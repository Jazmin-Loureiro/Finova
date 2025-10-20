import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../models/money_maker.dart';
import '../models/currency.dart';

import 'money_maker_form_screen.dart';
import 'category_form_screen.dart';
import '../widgets/currency_text_field.dart';
import '../widgets/success_dialog_widget.dart'; // 👈 usamos tu widget propio
import '../widgets/loading_widget.dart';

import 'package:provider/provider.dart';
import '../providers/register_provider.dart';
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

  bool isLoading = true; // Loader general
  bool isSaving = false; // Loader al guardar

  List<MoneyMaker> moneyMakers = [];
  MoneyMaker? selectedMoneyMaker;

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  List<Currency> currencies = [];
  Currency? selectedCurrency;

  File? attachedFile;
  int? repeatEveryNDays;
  String? repeatEnd;

  @override
  void initState() {
    super.initState();
    loadFormData();
  }

  Future<void> loadFormData() async {
    final data = await api.getTransactionFormData(widget.type);
    Currency defaultCurrency = data['defaultCurrency'] as Currency;
    setState(() {
      categories = data['categories'];
      selectedCategory = categories.isNotEmpty ? categories.first : null;
      moneyMakers = data['moneyMakers'];
      selectedMoneyMaker = moneyMakers.isNotEmpty ? moneyMakers.first : null;
      currencies = data['currencies'];
      selectedCurrency = selectedMoneyMaker?.currency ?? defaultCurrency;
      isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => attachedFile = File(result.files.single.path!));
    }
  }

  /// Guardar transacción + mostrar recompensas
  void saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(amountController.text);
    final name = nameController.text;
    setState(() => isSaving = true);

    final res = await api.createTransaction( widget.type,amount!, name, moneyMakerId: selectedMoneyMaker!.id,categoryId: selectedCategory!['id'],currencyId: selectedCurrency!.id,
      file: attachedFile,repetition: repeatEveryNDays != null,frequencyRepetition: repeatEveryNDays,);
    setState(() => isSaving = false);
    if (!mounted) return;

    if (res != null) {
      await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: "Éxito",
          message:
              "${widget.type == "income" ? "Ingreso" : "Gasto"} creado correctamente",
        ),
      );
      //  Recargar registros del MoneyMaker en el provider
      await context.read<RegisterProvider>().loadRegisters(selectedMoneyMaker!.id);
      await context.read<RegisterProvider>().loadMoneyMakers();

      // ⚡ Mostrar recompensas si existen (un solo pop-up con todo junto)
      if (res['rewards'] != null && (res['rewards'] as List).isNotEmpty) {
        final rewards = res['rewards'] as List;
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

      //  Actualizar desafíos en segundo plano
      try {
        await ApiService().getGamificationProfile();
      } catch (_) {}

    Navigator.pop(context);
    // Vamos directo a RegisterListScreen
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
       showDialog( context: context,
        builder: (_) => SuccessDialogWidget(
          title: "Error",
          message:
              "Error al crear ${widget.type == "income" ? "ingreso" : "gasto"}. Intente nuevamente.",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = { "income": "Ingreso", "expense": "Gasto",};
    if (isLoading) return const Scaffold( body: Center(child: LoadingWidget()));
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo ${typeLabels[widget.type] ?? widget.type}')),
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
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese un nombre' : null,
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
                  final parsed = double.tryParse(val) ?? 0;
                  if (parsed <= 0) return 'Ingrese un monto válido';
                  if (widget.type == 'expense' &&
                      parsed > selectedMoneyMaker!.balance) {
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
                      child: moneyMakers.isEmpty
                          ? const SizedBox()
                          : DropdownButtonFormField<MoneyMaker>(
                              decoration: const InputDecoration(
                                labelText: 'Fuente de dinero',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedMoneyMaker,
                        items: moneyMakers
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMoneyMaker = value;
                            selectedCurrency = value?.currency;
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
                              builder: (_) => const MoneyMakerFormScreen()),
                        );
                        if (newMaker != null) {
                          setState(() {
                            moneyMakers.add(newMaker);
                            selectedMoneyMaker = newMaker;
                            selectedCurrency = newMaker.currency;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Drop de moneda (deshabilitado)
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
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c['name'])))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCategory = value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Agregar categoría',
                      onPressed: () async {
                        final newCategory = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoryFormScreen(type: widget.type),
                          ),
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

                // Archivo adjunto
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: Icon(Icons.attach_file,color: Theme.of(context).colorScheme.primary) ,
                  title: const Text("Adjuntar archivo"),
                  subtitle: attachedFile != null
                      ? Text(attachedFile!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurface))
                      :  Text("No se seleccionó archivo",
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                  trailing: IconButton(
                    icon:  Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary) ,
                    onPressed: _pickFile,
                  ),
                ),
                const SizedBox(height: 20),

                // Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: saveTransaction,
                  child: const Text('Guardar'),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
          //  cargando al guardar
          if (isSaving)
            Container(
              color: Theme.of(context).colorScheme.onPrimary,
              child: const Center(
                child: LoadingWidget(message: 'Guardando registro...'),
              ),
            ),
        ],
      ),
    );
  }
}
