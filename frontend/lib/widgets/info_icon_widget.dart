import 'package:flutter/material.dart';

class InfoIcon extends StatelessWidget {
  final String title;
  final String message;
  final double iconSize;

  const InfoIcon({
    super.key,
    required this.title,
    required this.message,
    this.iconSize = 30, // tamaño visual del ícono
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // Para TalkBack/VoiceOver
      button: true,
      label: title,
      hint: 'Muestra información adicional',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // hace clickeable todo el contenedor
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  message,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Entendido'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
          child: SizedBox(
            width: 48,   // área táctil mínima accesible
            height: 48,  // área táctil mínima accesible
            child: Center(
              child: Icon(
                Icons.help_outline,
                color: theme.colorScheme.primary,
                size: iconSize, // tamaño visual
              ),
            ),
          ),
      ),
    );
  }
}
