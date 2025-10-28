import 'package:flutter/material.dart';
import 'package:frontend/widgets/loading_widget.dart';
import '../../services/api_service.dart';
import '../../models/register.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/custom_scaffold.dart';

class RegisterListScreen extends StatefulWidget {
  final int moneyMakerId;
  final String moneyMakerName;
  const RegisterListScreen({super.key, required this.moneyMakerId, required this.moneyMakerName});

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
    _fetchRegisters();
  }

  Future<void> _fetchRegisters() async {
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
      final category = r.category.name;
      totals[category] = (totals[category] ?? 0) + r.balance;
    }
    return totals;
  }

  //  Mapa de categoría a color
  Map<String, Color> getCategoryColors() {
    final Map<String, Color> map = {};
    for (var r in registers) {
        map[r.category.name] =
            Color(int.parse('0xff${r.category.color.substring(1)}'));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totals = getTotalsByCategory();
    final colorsMap = getCategoryColors();
    final hasData = totals.values.any((v) => v > 0);

    return CustomScaffold(
      title: 'Registros de ${widget.moneyMakerName}',
      currentRoute: '/registers',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchRegisters,
        ),
      ],
      body: isLoading
          ? const Center(child: LoadingWidget())
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
                              final totalValue =
                                  totals.values.reduce((a, b) => a + b);
                              final percentage = totalValue == 0
                                  ? 0
                                  : ((e.value / totalValue) * 100)
                                      .toStringAsFixed(1);
                              return PieChartSectionData(
                                value: e.value,
                                title: percentage == '0.0'
                                    ? ''
                                    : '$percentage%',
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

                    const SizedBox(height: 8),

                    /// LISTA DE REGISTROS
                    Expanded(
                      child: ListView.builder(
                        itemCount: registers.length,
                        itemBuilder: (context, index) {
                          final r = registers[index];
                          final tipo =
                              r.type == "income" ? "Ingreso" : "Gasto";
                          final category = r.category.name;

                       return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icono principal
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: r.type == "income"
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.red.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      r.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: r.type == "income" ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Contenido principal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Nombre + Tipo/Categoría
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$tipo • $category',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              dateFormat.format(r.created_at),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Meta asociada (opcional)
                                        if (r.goal != null)
                                          Text(
                                            'Meta: ${r.goal!.name} - Reservado: ${r.currency.symbol}${r.reserved_for_goal}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                        const SizedBox(height: 4),
                                        Text(
                                          '${r.currency.symbol}${r.balance.toStringAsFixed(2)} ${r.currency.code}',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
