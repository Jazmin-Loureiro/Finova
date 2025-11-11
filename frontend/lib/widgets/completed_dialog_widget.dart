import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CompletedDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const CompletedDialog({
    super.key,
    this.title = "¡Meta completada!",
    this.message = "Ganaste una nueva medalla y subiste de nivel 🎯",
    this.buttonText = "Aceptar",
  });

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "goalCompleted",
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) {
        return const Center(child: CompletedDialog());
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🏆 Ícono o animación
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Lottie.asset(
                  'assets/lottie/goal_trophy.json', // 👈 poné tu animación
                  height: 90,
                  repeat: false,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🎉 Título
            const Text(
              "¡Meta completada!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // 💬 Descripción
            const Text(
              "Ganaste una nueva medalla y subiste de nivel 🎯",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // 🌈 Botón azul estilo app moderna
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Aceptar",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
