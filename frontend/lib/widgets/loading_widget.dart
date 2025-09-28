import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = "Cargando..."});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/home_loading1.json', // 👈 podés cambiarlo por home_loading2
            width: 150,
            height: 150,
            repeat: true,
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
