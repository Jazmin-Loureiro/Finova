import 'package:flutter/material.dart';
import '../../widgets/ColorPickerField.widget.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';
import '../../services/api_service.dart';
import 'package:frontend/models/category.dart';

class CategoryFormScreen extends StatefulWidget {
  final String type; 
  final Category? category; // Categoría opcional para edición
  const CategoryFormScreen({super.key, required this.type, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final ApiService api = ApiService();

  final TextEditingController nameController = TextEditingController();
  Color? colorSelected;

  final _formKey = GlobalKey<FormState>();

  @override 
  void initState() {
    super.initState();
    if (widget.category != null) {
      nameController.text = widget.category!.name;
      colorSelected = Color(int.parse(widget.category!.color.substring(1), radix: 16) + 0xFF000000);
    }
  }

// Función para guardar la categoría
  void saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    final colorHex = '#${colorSelected!.toARGB32().toRadixString(16).substring(2)}';
    final data = {
      'name': name,
      'type': widget.type,
      'color': colorHex,
    };
    bool success = false;
    if (widget.category != null) {
    // Actualizar categoría existente
    success = await api.updateCategory(id: widget.category!.id, data: data);
  } else {
    // Crear nueva categoría
    success = await api.addCategory(name: name, type: widget.type, color: colorHex );
  }
  if (!mounted) return;
  if (success) {
    Navigator.pop(context, data); // devolvemos la categoría recién guardada
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la categoría')),
      );
    }
  }

  Future<void> _deleteCategory() async {
      if (widget.category == null) return;
      try {
        await api.deleteCategory(widget.category!.id);
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error al eliminar categoría: $e');
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
        title: Text(widget.category != null
                ? 'Editar ${typeLabels[widget.type]}: ${widget.category!.name}'
                : 'Nueva Categoria ${typeLabels[widget.type]}')
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
           // Selector de color (reutilizable)
            ColorPickerField(
              initialColor: colorSelected,
              onSaved: (color) => colorSelected = color,
              validator: (color) =>
                  color == null ? 'Seleccione un color' : null,
              label: 'Color de la categoría',
            ),
              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveCategory,
                  child: const Text("Guardar"),
                ),
              ),

              if (widget.category != null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar Categoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ConfirmDialogWidget(
                      title: "Eliminar Categoria",
                      message: "¿Seguro que querés deshabilitar esta categoría?",
                      confirmText: "Eliminar",
                      cancelText: "Cancelar",
                      confirmColor: Colors.red,
                    ),
                  );
                  if (confirmed == true) {
                    _deleteCategory(); // o _deleteGoal() según tu función
                  }
                },
              ),
              ]
            ],
          ),

        ),

      ),
    );
  }
}
