import 'package:flutter/material.dart';

class ChallengeHeaderWidget extends StatelessWidget {
  final int level;
  final int points;
  const ChallengeHeaderWidget({super.key, required this.level, required this.points});

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _pill(context, icon: Icons.stars, label: 'Nivel', value: '$level'),
          const SizedBox(width: 8),
          _pill(context,
              icon: Icons.military_tech, label: 'Puntos', value: '$points'),
        ],
      ),
    );
  }
}
