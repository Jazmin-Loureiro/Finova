import 'package:flutter/material.dart';
import 'package:frontend/widgets/empty_state_widget.dart';

/// Widget genérico para seleccionar un ítem desde un bottom sheet.
class BottomSheetPickerField<T> extends FormField<T> {
  BottomSheetPickerField({
    Key? key,
    required List<T> items,
    required String Function(T) itemLabel, // cómo mostrar el nombre
    Widget Function(T)? itemIcon, // ícono o avatar opcional
    String label = 'Seleccionar',
    String? title, // título del modal (opcional)
    String? emptyText,
    T? initialValue,
    required ValueChanged<T?> onChanged,
    FormFieldValidator<T>? validator,
    bool isRequired = true, 
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: (value) {
            if (!isRequired) return null;
            if (validator != null) return validator(value);
            if (value == null) return 'Seleccione una opción';
            return null;
          },
          autovalidateMode: autovalidateMode,
          builder: (state) {
            final selectedItem = state.value;

            Future<void> _showPickerBottomSheet(BuildContext context) async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicador superior
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

                        // Título
                        Text(
                          title ?? label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        items.isEmpty ? Center(
                            child: EmptyStateWidget(
                            title: "Sin elementos",
                            message: "No hay elementos disponibles para seleccionar.",
                            icon: Icons.info_outline,
                             ),)
                        : Flexible(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isSelected = item == selectedItem;

                              return GestureDetector(
                                onTap: () {
                                  state.didChange(item);
                                  onChanged(item);
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    leading: itemIcon?.call(item),
                                    title: Text(
                                      itemLabel(item),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
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
                },
              );
            }

            // Campo visual principal
            return InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                errorText: state.errorText,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showPickerBottomSheet(state.context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedItem != null
                            ? itemLabel(selectedItem)
                            : (emptyText ?? 'Seleccionar'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
}
