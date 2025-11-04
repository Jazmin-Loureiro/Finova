import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthHeaderWidget extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final DateTime? date;

  const MonthHeaderWidget({
    super.key,
    this.onPrevious,
    this.onNext,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = date ?? DateTime.now();
    final monthName = toBeginningOfSentenceCase(
      DateFormat('MMMM yyyy', 'es_ES').format(now),
    );
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: scheme.primary,
            onPressed: onPrevious,
            splashRadius: 24,
          ),

          Text(
            monthName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: scheme.primary,
            onPressed: onNext,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}
