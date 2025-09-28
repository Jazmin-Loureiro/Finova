import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeInfoWidget extends StatefulWidget {
  const HomeInfoWidget({super.key});

  @override
  State<HomeInfoWidget> createState() => _HomeInfoWidgetState();
}

class _HomeInfoWidgetState extends State<HomeInfoWidget> {
  final ApiService api = ApiService();
  double? _balance;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _loadBalance());
  }

  Future<void> _loadBalance() async {
    try {
      final data = await api.getHouseStatus();
      setState(() {
        _balance = double.tryParse(data['balance'].toString()) ?? 0;
      });
    } catch (e) {
      debugPrint("Error balance: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final meses = [
      "enero","febrero","marzo","abril","mayo","junio",
      "julio","agosto","septiembre","octubre","noviembre","diciembre"
    ];
    final dias = [
      "Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"
    ];
    return "${dias[now.weekday % 7]}, ${now.day} de ${meses[now.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    if (_balance == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final balanceColor = _balance! > 0 ? Colors.green[700] : Colors.red[700];

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), // ✅ corregido
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), // ✅ corregido
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
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              child: Text(
                "\$${_balance!.toStringAsFixed(2)}",
                key: ValueKey(_balance),
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
