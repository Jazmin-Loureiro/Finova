import 'package:flutter/material.dart';

class SuccessDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const SuccessDialogWidget({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "Aceptar",
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: cs.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () => Navigator.pop(context, true), // 👈 devuelve true
  child: Text(buttonText),
),

      ],
    );
  }
}
