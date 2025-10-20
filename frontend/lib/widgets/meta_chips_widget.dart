import 'package:flutter/material.dart';
import '../helpers/challenge_utils.dart';

class MetaChipsWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const MetaChipsWidget({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = ChallengeUtils.extractDuration(challenge);
    final points = challenge['reward_points'] ?? 0;

    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.25),
            border: Border.all(color: cs.primary.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.9), // 🔹 contraste dinámico
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        chip(Icons.schedule,
            duration > 0 ? 'Duración: $duration días' : 'Duración no definida'),
        chip(Icons.stars, 'Recompensa: $points pts'),
      ],
    );
  }
}
