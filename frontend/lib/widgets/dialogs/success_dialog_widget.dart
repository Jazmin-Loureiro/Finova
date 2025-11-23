import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessDialogWidget extends StatelessWidget {
  final bool? isFailure;
  final String title;
  final String message;
  final String buttonText;

  const SuccessDialogWidget({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "Aceptar",
    this.isFailure,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lottieAsset = isFailure == true
                  ? 'assets/lottie/Errorfailure.json'
                  : 'assets/lottie/success.json';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
           Lottie.asset(
              lottieAsset,
              height: 50,
              repeat: false,
            ),
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
