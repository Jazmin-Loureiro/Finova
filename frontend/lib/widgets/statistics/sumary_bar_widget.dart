import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/models/balance_item.dart';
import 'package:frontend/widgets/empty_state_widget.dart';

class SummaryBarCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  /// SOLO SALDOS → Map<String, BalanceItem>
  final Map<String, BalanceItem> totals;

  /// Total convertido a la moneda del usuario (opcional)
  final Currency? userCurrency;
  final bool showTotal;

  const SummaryBarCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totals,
    this.userCurrency,
    this.showTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    if (totals.isEmpty) {
      return const EmptyStateWidget(
        title: 'No hay datos',
        message: 'Todavía no hay saldos para mostrar',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    double totalGeneral = 0;
    if (showTotal && userCurrency != null) {
      totalGeneral = totals.values.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: primary.withOpacity(0.30),
          width: 1.5,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: primary.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          if (showTotal && userCurrency != null)
            Text(
              formatCurrency(
                totalGeneral,
                userCurrency!.code,
                symbolOverride: userCurrency!.symbol,
              ),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: primary.withOpacity(0.85),
                shadows: [
                  Shadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),

          if (showTotal && userCurrency != null)
            const SizedBox(height: 16),

          ...totals.entries.map((entry) {
            final label = entry.key;
            final BalanceItem item = entry.value;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${formatCurrency(
                      item.amount,
                      item.currency.code,
                      symbolOverride: item.currency.symbol,
                    )} ${item.currency.code}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
