import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategorySummaryChartWidget extends StatelessWidget {
  final Map<String, double> totals;
  final Map<String, Color> colorsMap;

  const CategorySummaryChartWidget({
    super.key,
    required this.totals,
    required this.colorsMap,
  });

  @override
  Widget build(BuildContext context) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -60,
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                    sections: totals.entries.map((e) {
                      final color = colorsMap[e.key] ?? Colors.grey.shade400;
                      final percentage = ((e.value / totalValue) * 100)
                          .toStringAsFixed(1);
                      return PieChartSectionData(
                        color: color,
                        value: e.value,
                        radius: 40,
                        title: percentage == '0.0' ? '' : '$percentage%',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
      
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(0)}',
                      style:  TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

  
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: totals.entries.map((e) {
                  final color = colorsMap[e.key] ?? Colors.grey.shade400;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.key,
                          style:  TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
