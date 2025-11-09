import 'package:flutter/material.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/widgets/buttons/button_delete.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/icon_picker_field.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:frontend/widgets/success_dialog_widget.dart';
import '../../widgets/color_pickerfield.widget.dart';
import '../../services/api_service.dart';
import 'package:frontend/models/category.dart';

class CategoryFormScreen extends StatefulWidget {
  final String type; 
  final Category? category;

  const CategoryFormScreen({super.key, required this.type, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final ApiService api = ApiService();

  final TextEditingController nameController = TextEditingController();
  Color? colorSelected;
  final _formKey = GlobalKey<FormState>();
  IconData? selectedIcon;
  String? selectedIconName;
  bool isSaving = false;

  @override 
  void initState() {
    super.initState();
    if (widget.category != null) {
      nameController.text = widget.category!.name;
      colorSelected = Color(int.parse(widget.category!.color.substring(1), radix: 16) + 0xFF000000);
      selectedIconName = widget.category!.icon;
      selectedIcon = AppIcons.fromName(widget.category!.icon);
    }
    selectedIcon ??= Icons.category_outlined;
    selectedIconName ??= 'category';
  }

  void _showIconPicker() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: IconPickerWidget(
          selectedIcon: selectedIcon,
          onIconSelected: (icon) {
            setState(() {
              selectedIcon = icon;
                selectedIconName = AppIcons.iconMap.entries.firstWhere((entry) => entry.value == icon).key;
            });
          },
        ),
      );
    },
  );
}

void saveCategory() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();
  setState(() => isSaving = true);
  final name = nameController.text.trim();
  final colorHex = '#${colorSelected!.toARGB32().toRadixString(16).substring(2)}';
  // actualizar categoría
  if (widget.category != null) {
    final success = await api.updateCategory(id: widget.category!.id,
      data: {'name': name,'type': widget.type,'color': colorHex,'icon': selectedIconName},
    );
    setState(() => isSaving = false);
    if (success) {
      await showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: 'Actualizada con éxito',
          message: 'La categoría se ha actualizado correctamente.',
        ),
      );
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar la categoría')),
      );
    }
    return; 
  }
  final newCategory = await api.addCategory(
    name: name,
    type: widget.type,
    color: colorHex,
    icon: selectedIconName!,
  );
  setState(() => isSaving = false);
  if (newCategory != null) {
    await showDialog(
      context: context,
      builder: (_) => const SuccessDialogWidget(
        title: 'Guardada con éxito',
        message: 'La nueva categoría se ha creado correctamente.',
      ),
    );
    Navigator.pop(context, newCategory); // devolvemos la nueva
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
      await showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: 'Eliminada con éxito',
          message: 'La categoría se ha eliminado correctamente.',
        ),
      );
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

    return CustomScaffold(
      title: widget.category != null
          ? 'Editar ${typeLabels[widget.type]}: ${widget.category!.name}'
          : 'Nueva Categoría ${typeLabels[widget.type]}',
      currentRoute: '/category_form',
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Nombre + ícono
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Nombre",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            counterText: '',
                          ),
                          maxLength: 20,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? "Ingrese un nombre"
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _showIconPicker,
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: colorSelected ??
                              Theme.of(context).colorScheme.primary,
                          child: Icon(
                            selectedIcon ?? Icons.category_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Color
                  ColorPickerField(
                    initialColor: colorSelected,
                    onSaved: (color) => colorSelected = color,
                    validator: (color) =>
                        color == null ? 'Seleccione un color' : null,
                    label: 'Color de la categoría',
                  ),
                  const SizedBox(height: 24),

                  ButtonSave(
                    title: "Guardar Categoría",
                    message: "¿Seguro que quieres guardar esta categoría?",
                    onConfirm: saveCategory,
                    formKey: _formKey,
                  ),
                  const SizedBox(height: 12),

                  if (widget.category != null)
                    ButtonDelete(
                      title: "Eliminar Categoría",
                      message:
                          "¿Seguro que quieres deshabilitar esta categoría?",
                      onConfirm: _deleteCategory,
                    ),
                ],
              ),
            ),
          ),

          // Overlay de guardado
          if (isSaving)
            Positioned.fill(
              child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(
                  child: LoadingWidget(message: 'Guardando categoría...'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
