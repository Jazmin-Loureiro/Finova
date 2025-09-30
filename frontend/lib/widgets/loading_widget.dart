import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = "Cargando..."});

  @override
  Widget build(BuildContext context) {
    // mismo color que se usa en UserScreen para "Actualizando..."
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/home_loading1.json',
            width: 150,
            height: 150,
            repeat: true,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary, // violeta icono
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: textColor, // 👈 igual que en UserScreen
            ),
          ),
        ],
      ),
    );
  }
}
