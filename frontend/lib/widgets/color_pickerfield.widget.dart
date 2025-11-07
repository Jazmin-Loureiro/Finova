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

            return InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                  Radius.circular(12))),
                errorText: state.errorText,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showDialog(
                    context: state.context,
                    barrierDismissible: true,
                    builder: (context) {
                      Color tempColor = colorSelected ?? Colors.red;

                      return Dialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Elige un color',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Paleta de colores predefinida
                              BlockPicker(
                                pickerColor: tempColor,
                                onColorChanged: (color) {
                                  state.didChange(color);
                                  Navigator.of(context).pop();
                                },
                                layoutBuilder: (context, colors, child) {
                                  return GridView.count(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 5,
                                    mainAxisSpacing: 5,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      for (Color color in colors)
                                        SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: child(color),
                                        ),
                                      // Botón para crear color personalizado
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          // Abrimos selector de color completo
                                          showDialog(
                                            context: state.context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Crear color',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                          
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
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      state.didChange(tempColor);
                                                      Navigator.of(context).pop();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(context).primaryColor, 
                                                    ),
                                                    child: const Text(
                                                      "Guardar",
                                                      style: TextStyle(color: Colors.white), 
                                                    ),
                                                  ),
                                              
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.grey.shade400),
                                          ),
                                          height: 50,
                                          width: 50,
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Circulito de vista previa (icono o color)
                              CircleAvatar(
                                backgroundColor:Colors.grey[300],
                                radius: 18,
                                child:  const Icon(Icons.color_lens_outlined,size: 16, color: Colors.grey)
                              ),
                              const SizedBox(width: 12),

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
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
}
