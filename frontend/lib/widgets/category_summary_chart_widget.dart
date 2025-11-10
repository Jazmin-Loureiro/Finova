import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class CategorySummaryChartWidget extends StatefulWidget {
  final Map<String, double> totals;
  final Map<String, Color> colorsMap;
  final String? symbol;

  const CategorySummaryChartWidget({
    super.key,
    required this.totals,
    required this.colorsMap,
     this.symbol,
  });

  @override
  State<CategorySummaryChartWidget> createState() =>
      _CategorySummaryChartWidgetState();
}

class _CategorySummaryChartWidgetState
    extends State<CategorySummaryChartWidget> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final totals = widget.totals;
    final colorsMap = widget.colorsMap;

    final totalValue =
        totals.isEmpty ? 0.0 : totals.values.reduce((a, b) => a + b);

    if (totalValue == 0) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Sin datos para mostrar',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    final entries = totals.entries.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Encabezado
          Text(
            'Resumen por categoría',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${widget.symbol ?? ''}${formatCurrency(totalValue, '')}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 18),

          //  Gráfico + leyenda
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gráfico
              SizedBox(
                height: 180,
                width: 180,
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 45,
                    borderData: FlBorderData(show: false),
                    sections: List.generate(entries.length, (i) {
                      final e = entries[i];
                      final color =
                          colorsMap[e.key] ?? Colors.grey.shade400;
                      final value = e.value;
                      final percentage = (value / totalValue) * 100;

                      // 🔸 Asegurar visibilidad mínima
                      final double adjustedValue = value == 0
                          ? 0.0
                          : (value < totalValue * 0.01
                              ? totalValue * 0.01
                              : value);

                      final isSelected = selectedIndex == i;
                      final double radius = isSelected ? 55 : 45;

                      final displayText = percentage < 1
                          ? '1%'
                          : '${percentage.toStringAsFixed(1)}%';

                      return PieChartSectionData(
                        color: color,
                        value: adjustedValue,
                        radius: radius,
                        title: displayText,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              //  Leyenda interactiva
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final color =
                        colorsMap[e.key] ?? Colors.grey.shade400;
                    final percentage =
                        ((e.value / totalValue) * 100).toStringAsFixed(1);
                    final isActive = selectedIndex == i;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = selectedIndex == i ? null : i;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: isActive ? 12 : 10,
                              width: isActive ? 12 : 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                            Text(
                              double.parse(percentage) < 1
                                  ? '1%'
                                  : '$percentage%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
