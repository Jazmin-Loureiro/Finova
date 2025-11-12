import 'package:flutter/material.dart';
import 'package:frontend/models/goal.dart';
import 'package:lottie/lottie.dart';

class CompletedDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String buttonText;
  final String iconPath;
  final Goal goal;

  const CompletedDialog({
    super.key,
    required this.goal,
    this.iconPath = 'assets/lottie/congratulationgoal.json',
    this.title = "¡Meta completada!",
    this.message,
    this.buttonText = "Aceptar",
  });

  static Future<void> show(
    BuildContext context, {
    required Goal goal,
    String? title,
    String? message,
    String? iconPath,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "goalCompleted",
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) {
        return Center(
          child: CompletedDialog(
            goal: goal,
            title: title ?? "¡Meta completada!",
            message: message,
            iconPath: iconPath ?? 'assets/lottie/congratulationgoal.json',
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dynamicMessage = message ??
        "Completaste tu meta \"${goal.name}\" con éxito. "
        "Tu dinero reservado ha sido liberado.";

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.9),
                        cs.primaryContainer.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                Lottie.asset(
                  iconPath,
                  height: 95,
                  repeat: false,
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              dynamicMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: cs.onSurface,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  buttonText,
                  style: const TextStyle(
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
