import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../models/money_maker.dart';
import 'money_maker_form_screen.dart';
import 'category_form_screen.dart';

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

  List<MoneyMaker> moneyMakers = [];
  MoneyMaker? selectedMoneyMaker;

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  List<String> currencies = ["USD", "EUR", "ARG"];
  String? selectedCurrency;

  File? attachedFile;
  int? repeatEveryNDays;
  String? repeatEnd; // para fin de repetición

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
      amountController.clear();
      nameController.clear();
      setState(() {
        attachedFile = null;
        repeatEveryNDays = null;
        repeatEnd = null;
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la transacción')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: _inputDecoration('Nombre'),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                ),
                const SizedBox(height: 12),

                // Monto
                TextFormField(
                  controller: amountController,
                  decoration: _inputDecoration('Monto'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese un monto';
                    if (double.tryParse(value) == null) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Moneda
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Moneda'),
                  value: selectedCurrency,
                  items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => selectedCurrency = value),
                ),
                const SizedBox(height: 12),

                // Categoría
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: _inputDecoration('Categoría'),
                        value: selectedCategory,
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
                const SizedBox(height: 12),

                // Fuente de dinero
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MoneyMaker>(
                        decoration: _inputDecoration('Fuente de dinero'),
                        value: selectedMoneyMaker,
                        items: moneyMakers
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (value) => setState(() => selectedMoneyMaker = value),
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
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 16),

                // Repetición
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Repetir"),
                  value: repeatEveryNDays != null
                      ? (repeatEveryNDays == 1
                          ? "Daily"
                          : repeatEveryNDays == 7
                              ? "Weekly"
                              : repeatEveryNDays == 30
                                  ? "Monthly"
                                  : repeatEveryNDays == 365
                                      ? "Yearly"
                                      : "Never")
                      : "Never",
                  items: const [
                    DropdownMenuItem(value: "Never", child: Text("Nunca")),
                    DropdownMenuItem(value: "Daily", child: Text("Todos los días")),
                    DropdownMenuItem(value: "Weekly", child: Text("Una vez a la semana")),
                    DropdownMenuItem(value: "Monthly", child: Text("Una vez al mes")),
                    DropdownMenuItem(value: "Yearly", child: Text("Una vez al año")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      switch (val) {
                        case "Daily":
                          repeatEveryNDays = 1;
                          break;
                        case "Weekly":
                          repeatEveryNDays = 7;
                          break;
                        case "Monthly":
                          repeatEveryNDays = 30;
                          break;
                        case "Yearly":
                          repeatEveryNDays = 365;
                          break;
                        default:
                          repeatEveryNDays = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Fin de repetición
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Fin de la repetición"),
                  value: repeatEnd,
                  items: const [
                    DropdownMenuItem(value: "Never", child: Text("Nunca")),
                    DropdownMenuItem(value: "After5", child: Text("Después de 5 veces")),
                    DropdownMenuItem(value: "After10", child: Text("Después de 10 veces")),
                    DropdownMenuItem(value: "CustomDate", child: Text("Fecha personalizada")),
                  ],
                  onChanged: (val) {
                    setState(() => repeatEnd = val);
                    // Aquí puedes abrir un DatePicker si es CustomDate
                  },
                ),
                const SizedBox(height: 20),

                // Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveTransaction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
