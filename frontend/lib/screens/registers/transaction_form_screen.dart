import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:frontend/widgets/completed_dialog_widget.dart';
import 'package:frontend/widgets/custom_scaffold.dart';

import '../../services/api_service.dart';
import '../../models/money_maker.dart';
import '../../models/currency.dart';
import '../../models/goal.dart';
import '../../models/category.dart';

import '../moneyMaker/money_maker_form_screen.dart';
import '../category/category_form_screen.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/success_dialog_widget.dart';
import '../../widgets/loading_widget.dart';

import 'package:provider/provider.dart';
import '../../providers/register_provider.dart';
import 'register_list_screen.dart';
import '../challenge_completed_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  final String type; // "income" o "expense"
  const TransactionFormScreen({required this.type, super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  List<MoneyMaker> moneyMakers = [];
  MoneyMaker? selectedMoneyMaker;

  List<Category> categories = [];
  Category? selectedCategory;

  List<Currency> currencies = [];
  Currency? selectedCurrency;

  List<Goal> goals = [];
  Goal? selectedGoal;

  File? attachedFile;

  String? repeatType; // 'day', 'month', 'year'
  int? repeatEveryNDays;

  List<Goal> allGoals = [];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final data = await api.getTransactionFormData(widget.type);
      Currency defaultCurrency = data['defaultCurrency'] as Currency;

      setState(() {
        categories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        moneyMakers = data['moneyMakers'];
        currencies = data['currencies'];
        allGoals = data['goals'] ?? [];

        selectedMoneyMaker =
            moneyMakers.isNotEmpty ? moneyMakers.first : null;
        selectedCurrency =
            selectedMoneyMaker?.currency ?? defaultCurrency;
        selectedCategory =
            categories.isNotEmpty ? categories.first : null;

        _filterGoalsByCurrency();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando formulario: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterGoalsByCurrency() {
    if (selectedCurrency == null) return;
    final filtered = allGoals
        .where((g) => g.currency?.id == selectedCurrency!.id)
        .where((g) => g.state == 'in_progress')
        .toList();

    setState(() {
      goals = filtered;
      if (selectedGoal != null &&
          !filtered.any((g) => g.id == selectedGoal!.id)) {
        selectedGoal = null;
      }
    });
  }


  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final amount =  parseCurrency(amountController.text, selectedCurrency!.code);
    if (amount <= 0) return;

    setState(() => isSaving = true);

    try {
      final res = await api.createTransaction(
        widget.type,
        amount,
        nameController.text,
        moneyMakerId: selectedMoneyMaker!.id,
        categoryId: selectedCategory!.id,
        currencyId: selectedCurrency!.id,
        goalId: selectedGoal?.id,
        file: attachedFile,
        repetition: repeatType != null,
        frequencyRepetition:
            repeatType != null ? int.tryParse(repeatType!) : null,
      );
      setState(() => isSaving = false);
      if (!mounted) return;

      if (res != null) {
        await showDialog(
          context: context,
          builder: (_) => SuccessDialogWidget(
            title: "Éxito",
            message:
                "${widget.type == 'income' ? "Ingreso" : "Gasto"} creado correctamente",
          ),
        );

        await context
            .read<RegisterProvider>()
            .loadRegisters(selectedMoneyMaker!.id);
        await context.read<RegisterProvider>().loadMoneyMakers();

        // 1) Mostrar CelebrationScreen primero
        if (res['rewards'] != null && (res['rewards'] as List).isNotEmpty) {

          final userData = await api.getUser();
          final userName = userData?['name'] ?? 'Usuario';
          final avatar = (userData?['full_icon_url'] ??
                          userData?['icon'] ??
                          '') as String;

          for (final reward in res['rewards']) {

            final closed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeCompletedScreen(
                  userName: userName,
                  avatarSeedOrUrl: avatar,

                  // ✔ Puntos que ganó con el desafío
                  pointsEarned: reward['points_earned'] ?? 0,

                  // ✔ Total REAL después de sumar recompensa
                  totalPoints: reward['new_total_points'] ?? 0,

                  // ✔ Subió de nivel
                  leveledUp: reward['leveled_up'] == true,

                  // ✔ Nuevo nivel
                  newLevel: reward['new_level'],

                  // ✔ Insignia (si la hay)
                  badgeName: reward['badge_earned']?['name'],
                ),
              ),
            );
            if (closed != true) return;
          }
        }

        // 2) Recién después, mostrar METAS completadas
        if (res['goal'] != null) {
          final goal = Goal.fromJson(res['goal']);
          if (goal.state == 'completed') {
            await api.assignReservedToMoneyMakers(goal.id);
            await CompletedDialog.show(context, goal: goal);
          }
        }

        // 3) Navegar al listado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterListScreen(
              moneyMakerId: selectedMoneyMaker!.id,
              moneyMakerName: selectedMoneyMaker!.name,
            ),
          ),
        );

      } else {
        await showDialog(
          context: context,
          builder: (_) => SuccessDialogWidget(
            title: "Error",
            message:
                "Error al crear ${widget.type == 'income' ? "ingreso" : "gasto"}. Intente nuevamente.",
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      debugPrint('Error guardando transacción: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = {
      "income": "Ingreso",
      "expense": "Gasto"
    };

    if (isLoading) {
      return const Scaffold(body: Center(child: LoadingWidget()));
    }

    return CustomScaffold(
      title: 'Nuevo ${typeLabels[widget.type] ?? widget.type}',
      currentRoute: 'transaction_form',
      showNavigation: false,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese un nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Fuente de dinero
                    Row(
                      children: [
                        Expanded(
                          child: BottomSheetPickerField<MoneyMaker>(
                            key: ValueKey(selectedMoneyMaker?.id ?? 'no_source'), 
                            label: 'Fuente de dinero',
                            title: 'Seleccionar fuente de dinero',
                            items: moneyMakers,
                            itemLabel: (m) => m.name,
                            itemIcon: (m) => CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(
                                int.parse(m.color.substring(1), radix: 16) + 0xFF000000,
                              ).withOpacity(0.15),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(
                                  int.parse(m.color.substring(1), radix: 16) + 0xFF000000,
                                ),
                              ),
                            ),
                            initialValue: selectedMoneyMaker,
                            onChanged: (value) {
                              setState(() {
                                selectedMoneyMaker = value;
                                selectedCurrency = value?.currency;
                                  amountController.clear();
                                _filterGoalsByCurrency();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Agregar fuente de dinero',
                          onPressed: () async {
                            final newMaker = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MoneyMakerFormScreen()),
                            );
                            if (newMaker != null) {
                              setState(() {
                                moneyMakers.add(newMaker);
                                selectedMoneyMaker = newMaker;
                                selectedCurrency = newMaker.currency;
                                _filterGoalsByCurrency();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Monto
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CurrencyTextField(
                            controller: amountController,
                            currencies: currencies,
                            selectedCurrency: selectedCurrency,
                            label: 'Monto',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingrese un monto';
                              }
                              final clean = val.replaceAll('.', '').replaceAll(',', '.');   // decimal
                              final parsed = double.tryParse(clean);
                              if (parsed! <= 0) return 'Ingrese un monto válido';
                              if (widget.type == 'expense' &&
                                  parsed > selectedMoneyMaker!.balance) {
                                return 'El gasto supera el monto disponible (${selectedMoneyMaker!.balance.toStringAsFixed(2)})';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Moneda',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            controller: TextEditingController(
                                text: selectedCurrency?.code),
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    Row(
                    children: [
                      Expanded(
                        child: BottomSheetPickerField<Category>(
                          key: ValueKey(selectedCategory?.id ?? 'no_category'),
                          label: 'Categoría',
                          title: 'Seleccionar categoría',
                          items: categories,
                          itemLabel: (c) => c.name,
                          itemIcon: (c) {
                            final color = Color(
                              int.parse(c.color.substring(1), radix: 16) + 0xFF000000,
                            );
                            return CircleAvatar(
                              radius: 20,
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(AppIcons.fromName(c.icon), color: color, size: 22),
                            );
                          },
                          initialValue: selectedCategory,
                          onChanged: (value) => setState(() => selectedCategory = value),
                          validator: (value) =>
                              value == null ? 'Seleccione una categoría' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Agregar categoría',
                        onPressed: () async {
                          final newCategory = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryFormScreen(type: widget.type),
                            ),
                          );
                          if (newCategory != null && newCategory is Category) {
                            setState(() {
                              categories.add(newCategory);
                              selectedCategory = newCategory;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),

                    // Meta
                    if (widget.type != 'expense') ...[
                     BottomSheetPickerField<Goal?>(
                      label: 'Meta (opcional)',
                      title: 'Seleccionar meta',
                      items: [
                        ...goals, // tus metas disponibles
                      ],
                    itemLabel: (g) {
                      final goal = g!;
                      final balance = goal.balance;
                      final target = goal.targetAmount;
                      final code = goal.currency?.code ?? '---';

                      return '${goal.name} (${goal.currency?.symbol}${formatCurrency(balance, code)} / ${goal.currency?.symbol}${formatCurrency(target, code)})';
                    },
                      itemIcon: (g) => const Icon(Icons.flag_rounded, color: Colors.blueAccent),
                      initialValue: selectedGoal,
                      emptyText: 'Sin meta',
                      onChanged: (value) => setState(() => selectedGoal = value),
                      isRequired: false,
                    ),
                      const SizedBox(height: 16),
                    ],

                    // Repetición
                    /*
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Repetir',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            initialValue: repeatType,
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text('No Repetir')),
                              DropdownMenuItem(
                                  value: '1', child: Text('Por día')),
                              DropdownMenuItem(
                                  value: '7', child: Text('Por semana')),
                              DropdownMenuItem(
                                  value: '30', child: Text('Por mes')),
                              DropdownMenuItem(
                                  value: '365', child: Text('Por año')),
                            ],
                            onChanged: (val) {
                              setState(() => repeatType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    */

                    // Archivo adjunto
                   FormField<File?>(
                    validator: (value) {
                      if (attachedFile == null) return null; // no obligatorio

                      final ext = attachedFile!.path.split('.').last.toLowerCase();
                      const allowed = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];

                      if (!allowed.contains(ext)) {
                        return 'Tipo de archivo no permitido (${ext.toUpperCase()})';
                      }

                      return null; //
                    },
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.2),
                            ),
                          ),
                          leading: Icon(
                            Icons.attach_file,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Adjuntar archivo"),
                          subtitle: attachedFile != null
                              ? Text(
                                  attachedFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                )
                              : Text(
                                  "No se seleccionó archivo",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (attachedFile != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      attachedFile = null;
                                      state.didChange(null); 
                                    });
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.upload_file,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(type: FileType.any);
                                  if (result != null && result.files.single.path != null) {
                                    final pickedFile = File(result.files.single.path!);
                                    setState(() {
                                      attachedFile = pickedFile;
                                      state.didChange(pickedFile); 
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                            child: Text(
                              state.errorText!,
                              style:  TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  )
                  ,
                    const SizedBox(height: 16),

                    ButtonSave(
                      title: 'Guardar',
                      message:
                          '¿Seguro que quieres guardar este registro?',
                      onConfirm: _saveTransaction,
                      formKey: _formKey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSaving)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: LoadingWidget(message: 'Guardando registro...'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
