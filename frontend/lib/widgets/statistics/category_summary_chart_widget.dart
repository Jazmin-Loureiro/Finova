import 'dart:ui';
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

    final theme = Theme.of(context);
    final totalGeneral = totals.values.fold(0.0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.30),
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              subtitle,
              style: TextStyle(
              color: Theme.of(  context).colorScheme.onSurface.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            if (userCurrency != null)
              Text(
                '${formatCurrency(
                  totalGeneral,
                  userCurrency!.code,
                  symbolOverride: userCurrency!.symbol,
                )} ${userCurrency!.code}',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

            const SizedBox(height: 16),
            Center(child: _buildPieChart()),

            const SizedBox(height: 18),
            ...totals.entries.map(
              (e) => _buildItemRow(
                context,
                e.key,
                e.value,
                totalGeneral,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            final double visual =
                value == 0 ? 0 : (value < minVisual ? minVisual : value);

            return PieChartSectionData(
              color: colorsMap?[entries[i].key] ??
                  Colors.primaries[i % Colors.primaries.length],
              value: visual,
              radius: 60,
              title: percent < 1 ? "1%" : "${percent.toStringAsFixed(1)}%",
              titleStyle: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItemRow(
      BuildContext context, String key, double amount, double totalGeneral) {
    final theme = Theme.of(context);
    final color = colorsMap?[key] ??
        Colors.primaries[key.hashCode % Colors.primaries.length];

    final percent = (amount / totalGeneral) * 100;
    final shownPercent = percent < 1 && percent > 0 ? 1 : percent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Badge de ícono gamificado
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        AppIcons.fromName(iconsMap?[key]),
                        size: 16,
                        color: color.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      key,
                      style:  TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "${shownPercent.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${formatCurrency(
                  amount,
                  userCurrency!.code,
                  symbolOverride: userCurrency!.symbol,
                )}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              widthFactor: (amount / totalGeneral).clamp(0.05, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
