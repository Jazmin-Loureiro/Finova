import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/money_maker.dart';
import 'money_maker_form_screen.dart';

class MoneyMakerListScreen extends StatefulWidget {
  const MoneyMakerListScreen({super.key});

  @override
  State<MoneyMakerListScreen> createState() => _MoneyMakerListScreenState();
}

class _MoneyMakerListScreenState extends State<MoneyMakerListScreen> {
  final ApiService api = ApiService();
  List<MoneyMaker> moneyMakers = [];
  bool isLoading = true;
  String currencyBase = '';
  String currencySymbol = '';

  // Convierte un color hex a Color de Flutter
  Color fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    fetchMoneyMakers();
  }

  // Obtiene las fuentes de dinero y la moneda base desde la API
  Future<void> fetchMoneyMakers() async {
    setState(() => isLoading = true);
    try {
      final response = await api.getMoneyMakersFull();
      moneyMakers = response['moneyMakers'];
      currencyBase = response['currency_base'] ?? '';
      currencySymbol = response['currency_symbol'] ?? '';
    } catch (e) {
      moneyMakers = [];
      currencyBase = '';
      currencySymbol = '';
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBalance = moneyMakers.fold(0, (sum, m) => sum + m.balanceConverted);

    return Scaffold(
      appBar: AppBar(title: const Text('Fuentes de Dinero')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : moneyMakers.isEmpty
              ? const Center(child: Text('No hay fuentes de dinero'))
              : Column(
                  children: [
                    // Saldo total en moneda base
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Saldo total: $currencyBase $currencySymbol ${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Gráfico circular
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(157, 255, 255, 255),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: moneyMakers.map((m) {
                            final porcentaje = totalBalance == 0
                                ? 0
                                : (m.balanceConverted / totalBalance) * 100;
                            return PieChartSectionData(
                              color: fromHex(m.color),
                              value: m.balanceConverted,
                              title: '${porcentaje.toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lista de fuentes de dinero
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: moneyMakers.length,
                        itemBuilder: (context, index) {
                          final m = moneyMakers[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading:
                                  Icon(Icons.account_balance_wallet, color: fromHex(m.color)),
                              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                Text('${m.type} - ${m.typeMoney}'),
                                Text('${m.typeMoney}: ${m.currencySymbol}${m.balance.toStringAsFixed(2)} '),
                                if (currencyBase != m.typeMoney)
                                  Text('Balance: $currencyBase $currencySymbol${m.balanceConverted.toStringAsFixed(2)}'),
                              ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoneyMakerFormScreen()),
          );
          if (result != null) {
            fetchMoneyMakers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}