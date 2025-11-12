import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerField extends FormField<Color> {
  ColorPickerField({
    Key? key,
    Color? initialColor,
    FormFieldSetter<Color>? onSaved,
    FormFieldValidator<Color>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String label = 'Color',
  }) : super(
          key: key,
          initialValue: initialColor ,
          onSaved: onSaved,
          validator: (value) {
            if (value == null) return 'Seleccione un color';
            if (validator != null) return validator(value);
            return null;
          },
          autovalidateMode: autovalidateMode,
          builder: (state) {
            final Color? colorSelected = state.value;

            Future<void> _showColorPickerBottomSheet(BuildContext context) async {
              Color tempColor = colorSelected ?? Colors.red;

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Elige un color',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Paleta rápida
                        BlockPicker(
                          pickerColor: tempColor,
                          onColorChanged: (color) {
                            state.didChange(color);
                            Navigator.of(context).pop();
                          },
                        ),

                        const SizedBox(height: 12),
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 8),

                        // Botón crear color
                        ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text(
                                    'Crear color personalizado',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: tempColor,
                                      onColorChanged: (color) {
                                        tempColor = color;
                                      },
                                      enableAlpha: false,
                                      displayThumbColor: true,
                                      showLabel: true,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        state.didChange(tempColor);
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text("Crear color personalizado"),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

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
                onTap: () => _showColorPickerBottomSheet(state.context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Ícono de color
                          CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            radius: 18,
                            child: const Icon(
                              Icons.color_lens_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Texto o franja
                          Expanded(
                            child: colorSelected == null
                                ? const Text(
                                    'Seleccionar color',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Container(
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: colorSelected,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
}
