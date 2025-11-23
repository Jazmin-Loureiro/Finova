import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:frontend/widgets/dialogs/completed_dialog_widget.dart';
import 'package:frontend/widgets/custom_scaffold.dart';

import '../challenges/extra_unlocked_screen.dart';

import '../../services/api_service.dart';
import '../../models/money_maker.dart';
import '../../models/currency.dart';
import '../../models/goal.dart';
import '../../models/category.dart';

import '../moneyMaker/money_maker_form_screen.dart';
import '../category/category_form_screen.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/dialogs/success_dialog_widget.dart';
import '../../widgets/loading_widget.dart';

import 'package:provider/provider.dart';
import '../../providers/register_provider.dart';
import 'register_list_screen.dart';
import '../challenges/challenge_completed_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  final String type;

  const TransactionFormScreen({
    required this.type,
    super.key,
  });

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

  List<Goal> allGoals = [];

  File? attachedFile;

  String? repeatType;
  int? repeatEveryNDays;

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

  // =====================================================
  // 🔥 VERSION ORIGINAL + EXTRA DESBLOQUEADO
  // =====================================================
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        parseCurrency(amountController.text, selectedCurrency!.code);

    if (amount <= 0) return;

    setState(() => isSaving = true);

    try {
  // Crear transacción
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
    // ============================
    // 1) ÉXITO
    // ============================
    await showDialog(
      context: context,
      builder: (_) => SuccessDialogWidget(
        title: "Éxito",
        message: "${widget.type == 'income' ? "Ingreso" : "Gasto"} creado correctamente",
      ),
    );

    // 🔥 evita el parpadeo sin modificar el dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => isSaving = true);
    });


    await context
        .read<RegisterProvider>()
        .loadRegisters(selectedMoneyMaker!.id);

    await context.read<RegisterProvider>().loadMoneyMakers();

    // ============================
    // 2) RECOMPENSAS
    // ============================
    if (res['rewards'] != null &&
        (res['rewards'] as List).isNotEmpty) {
      final userData = await api.getUser();
      final userName = userData?['name'] ?? 'Usuario';
      final avatar =
          (userData?['full_icon_url'] ?? userData?['icon'] ?? '') as String;

      for (final reward in res['rewards']) {

        // apagar loader antes de abrir pantalla desafio
        setState(() => isSaving = false);

        final closed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeCompletedScreen(
              userName: userName,
              avatarSeedOrUrl: avatar,
              pointsEarned: reward['points_earned'] ?? 0,
              totalPoints: reward['new_total_points'] ?? 0,
              leveledUp: reward['leveled_up'] == true,
              newLevel: reward['new_level'],
              badgeName: reward['badge_earned']?['name'],
            ),
          ),
        );

        if (closed != true) return;

        // 🔥 loader intermedio DESPUÉS del challenge completado
        setState(() => isSaving = true);

        // ============================
        // 3) EXTRAS DESBLOQUEADOS
        // ============================
        final house = await api.getHouseStatus();
        final extras = (house['casa']?['extras'] ?? []) as List;

        final newlyUnlocked = extras.where((e) {
          return e['level_required'] == reward['new_level'] &&
                 e['already_shown'] == false;
        }).toList();

        for (final extra in newlyUnlocked) {
          
          // apagar loader antes de mostrar pantalla extra desbloqueado
          setState(() => isSaving = false);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExtraUnlockedScreen(
                extraName: extra['name'],
                iconPath: "assets/${extra['icon']}"
                    .replaceFirst(".svg", "_icon.svg"),
                levelUnlocked: extra['level_required'],
              ),
            ),
          );

          // 🔥 loader intermedio DESPUÉS del ExtraUnlockedScreen
          setState(() => isSaving = true);

          await api.markExtraShown(extra['id']);
        }
      }
    }

    // ============================
    // 4) METAS COMPLETADAS
    // ============================
    if (res['goal'] != null) {
      final goal = Goal.fromJson(res['goal']);
      if (goal.state == 'completed') {

        // loader intermedio opcional
        setState(() => isSaving = true);

        await api.assignReservedToMoneyMakers(goal.id);

        setState(() => isSaving = false);

        await CompletedDialog.show(context, goal: goal);

        // loader de retorno
        setState(() => isSaving = true);
      }
    }

    // ============================
    // 5) VOLVER AL LISTADO
    // ============================
    setState(() => isSaving = false);

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
        message: "Error al crear ${widget.type == 'income' ? "ingreso" : "gasto"}. Intente nuevamente.",
      ),
    );
  }
} catch (e) {
  setState(() => isSaving = false);
  debugPrint('Error guardando transacción: $e');
}

  }

  // =====================================================
  // UI COMPLETA (idéntica a tu versión original)
  // =====================================================
  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = {
      "income": "Ingreso",
      "expense": "Gasto"
    };

    if (isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
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
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    // =====================================================
                    // Categoría
                    // =====================================================
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
                                int.parse(c.color.substring(1), radix: 16) +
                                    0xFF000000,
                              );
                              return CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  AppIcons.fromName(c.icon),
                                  color: color,
                                  size: 22,
                                ),
                              );
                            },
                            initialValue: selectedCategory,
                            onChanged: (value) =>
                                setState(() => selectedCategory = value),
                            validator: (value) =>
                                value == null ? 'Seleccione una categoría' : null,
                          ),
                        ),

                        const SizedBox(width: 8),
                          Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          color: Theme.of(context).colorScheme.onPrimary,
                          tooltip: 'Agregar categoría',
                          onPressed: () async {
                            final newCategory = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryFormScreen(type: widget.type),
                              ),
                            );
                            if (newCategory != null &&
                                newCategory is Category) {
                              setState(() {
                                categories.add(newCategory);
                                selectedCategory = newCategory;
                              });
                            }
                          },
                        ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    // =====================================================
                    // Fuente de dinero
                    // =====================================================
                    Row(
                      children: [
                        Expanded(
                          child: BottomSheetPickerField<MoneyMaker>(
                            key: ValueKey(selectedMoneyMaker?.id ?? 'no_source'),
                            label: 'Fuente de dinero',
                            title: 'Seleccionar fuente de dinero',
                            items: moneyMakers,
                            itemLabel: (m) => m.name,
                            itemIcon: (m) {
                              final color = Color(
                                int.parse(m.color.substring(1), radix: 16) +
                                    0xFF000000,
                              );
                              return CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: color,
                                ),
                              );
                            },
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
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                        IconButton(
                          icon: const Icon(Icons.add),
                          color: Theme.of(context).colorScheme.onPrimary,
                          tooltip: 'Agregar fuente de dinero',
                          onPressed: () async {
                            final newMaker = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MoneyMakerFormScreen()),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // =====================================================
                    // Monto
                    // =====================================================
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
                              final parsed = parseCurrency(val, selectedCurrency!.code);
                                  if (parsed <= 0) {
                                return 'Ingrese un monto válido';
                              }
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                            ),
                            controller: TextEditingController(
                              text: selectedCurrency?.code,
                            ),
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // =====================================================
                    // Descripción
                    // =====================================================
                    TextFormField(
                      controller: nameController,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                          counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // =====================================================
                    // Meta
                    // =====================================================
                    if (widget.type != 'expense') ...[
                      BottomSheetPickerField<Goal?>(
                        label: 'Meta (opcional)',
                        title: 'Seleccionar meta',
                        items: [...goals],
                        itemLabel: (g) {
                          final goal = g!;
                          final balance = goal.balance;
                          final target = goal.targetAmount;
                          final code = goal.currency?.code ?? '---';

                          return '${goal.name} (${goal.currency?.symbol}${formatCurrency(balance, code)} / ${goal.currency?.symbol}${formatCurrency(target, code)})';
                        },
                        itemIcon: (g) => const Icon(
                          Icons.flag_rounded,
                          color: Colors.blueAccent,
                        ),
                        initialValue: selectedGoal,
                        emptyText: 'Sin meta',
                        onChanged: (value) =>
                            setState(() => selectedGoal = value),
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // =====================================================
                    // Archivo adjunto
                    // =====================================================
                    FormField<File?>(
                      validator: (value) {
                        if (attachedFile == null) return null;

                        final ext = attachedFile!.path.split('.').last.toLowerCase();
                        const allowed = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];

                        if (!allowed.contains(ext)) {
                          return 'Tipo de archivo no permitido (${ext.toUpperCase()})';
                        }
                        return null;
                      },
                      builder: (state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputDecorator(
                              isEmpty: attachedFile == null,
                              decoration: InputDecoration(
                              
                                errorText: state.hasError ? state.errorText : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.any,
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    final pickedFile = File(result.files.single.path!);
                                    attachedFile = pickedFile;
                                    state.didChange(pickedFile);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.attach_file,
                                        color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),

                                    // nombre del archivo
                                    Expanded(
                                      child: Text(
                                        attachedFile != null
                                            ? attachedFile!.path.split('/').last
                                            : "No se seleccionó archivo",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    if (attachedFile != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                                        onPressed: () {
                                          attachedFile = null;
                                          state.didChange(null);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // =====================================================
                    // Botón Guardar
                    // =====================================================
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

          //Overlay de guardado
        if (isSaving)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: LoadingWidget(message: 'Creando registro...'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
