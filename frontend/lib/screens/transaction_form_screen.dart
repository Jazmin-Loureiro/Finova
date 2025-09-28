import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../models/money_maker.dart';
import '../models/currency.dart';

import 'money_maker_form_screen.dart';
import 'category_form_screen.dart';
import '../widgets/currency_text_field.dart';

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

  List<MoneyMaker> moneyMakers = [];
  MoneyMaker? selectedMoneyMaker;

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  List<Currency> currencies = [];
  String? selectedCurrency;

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
    setState(() {
      categories = data['categories'];
      selectedCategory = categories.isNotEmpty ? categories.first : null;
      moneyMakers = data['moneyMakers'];
      selectedMoneyMaker = moneyMakers.isNotEmpty ? moneyMakers.first : null;
      currencies = data['currencies'];
      selectedCurrency = (data['defaultCurrency'] as Currency).code;

      isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => attachedFile = File(result.files.single.path!));
    }
  }

  void saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(amountController.text);
    final name = nameController.text;
    if (amount == null || name.isEmpty || selectedMoneyMaker == null || selectedCategory == null) return;

    final res = await api.createTransaction(
      widget.type,
      amount,
      name,
      moneyMakerId: selectedMoneyMaker!.id,
      categoryId: selectedCategory!['id'],
      typeMoney: selectedCurrency,
      file: attachedFile,
      repetition: repeatEveryNDays != null,
      frequencyRepetition: repeatEveryNDays,
    );

    if (!mounted) return;

    if (res != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Éxito'),
          content: Text('${widget.type == "income" ? "Ingreso" : "Gasto"} creado correctamente'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la transacción')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    const Map<String, String> typeLabels = {
      "income": "Ingreso",
      "expense": "Gasto",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo ${typeLabels[widget.type] ?? widget.type}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  selectedCurrency: selectedCurrency ?? (currencies.isNotEmpty ? currencies.first.code : null),
                  label: 'Monto',
                ),
                const SizedBox(height: 16),

                // Fuente de dinero
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MoneyMaker>(
                       decoration: const InputDecoration(
                        labelText: 'Tipo de fuente',
                       
                       border: OutlineInputBorder(),
                      ),
                        initialValue: selectedMoneyMaker,
                        items: moneyMakers
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMoneyMaker = value;
                            selectedCurrency = value?.typeMoney;
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
                            selectedCurrency = newMaker.typeMoney;
                          });
                        }
                      },
                    ),
                  ],
                ),
                 const SizedBox(height: 16),

                //Drop desabilitado de moneda (la moneda se elige con la fuente de dinero)
                DropdownButtonFormField<Currency>(
                initialValue: currencies.firstWhere(
                  (c) => c.code == selectedCurrency,
                  orElse: () => currencies.first,
                ),
                items: currencies
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.symbol} ${c.code} - ${c.name}'),
                        ))
                    .toList(),
                onChanged: null, // null = deshabilitado
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
                          MaterialPageRoute(
                            builder: (_) => CategoryFormScreen(type: widget.type),
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
                  leading: const Icon(Icons.attach_file, color: Colors.indigo),
                  title: const Text("Adjuntar archivo"),
                  subtitle: attachedFile != null
                      ? Text(
                          attachedFile!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      : const Text(
                          "No se seleccionó archivo",
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                  trailing: IconButton(
                    icon: const Icon(Icons.upload_file, color: Colors.indigo),
                    onPressed: _pickFile,
                  ),
                ),
                const SizedBox(height: 20),

                // Guardar
               ElevatedButton(
                  onPressed: saveTransaction,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
