import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';

class ButtonSave extends StatelessWidget {
  final String title;          
  final String message;        
  final VoidCallback onConfirm; 
  final String label;         
  final Color color;           

  const ButtonSave({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.label = "Guardar",
    this.color = Colors.green,
    
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(

      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
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
            confirmText: "Guardar",
            cancelText: "Cancelar",
            confirmColor: color,
          ),
        );
        if (confirmed == true) onConfirm();
      },
    );
  }
}
