import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/api_service.dart';
import '../../models/money_maker.dart';
import '../../models/currency.dart';
import '../../models/goal.dart';

import '../money_maker_form_screen.dart';
import '../category/category_form_screen.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/success_dialog_widget.dart';
import '../../widgets/loading_widget.dart';

import 'package:provider/provider.dart';
import '../../providers/register_provider.dart';
import 'register_list_screen.dart';

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

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  List<Currency> currencies = [];
  Currency? selectedCurrency;

  List<Goal> goals = [];
  Goal? selectedGoal;

  File? attachedFile;

  String? repeatType; // 'day', 'month', 'year'
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
        categories = data['categories'];
        moneyMakers = data['moneyMakers'];
        currencies = data['currencies'];
        allGoals = data['goals'] ?? [];

        selectedMoneyMaker = moneyMakers.isNotEmpty ? moneyMakers.first : null;
        selectedCurrency = selectedMoneyMaker?.currency ?? defaultCurrency;
        selectedCategory = categories.isNotEmpty ? categories.first : null;

        _filterGoalsByCurrency();

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando formulario: $e');
      setState(() => isLoading = false);
    }
  }

  List<Goal> allGoals = []; // lista original, nunca tocarla

  void _filterGoalsByCurrency() {
    if (selectedCurrency == null) return;
    final filtered = allGoals
    .where((g) => g.currency?.id == selectedCurrency!.id)
    .where((g) => g.state == 'in_progress')
    .toList(); 
    setState(() {
    goals = filtered;
    if (selectedGoal != null && filtered.any((g) => g.id == selectedGoal!.id)) {
    } else {
      selectedGoal = null; //por defecto "Sin meta"
    }
  });
}


  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => attachedFile = File(result.files.single.path!));
    }
  }

  Future<void> _showRewardsDialog(List rewards) async {
    if (rewards.isEmpty) return;

    String rewardMessage = "";
    for (final reward in rewards) {
      final points = reward['points_earned'] ?? 0;
      final newLevel = reward['new_level'];
      final leveledUp = reward['leveled_up'] == true;
      final badge = reward['badge_earned'];

      rewardMessage += "🏆 ¡Ganaste $points puntos!\n";
      if (leveledUp) rewardMessage += "🎉 ¡Subiste al nivel $newLevel!\n";
      if (badge != null && badge['name'] != null) {
        rewardMessage += "🏅 Nueva insignia: ${badge['name']}\n";
      }
      rewardMessage += "\n";
    }

    await showDialog(
      context: context,
      builder: (_) => SuccessDialogWidget(
        title: "¡Desafío completado!",
        message: rewardMessage.trim(),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;
    setState(() => isSaving = true);
    try {
      final res = await api.createTransaction(
        widget.type,
        amount,
        nameController.text,
        moneyMakerId: selectedMoneyMaker!.id,
        categoryId: selectedCategory!['id'],
        currencyId: selectedCurrency!.id,
        goalId: selectedGoal?.id,
        file: attachedFile,
        repetition: repeatType != null,
        frequencyRepetition: repeatType != null ? int.tryParse(repeatType!) : null,
      );
      setState(() => isSaving = false);
      if (!mounted) return;

      if (res != null) {
        await showDialog(
          context: context,
          builder: (_) => SuccessDialogWidget(
            title: "Éxito",
            message: "${widget.type == 'income' ? "Ingreso" : "Gasto"} creado correctamente",
          ),
        );
        await context.read<RegisterProvider>().loadRegisters(selectedMoneyMaker!.id);
        await context.read<RegisterProvider>().loadMoneyMakers();
        if (res['rewards'] != null && (res['rewards'] as List).isNotEmpty) {
          await _showRewardsDialog(res['rewards']);
        }
        if (res['goal'] != null) {
          final goal = Goal.fromJson(res['goal']);  
          if (goal.state == 'completed') {
             // Asignar automáticamente el dinero reservado
            await api.assignReservedToMoneyMakers(goal.id);
            // Mostrar un solo mensaje de éxito
            await showDialog(
              context: context,
              builder: (_) => const SuccessDialogWidget(
                title: 'Meta completada',
                message: '¡Meta completada! Su dinero reservado se asignará a las fuentes de dinero utilizadas.',
              ),
            );
          }
        }
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

  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = {"income": "Ingreso", "expense": "Gasto"};

    if (isLoading) return const Scaffold(body: Center(child: LoadingWidget()));

    return Scaffold(
      appBar: AppBar(title: Text('Nuevo ${typeLabels[widget.type] ?? widget.type}')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Nombre
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                    ),
                    const SizedBox(height: 16),

                    // Monto
                    CurrencyTextField(
                      controller: amountController,
                      currencies: currencies,
                      selectedCurrency: selectedCurrency,
                      label: 'Monto',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingrese un monto';
                        final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                        if (parsed <= 0) return 'Ingrese un monto válido';
                        if (widget.type == 'expense' && parsed > selectedMoneyMaker!.balance) {
                          return 'El gasto supera el monto disponible (${selectedMoneyMaker!.balance.toStringAsFixed(2)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fuente de dinero
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<MoneyMaker>(
                            decoration: const InputDecoration(
                              labelText: 'Fuente de dinero',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: selectedMoneyMaker,
                            items: moneyMakers
                                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMoneyMaker = value;
                                selectedCurrency = value?.currency;
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
                              MaterialPageRoute(builder: (_) => const MoneyMakerFormScreen()),
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

                    // Moneda (deshabilitada)
                    DropdownButtonFormField<int>(
                      initialValue: selectedCurrency?.id ?? currencies.first.id,
                      items: currencies
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.symbol} ${c.code} - ${c.name}'),
                              ))
                          .toList(),
                      onChanged: null,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de moneda',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: selectedCategory,
                            items: categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c['name'])))
                                .toList(),
                            onChanged: (value) => setState(() => selectedCategory = value),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Agregar categoría',
                          onPressed: () async {
                            final newCategory = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CategoryFormScreen(type: widget.type)),
                            );
                            if (newCategory != null) {
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
                    DropdownButtonFormField<Goal?>(
                      decoration: const InputDecoration(
                        labelText: 'Meta (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedGoal,
                      items: [
                        DropdownMenuItem<Goal?>(
                          value: null,
                          child: Text('Sin meta'),
                        ),
                        ...goals.map((g) => DropdownMenuItem<Goal?>(
                            value: g,
                            child: Text(g.name),
                          )),
                    ],
                    onChanged: (value) => setState(() => selectedGoal = value),
                  ),
                    const SizedBox(height: 16),
                  ],
                    // Repetición
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Repetir',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: repeatType,
                            items: const [
                              DropdownMenuItem(value: null, child: Text('No Repetir')),
                              DropdownMenuItem(value: '1', child: Text('Por día')),
                              DropdownMenuItem(value: '7', child: Text('Por semana')),
                              DropdownMenuItem(value: '30', child: Text('Por mes')),
                              DropdownMenuItem(value: '365', child: Text('Por año')),
                            ],
                            onChanged: (val) {
                              setState(() => repeatType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Archivo adjunto
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      leading: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Adjuntar archivo"),
                      subtitle: attachedFile != null
                          ? Text(attachedFile!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))
                          : Text("No se seleccionó archivo",
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                      trailing: IconButton(
                        icon: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                        onPressed: _pickFile,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlay al guardar
          if (isSaving)
            Container(
              child: const Center(
                child: LoadingWidget(message: 'Guardando registro...'),
              ),
            ),
        ],
      ),
    );
  }
}
