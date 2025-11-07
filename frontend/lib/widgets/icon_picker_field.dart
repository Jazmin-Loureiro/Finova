import 'package:flutter/material.dart';
import 'package:frontend/helpers/icon_utils.dart';

class IconPickerWidget extends StatefulWidget {
  final IconData? selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  const IconPickerWidget({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  IconData? _selectedIcon;

static final List<IconData> allIcons = AppIcons.all;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 🔹 Indicador superior
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text(
            "Seleccionar ícono",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 🔹 Grid de íconos
          Expanded(
            child: GridView.builder(
              itemCount: allIcons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final iconData = allIcons[index];
                final isSelected = _selectedIcon == iconData;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = iconData);
                    widget.onIconSelected(iconData);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      size: 28,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
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
