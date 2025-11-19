import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';

class ButtonDelete extends StatelessWidget {
  final String title;          // Título del diálogo
  final String message;        // Mensaje del diálogo
  final VoidCallback onConfirm; // Acción a ejecutar si confirma
  final String label;          // Texto del botón
  final Color color;           // Color del botón
  final IconData icon;         // Ícono opcional

  const ButtonDelete({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.label = "Eliminar",
    this.color = Colors.red,
    this.icon = Icons.delete_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(vertical: 16),
         textStyle: const TextStyle(
           fontWeight: FontWeight.bold,
           fontSize: 16,
           letterSpacing: 0.5,
         ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        shadowColor: colorScheme.primary.withOpacity(0.4),
        elevation: 8,
      ),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ConfirmDialogWidget(
            title: title,
            message: message,
            confirmText: "Confirmar",
            cancelText: "Cancelar",
            confirmColor: color,
          ),
        );
        if (confirmed == true) onConfirm();
      },
    );
  }
}
