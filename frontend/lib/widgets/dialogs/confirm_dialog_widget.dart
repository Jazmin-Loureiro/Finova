import 'package:flutter/material.dart';

class ConfirmDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor; // pasás Theme.of(context).colorScheme.primary

  const ConfirmDialogWidget({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = "Aceptar",
    this.cancelText = "Cancelar",
    this.confirmColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: cs.primary, // texto del cancelar con color del sistema
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,   // fondo segun sistema que le pases
            foregroundColor: cs.onPrimary,   // 👈 asegura contraste (texto blanco en primario)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
