import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/api_service.dart';

class MoneyMakerFormScreen extends StatefulWidget {
  const MoneyMakerFormScreen({super.key});

  @override
  State<MoneyMakerFormScreen> createState() => _MoneyMakerFormScreenState();
}

class _MoneyMakerFormScreenState extends State<MoneyMakerFormScreen> {
  final ApiService api = ApiService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController(text: '0');

  final _formKey = GlobalKey<FormState>();

  final List<String> types = [
    "Efectivo", "Mastercard", "Visa", "Tarjeta de débito", "Ahorros",
    "Banco", "Inversión", "Tarjeta de crédito", "Cuenta bancaria", "Criptomoneda",
    "Cheque", "Cuenta virtual", "PayPal", "Transferencia", "Préstamo", "Otro"
  ]; /////////////ESTO DEBERIA SALIR DE OTRO LADO O TENER UNA TABLA EN LA BASE DE DATOS PARA Q EL ADMIN PUEDA ADMINISTRAR O NOSE

  String typeSelected = "Efectivo"; // por defecto
  final List<String> typeMoney = ["USD", "ARS", "EUR"]; // ESTO SALE DEL BACKEND EN REALIDAD
  String typeMoneySelected = "ARS"; //ESTO TIENE Q SER EL MONEDA BASE DEL USUARIO

  Color? selectedColor;

 Future<void> addMoneyMaker() async {
  if (!_formKey.currentState!.validate()) return;
  final name = nameController.text.trim();
  final balance = double.tryParse(balanceController.text) ?? 0;
  final colorHex = '#${selectedColor!.toARGB32().toRadixString(16).substring(2)}';

  final newSource = await api.addPaymentSource( name, typeSelected, balance, typeMoneySelected, colorHex,);
  if (!mounted) return;
  if (newSource != null) {
    Navigator.pop(context, newSource); 
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al agregar la fuente')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Fuente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                  if (val.trim().length < 3) return 'El nombre debe tener al menos 3 caracteres';
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
                items: types.map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => typeSelected = value);
                },
              ),
              const SizedBox(height: 16),

              // Tipo de moneda
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de moneda',
                  border: OutlineInputBorder(),
                ),
                initialValue: typeMoneySelected,
                items: typeMoney.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m),
                    )).toList(),
                onChanged: (value) => setState(() => typeMoneySelected = value!),
              ),
              const SizedBox(height: 16),

              // Saldo inicial
              TextFormField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed < 0) return 'Ingresa un número válido para el saldo';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de color como FormField con InputDecorator
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
                          Text(selectedColor == null ? 'Seleccionar Color' : '#${selectedColor!.toARGB32().toRadixString(16).substring(2)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Botón agregar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addMoneyMaker,
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
