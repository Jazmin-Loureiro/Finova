import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/api_service.dart';

class CategoryFormScreen extends StatefulWidget {
  final String type; 
  const CategoryFormScreen({super.key, required this.type});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final ApiService api = ApiService();

  final TextEditingController nameController = TextEditingController();
  Color? colorSelected;

  final _formKey = GlobalKey<FormState>();

// Función para guardar la categoría
  void saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    final colorHex = '#${colorSelected!.toARGB32().toRadixString(16).substring(2)}';
    final success = await api.addCategory(
      name: name,
      type: widget.type,
      color: colorHex,
    );
    if (!mounted) return;
    if (success) {
      final newCategory = {
        'name': name,
        'type': widget.type,
        'color': colorHex,
      };
      Navigator.pop(context, newCategory);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la categoría')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Map<String, String> typeLabels = {
      "income": "Ingreso",
      "expense": "Gasto",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text("Nueva categoría (${typeLabels[widget.type] ?? widget.type})"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la categoría",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Ingrese un nombre" : null,
              ),
              const SizedBox(height: 16),

              // Selector de color
              FormField<Color>(
                validator: (value) {
                  if (colorSelected == null) return 'Seleccione un color';
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
                                pickerColor: colorSelected ?? Colors.blue,
                                onColorChanged: (color) {
                                  setState(() {
                                    colorSelected = color;
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
                            backgroundColor: colorSelected ?? Colors.transparent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            colorSelected == null 
                              ? 'Seleccionar color' 
                              : '#${colorSelected!.toARGB32().toRadixString(16).substring(2)}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveCategory,
                  child: const Text("Guardar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
