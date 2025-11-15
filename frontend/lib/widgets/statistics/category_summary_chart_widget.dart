import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class CategorySummaryChartWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  /// SOLO CATEGORÍAS → Map<String, double>
  final Map<String, double> totals;

  final Currency? userCurrency;
  final Map<String, Color>? colorsMap;
  final Map<String, String>? iconsMap;

  const CategorySummaryChartWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totals,
    this.userCurrency,
    this.colorsMap,
    this.iconsMap,
  });

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const EmptyStateWidget(
        title: 'Sin datos',
        message: 'No se encontraron categorías',
        icon: Icons.category_outlined,
      );
    }

    final totalGeneral = totals.values.fold(0.0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
       
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 14),

            // TOTAL GENERAL
            if (userCurrency != null)
              Text(
                formatCurrency(
                  totalGeneral,
                  userCurrency!.code,
                  symbolOverride: userCurrency!.symbol,
                ),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 16),

            // -----------------------------------
            // PIE CHART
            // -----------------------------------
            Center(child: _buildPieChart()),

            // -----------------------------------
            // LISTA DE ÍTEMS
            // -----------------------------------
            ...totals.entries.map((e) {
              return _buildItemRow(
                e.key,
                e.value,
                totalGeneral,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // PIE CHART
  Widget _buildPieChart() {
    final entries = totals.entries.toList();
    final total = totals.values.fold<double>(0, (s, v) => s + v);

    return SizedBox(
      height: 220,
      width: 220,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 42,
          sections: List.generate(entries.length, (i) {
            final value = entries[i].value;

            final percent = (value / total) * 100;
            final minVisual = total * 0.03;
            final double visual = value == 0 ? 0 : (value < minVisual ? minVisual : value);

            return PieChartSectionData(
              color: colorsMap?[entries[i].key] ??
                  Colors.primaries[i % Colors.primaries.length],
              value: visual,
              radius: 60,
              title: percent < 1 ? "1%" : "${percent.toStringAsFixed(1)}%",
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ),
      ),
    );
  }

  // ITEM ROW
  Widget _buildItemRow(String key, double amount, double totalGeneral) {
    final color = colorsMap?[key] ??
        Colors.primaries[key.hashCode % Colors.primaries.length];

    final percent = (amount / totalGeneral) * 100;
    final shownPercent = percent < 1 && percent > 0 ? 1 : percent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila con icono + nombre + porcentaje + monto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 25,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.fromName(iconsMap?[key]),
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),

                    Text(
                      key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "(${shownPercent.toStringAsFixed(1)}%)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                formatCurrency(
                  amount,
                  userCurrency!.code,
                  symbolOverride: userCurrency!.symbol,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Barra horizontal
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: amount / totalGeneral < 0.07
                  ? 0.07
                  : (amount / totalGeneral).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
