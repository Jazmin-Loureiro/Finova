import 'package:flutter/material.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/models/category.dart';

class CategoryPickerWidget extends StatefulWidget {
  final List<Category> categories;
  final Category? selectedCategory;

  const CategoryPickerWidget({
    super.key,
    required this.categories,
    this.selectedCategory,
  });

  /// Método estático para abrir el picker
  static Future<Category?> show(
    BuildContext context, {
    required List<Category> categories,
    Category? initialCategory,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryPickerWidget(
        categories: categories,
        selectedCategory: initialCategory,
      ),
    );
  }

  @override
  State<CategoryPickerWidget> createState() => _CategoryPickerWidgetState();
}

class _CategoryPickerWidgetState extends State<CategoryPickerWidget> {
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Indicador superior
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // 🔹 Título
          const Text(
            "Seleccionar categoría",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // 🔹 Lista scrolleable de categorías
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final icon = AppIcons.fromName(category.icon);
                final color = Color(
                  int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
                );

                final isSelected = _selectedCategory?.id == category.id;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context, category);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
