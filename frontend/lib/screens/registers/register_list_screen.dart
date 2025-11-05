import 'package:flutter/material.dart';
import 'package:frontend/widgets/category_summary_chart_widget.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:frontend/widgets/month_header_widget.dart';
import '../../services/api_service.dart';
import '../../models/register.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_scaffold.dart';

class RegisterListScreen extends StatefulWidget {
  final int moneyMakerId;
  final String moneyMakerName;
  const RegisterListScreen({
    super.key,
    required this.moneyMakerId,
    required this.moneyMakerName,
  });

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Register> registers = [];

  //  agregamos una variable de estado para el mes actual
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchRegisters();
  }

  Future<void> _fetchRegisters() async {
    setState(() => isLoading = true);
    try {
      registers = await api.getRegistersByMoneyMaker(widget.moneyMakerId);
      registers = registers.where((r) {
        return r.created_at.year == selectedDate.year &&
            r.created_at.month == selectedDate.month;
      }).toList();
    } catch (e) {
      registers = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Totales por categoría
  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (var r in registers) {
      final category = r.category.name;
      totals[category] = (totals[category] ?? 0) + r.balance;
    }
    return totals;
  }

  // Mapa de categoría a color
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
          : Column(
                  children: [
                    MonthHeaderWidget(
                      date: selectedDate,
                      onPrevious: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month - 1,
                          );
                        });
                        _fetchRegisters(); // recarga del backend
                      },
                      onNext: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month + 1,
                          );
                        });
                        _fetchRegisters(); // recarga del backend
                      },
                    ),

                    const SizedBox(height: 10),
                    if (hasData) ...[
                     CategorySummaryChartWidget(
                        totals: totals,
                        colorsMap: colorsMap,
                      ),
                    ],
                    const SizedBox(height: 8),

                    registers.isEmpty ? EmptyStateWidget(
                          title: "Aún no hay registros.",
                          message:
                              "No has reservado ninguna cantidad aún.",
                          icon: Icons.receipt_long,
                        ) : 
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
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
                                      r.type == "income"
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: r.type == "income"
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Contenido principal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$tipo • $category',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              dateFormat.format(r.created_at),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        if (r.goal != null)
                                          Text(
                                            'Meta: ${r.goal!.name} - Reservado: ${r.currency.symbol}${r.reserved_for_goal}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                        const SizedBox(height: 4),
                                        Text(
                                          '${r.currency.symbol}${r.balance.toStringAsFixed(2)} ${r.currency.code}',
                                          style: const TextStyle(fontSize: 14),
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

}
