import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/register.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RegisterListScreen extends StatefulWidget {
  final int moneyMakerId;
  const RegisterListScreen({super.key, required this.moneyMakerId});

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Register> registers = [];

  @override
  void initState() {
    super.initState();
    fetchRegisters();
  }

  Future<void> fetchRegisters() async {
    setState(() => isLoading = true);
    try {
      registers = await api.getRegistersByMoneyMaker(widget.moneyMakerId);
    } catch (e) {
      registers = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  //  Totales por categoría
  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (var r in registers) {
      final category = r.category?.name ?? 'Sin categoría';
      totals[category] = (totals[category] ?? 0) + r.balance;
    }
    return totals;
  }

  //  Mapa de categoría a color
  Map<String, Color> getCategoryColors() {
    final Map<String, Color> map = {};
    for (var r in registers) {
      if (r.category != null) {
        map[r.category!.name] =
            Color(int.parse('0xff${r.category!.color.substring(1)}'));
      } 
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totals = getTotalsByCategory();
    final colorsMap = getCategoryColors();
    final hasData = totals.values.any((v) => v > 0);


    return Scaffold(
      appBar: AppBar(title: const Text('Registros')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : registers.isEmpty
              ? const Center(child: Text('No hay registros para esta moneda'))
              : Column(
                  children: [
                    const SizedBox(height: 16),


if (hasData) ...[

SizedBox(
  height: 250,
  child: PieChart(
    PieChartData(
      sections: totals.entries.map((e) {
        final color = colorsMap[e.key] ?? Colors.grey;
        final totalValue = totals.values.reduce((a, b) => a + b);
final percentage = totalValue == 0 
    ? 0 
    : ((e.value / totalValue) * 100).toStringAsFixed(1);
        return PieChartSectionData(
          value: e.value,
  title: percentage == 0 ? '' : '$percentage%', // si es 0, no mostramos nada
          color: color,
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 30,
    ),
  ),
),


                    const SizedBox(height: 8),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: totals.entries.map((e) {
                        final color = colorsMap[e.key] ?? Colors.grey;
                        return _buildLegend(color, e.key);
                      }).toList(),
                    ),
],
                    // LISTA DE REGISTROS
                    Expanded(
                      child: ListView.builder(
                        itemCount: registers.length,
                        itemBuilder: (context, index) {
                          final r = registers[index];
                          final tipo =
                              r.type == "income" ? "Ingreso" : "Gasto";
                          final category =
                              totals == 0 ? 'Sin categoría' : r.category?.name ?? 'Sin categoría';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                r.type == "income"
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: r.type == "income"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                r.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '$tipo - $category - ${r.currency.code} ${r.currency.symbol}${r.balance.toStringAsFixed(2)}'),
                              trailing:
                                  Text(dateFormat.format(r.created_at)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
