import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../models/money_maker.dart';
import 'money_maker_form_screen.dart';
import 'category_form_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  final String type; // "income" or "expense"
  const TransactionFormScreen({required this.type, super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController = TextEditingController(); // Monto controller
  final TextEditingController nameController = TextEditingController(); // Nombre controller

  List<MoneyMaker> moneyMakers = []; // Lista de FUENTES DE DINERO
  MoneyMaker? selectedMoneyMaker; // Fuente de dinero seleccionada

  List<Map<String, dynamic>> categories = []; // Lista de CATEGORIAS
  Map<String, dynamic>? selectedCategory; // Categoria seleccionada

  List<String> currencies = ["USD", "EUR", "ARG"]; // Lista de monedas
  String? selectedCurrency; // Moneda seleccionada

  File? attachedFile;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool repeats = false;
  int? repeatEveryNDays;

  @override
  void initState() {
    super.initState();
    _loadMoneyMakers();
    _loadCurrencies();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
  final categoriesApi = await api.getCategories(widget.type);
  if (categoriesApi.isNotEmpty) {
    setState(() {
      categories = categoriesApi;
      selectedCategory = categories.first; 
    });
  }
}

Future<void> _loadMoneyMakers() async {
  final makersApi = await api.getMoneyMakers();
  if (makersApi.isNotEmpty) {
    setState(() {
      moneyMakers = makersApi;
      selectedMoneyMaker = moneyMakers.first; 
    });
  }
}

  void _loadCurrencies() async {
    final currenciesApi = await api.getMonedas();
    if (currenciesApi.isNotEmpty) {
      setState(() {
        selectedCurrency = currenciesApi.first;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => attachedFile = File(result.files.single.path!));
    }
  }


/////////////////////////////////////////////////////
  void saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(amountController.text); // Monto
    final name = nameController.text; // Nombre
    if (amount == null || name.isEmpty || selectedMoneyMaker == null || selectedCategory == null) return; // Validacione

    final res = await api.createTransaction(
      widget.type,
      amount,
      name,
      moneyMakerId: selectedMoneyMaker!.id, // sending MoneyMaker ID
      categoryId: selectedCategory!['id'], // sending Category ID
      typeMoney: selectedCurrency,
      file: attachedFile,
      repetition: repeats,
      frequencyRepetition: repeatEveryNDays,
    );

    if (!mounted) return;

    if (res != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: Text('${widget.type} created successfully'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      amountController.clear();
      nameController.clear();
      setState(() {
        attachedFile = null;
        repeats = false;
        repeatEveryNDays = null;
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating transaction')),
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = {
      "income": "Income",
      "expense": "Expense",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('New ${typeLabels[widget.type] ?? widget.type}'),
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
                ),
                // Monto
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    if (double.tryParse(value) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                // Moneda
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Currency'),
                  initialValue: selectedCurrency,
                  items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => selectedCurrency = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: const InputDecoration(labelText: 'Category'),
                        initialValue: selectedCategory,
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c['name'])))
                            .toList(),
                        onChanged: (value) => setState(() => selectedCategory = value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Category',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MoneyMaker>(
                        decoration: const InputDecoration(labelText: 'Money Source'),
                        initialValue: selectedMoneyMaker,
                        items: moneyMakers
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (value) => setState(() => selectedMoneyMaker = value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Money Source',
                      onPressed: () async {
                        final newMaker = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MoneyMakerFormScreen()),
                        );
                        if (newMaker != null) {
                          setState(() {
                            moneyMakers.add(newMaker);   // lo agregás a la lista
                            selectedMoneyMaker = newMaker; // y lo seleccionás
                          });
                        }
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Attach File"),
                    ),
                    const SizedBox(width: 12),
                    if (attachedFile != null)
                      Expanded(
                        child: Text(
                          attachedFile!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text("Repeat Transaction"),
                  value: repeats,
                  onChanged: (val) => setState(() => repeats = val ?? false),
                ),
                if (repeats)
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Repeat every N days"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => repeatEveryNDays = int.tryParse(val),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveTransaction,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
