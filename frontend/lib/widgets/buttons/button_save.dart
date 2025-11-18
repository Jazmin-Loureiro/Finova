import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';

class ButtonSave extends StatelessWidget {
  final String title;          
  final String message;        
  final VoidCallback onConfirm; 
  final String label;         
  final Color color;           
  final bool variant;    
  final GlobalKey<FormState>? formKey; 

  const ButtonSave({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.label = "Guardar",
    this.color = Colors.green,
    this.variant = false,
    this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      label: Text(label),
      icon: variant ? Icon(Icons.refresh) : Icon(Icons.check_circle),
      style: ElevatedButton.styleFrom(
        backgroundColor: variant ? Colors.greenAccent.shade700 : colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
        if (formKey != null) {
          final isValid = formKey!.currentState?.validate() ?? false;
          if (!isValid) return; 
        }
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
