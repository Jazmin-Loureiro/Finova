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
    if (totals.isEmpty) {
      return const EmptyStateWidget(
        title: 'No hay datos',
        message: 'Todavía no hay saldos para mostrar',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    double totalGeneral = 0;
    // Calcular total en moneda del usuario si showTotal = true
    if (showTotal && userCurrency != null) {
      totalGeneral = totals.values.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );
    }

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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULOS
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

         
          if (showTotal && userCurrency != null)
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

          if (showTotal && userCurrency != null) const SizedBox(height: 16),

          // LISTA DE SALDOS
          ...totals.entries.map((entry) {
            final label = entry.key;
            final BalanceItem item = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // NOMBRE DE CUENTA/MONEDA
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  // MONTO
                  Text(
                    formatCurrency(
                      item.amount,
                      item.currency.code,
                      symbolOverride: item.currency.symbol,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
