import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';
import '../services/api_service.dart';

class HomeInfoWidget extends StatefulWidget {
  const HomeInfoWidget({super.key});

  @override
  State<HomeInfoWidget> createState() => _HomeInfoWidgetState();
}

class _HomeInfoWidgetState extends State<HomeInfoWidget> {
  final ApiService api = ApiService();
  double? dolarValue;
  String? userCurrencyCode;
  bool isLoadingDolar = true;

  @override
  void initState() {
    super.initState();
    fetchDolarValue();
  }

  Future<void> fetchDolarValue() async {
    try {
      final currencies = await api.getCurrencies();
      final userCurrencyId = await api.getUserCurrency();

      final usd = currencies.firstWhere((c) => c.code == 'USD');
      final userCurrency =
          currencies.firstWhere((c) => c.id == userCurrencyId);

      // Calcular el valor de 1 USD en la moneda base del usuario
      final valor = userCurrency.rate! / usd.rate!;

      setState(() {
        dolarValue = valor;
        userCurrencyCode = userCurrency.code;
        isLoadingDolar = false;
      });
    } catch (e) {
      setState(() {
        dolarValue = null;
        userCurrencyCode = null;
        isLoadingDolar = false;
      });
    }
  }

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
    final currencySymbol = houseData['currency_symbol'] ?? '\$';
    final currencyCode = houseData['currency_code'] ?? 'ARS';


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
              child: RichText(
                key: ValueKey(balance),
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                  children: [
                    TextSpan(text: "$currencySymbol${balance.toStringAsFixed(2)} "),
                    TextSpan(
                      text: currencyCode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 🔹 Info extra (fecha + dólar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 📅 Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      getFormattedDate(),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),

                // 💵 Dólar (solo si la moneda base no es USD)
                if (userCurrencyCode != 'USD') ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      if (isLoadingDolar)
                        const Text(
                          "Cargando dólar...",
                          style:
                              TextStyle(fontSize: 13, color: Colors.black45),
                        )
                      else if (dolarValue != null && userCurrencyCode != null)
                        Text(
                          "1 USD = ${dolarValue!.toStringAsFixed(2)} $userCurrencyCode",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        )
                      else
                        const Text(
                          "Error dólar",
                          style: TextStyle(
                              fontSize: 13, color: Colors.redAccent),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
