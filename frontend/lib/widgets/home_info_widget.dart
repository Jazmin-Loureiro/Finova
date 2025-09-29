import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';

class HomeInfoWidget extends StatelessWidget {
  const HomeInfoWidget({super.key});

  String getFormattedDate() {
    final now = DateTime.now();
    const meses = [
      "enero","febrero","marzo","abril","mayo","junio",
      "julio","agosto","septiembre","octubre","noviembre","diciembre"
    ];
    const dias = [
      "Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"
    ];
    return "${dias[now.weekday % 7]}, ${now.day} de ${meses[now.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    final houseData = context.watch<HouseProvider>().houseData;

    if (houseData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final balance = double.tryParse(houseData['balance'].toString()) ?? 0;
    final balanceColor = balance > 0 ? Colors.green[700] : Colors.red[700];

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 22, color: balanceColor),
                const SizedBox(width: 8),
                const Text(
                  "Saldo disponible",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔹 Balance con animación
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                "\$${balance.toStringAsFixed(2)}",
                key: ValueKey(balance),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 🔹 Info extra (fecha + dólar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      getFormattedDate(),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("Dólar: -",
                        style: TextStyle(fontSize: 13, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
