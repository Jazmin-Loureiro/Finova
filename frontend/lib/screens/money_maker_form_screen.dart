import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/api_service.dart';

import '../models/currency.dart';
import '../models/money_maker.dart';
import '../widgets/currency_text_field.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';

class MoneyMakerFormScreen extends StatefulWidget {
  final MoneyMaker? moneyMaker; // Fuente opcional (si se edita)

  const MoneyMakerFormScreen({super.key, this.moneyMaker});

  @override
  State<MoneyMakerFormScreen> createState() => _MoneyMakerFormScreenState();
}

class _MoneyMakerFormScreenState extends State<MoneyMakerFormScreen> {
  final ApiService api = ApiService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  

  Color? selectedColor;
  String typeSelected = "Efectivo";
  bool _isLoading = true;
  bool isSaving = false;
  List<Currency> currencies = [];
  Currency? selectedCurrency;

@override
  void initState() {
    super.initState();
    if (widget.moneyMaker != null) {
      final m = widget.moneyMaker!;
      nameController.text = m.name;
      balanceController.text = m.balance.toString();
      selectedColor = Color(int.parse(m.color.replaceAll('#', '0xFF')));
      typeSelected = m.type;
    }
    loadFormData();
  }

  Future<void> loadFormData() async {
    final fetchedCurrencies = await api.getCurrencies();
    final userBaseCurrency = await api.getUserCurrency();
    if (!mounted) return;
    setState(() {
      currencies = fetchedCurrencies;
      selectedCurrency = currencies.firstWhere(
        (c) => c.id == userBaseCurrency,
        orElse: () => currencies.first,
      );
      _isLoading = false;
    });
  }

  Future<void> saveMoneyMaker() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.moneyMaker != null;
    final name = nameController.text.trim();
    final balance = double.tryParse(balanceController.text) ?? 0;
    final colorHex =
        '#${selectedColor!.toARGB32().toRadixString(16).substring(2)}';

    setState(() => isSaving = true);

    dynamic newSource;
    if (isEditing) {
      newSource = await api.updatePaymentSource(
        widget.moneyMaker!.id,
        name,
        typeSelected,
        balance,
        selectedCurrency!,
        colorHex,
      );
    } else {
      newSource = await api.addPaymentSource(
        name,
        typeSelected,
        balance,
        selectedCurrency!,
        colorHex,
      );
    }

    setState(() => isSaving = false);

    if (newSource != null) {
      final confirmed = await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: isEditing ? 'Fuente Actualizada' : 'Fuente Agregada',
          message: isEditing
              ? 'La fuente se actualizó exitosamente.'
              : 'La fuente se agregó exitosamente.',
          buttonText: 'Aceptar',
        ),
      );
      if (confirmed && mounted) Navigator.pop(context, newSource);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la fuente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.moneyMaker != null;
    if (_isLoading) return const Scaffold(body: Center(child: LoadingWidget()));
    return Scaffold(
      appBar: AppBar(title:  Text(isEditing ? 'Editar Fuente' : 'Agregar Fuente')),
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
                          labelText: 'Nombre de la fuente',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'El nombre no puede estar vacío';
                          if (val.trim().length < 3) return 'Debe tener al menos 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tipo de fuente
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de fuente',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: typeSelected,
                        items: [
                          "Efectivo", "Mastercard", "Visa", "Tarjeta de débito", "Ahorros",
                          "Banco", "Inversión", "Tarjeta de crédito", "Cuenta bancaria", "Criptomoneda",
                          "Cheque", "Cuenta virtual", "PayPal", "Transferencia", "Préstamo", "Otro"
                        ]
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (value) => setState(() => typeSelected = value!),
                      ),
                      const SizedBox(height: 16),

                      // Tipo de moneda
                      DropdownButtonFormField<Currency>(
                        initialValue: selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de moneda',
                          border: OutlineInputBorder(),
                        ),
                        items: currencies.map((c) => DropdownMenuItem<Currency>(
                          value: c,
                          child: Text('${c.symbol} ${c.code} - ${c.name}'),
                        )).toList(),
                        onChanged: (value) => setState(() => selectedCurrency = value),
                        validator: (val) => val == null ? 'Debes seleccionar una moneda' : null,
                      ),
                      const SizedBox(height: 16),

                      // Saldo inicial
                      CurrencyTextField(
                        controller: balanceController,
                        currencies: currencies,
                        selectedCurrency: selectedCurrency,
                        label: 'Saldo inicial',
                      ),

                      const SizedBox(height: 16),

                      // Selector de color
                      FormField<Color>(
                        validator: (val) {
                          if (selectedColor == null) return 'Debes seleccionar un color';
                          return null;
                        },
                        builder: (state) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Color',
                              border: const OutlineInputBorder(),
                              errorText: state.errorText,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Elige un color'),
                                    content: SingleChildScrollView(
                                      child: BlockPicker(
                                        pickerColor: selectedColor ?? Colors.blue,
                                        onColorChanged: (color) {
                                          setState(() {
                                            selectedColor = color;
                                            state.didChange(color);
                                          });
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Cerrar'),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: selectedColor ?? Colors.transparent,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(selectedColor == null
                                      ? 'Seleccionar Color'
                                      : '#${selectedColor!.toARGB32().toRadixString(16).substring(2)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saveMoneyMaker,
                          child: Text(isEditing ? 'Guardar Cambios' : 'Agregar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Overlay de guardado
          if (isSaving)
            Container(
              color: Theme.of(context).colorScheme.onPrimary,
              child: const Center(
                child: LoadingWidget(message: 'Guardando fuente...'),
              ),
            ),
        ],
      ),
    );
  }
}
