import 'package:flutter/material.dart';
import '../helpers/challenge_utils.dart';
import 'meta_chips_widget.dart';
import 'info_icon_widget.dart';

class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool completed;
  const ChallengeCardWidget({super.key, required this.challenge, this.completed = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ch = challenge;
    final rawProgress = ch['pivot']?['progress'] ?? 0;
    final progress = rawProgress is String
        ? double.tryParse(rawProgress) ?? 0.0
        : (rawProgress as num).toDouble();
    final state =
        ch['pivot']?['state'] ?? (completed ? 'completed' : 'in_progress');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                ch['name'] ?? '',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            // 🔹 Ícono de información solo para desafíos de ahorro
            if (ch['type'] == 'SAVE_AMOUNT')
              InfoIcon(
                title: 'Desafío de ahorro',
                message:
                    'Este desafío se completa ahorrando dentro de la meta creada automáticamente. '
                    'Cada vez que sumes dinero a esa meta, tu progreso se actualizará en esta sección.',
                iconSize: 20,
              ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((ch['description'] as String?)?.isNotEmpty == true)
              Text(
                ch['description'] ?? '',
                style: TextStyle(color: cs.onSurface.withOpacity(0.85)),
              ),

            // 🧩 Hint
            Builder(builder: (_) {
              final merged = {
                'type': ch['type'],
                'description': ch['description'],
                'payload': ch['pivot']?['payload'] ?? ch['payload'],
                'target_amount':
                    ch['pivot']?['target_amount'] ?? ch['target_amount'],
                'duration_days': ch['duration_days'],
                'reward_points': ch['reward_points'],
                'start_date': ch['pivot']?['start_date'],
              };
              final hint = _buildChallengeHint(merged);
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(
                  hint,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              );
            }),

            MetaChipsWidget(challenge: ch),
            const SizedBox(height: 8),

            // 🔹 Progreso
            _progressBar(context, ch, state, progress),

            // 🔹 Mensaje final
            _statusRow(context, ch, progress, state),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(
      BuildContext context, Map<String, dynamic> ch, String state, double progress) {
    final cs = Theme.of(context).colorScheme;
    final p = ChallengeUtils.decodePayload(ch['pivot']?['payload'] ?? ch['payload']);
    final type = ch['type'];

    Color trackColor = cs.surfaceContainerHighest.withOpacity(0.25);

    Widget progressContainer(double value, Color fillColor) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: value,
            color: fillColor,
            backgroundColor: trackColor,
            minHeight: 6,
          ),
        ),
      );
    }

    if (type == 'SAVE_AMOUNT') {
      final double goal = (p['goal_amount'] ?? p['amount'] ?? 0).toDouble();
      final double saved = (p['total_ahorro'] ?? 0).toDouble();
      final double realProgress = goal > 0 ? (saved / goal).clamp(0.0, 1.0) : 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          progressContainer(realProgress, state == 'completed' ? Colors.green : cs.primary),
          const SizedBox(height: 6),
          Text(
            'Llevás ahorrado ${ChallengeUtils.symbolOf(ch)}${saved.toStringAsFixed(0)} '
            'de ${ChallengeUtils.symbolOf(ch)}${goal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (type == 'REDUCE_SPENDING_PERCENT') {
      final num? maxAllowed = p['max_allowed'] is num
          ? p['max_allowed']
          : (p['max_allowed'] is String ? num.tryParse(p['max_allowed']) : null);
      final num? currentSpent = p['current_spent'] is num
          ? p['current_spent']
          : (p['current_spent'] is String ? num.tryParse(p['current_spent']) : null);

      if (maxAllowed != null && currentSpent != null) {
        final symbol = ChallengeUtils.symbolOf(ch);
        final percent = (currentSpent / maxAllowed).clamp(0.0, 1.0);
        Color color;
        if (percent < 0.5) {
          color = Colors.green;
        } else if (percent < 0.8) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }

        final remaining = (maxAllowed - currentSpent).clamp(0, maxAllowed);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            progressContainer(percent, color),
            const SizedBox(height: 4),
            Text(
              remaining > 0
                  ? 'Te queda ${symbol}${remaining.toStringAsFixed(0)} '
                      'de ${symbol}${maxAllowed.toStringAsFixed(0)}'
                  : 'Te pasaste del límite',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }
    }

    return progressContainer(
      (progress / 100).clamp(0.0, 1.0),
      state == 'completed' ? Colors.green : cs.primary,
    );
  }

  Widget _statusRow(
      BuildContext context, Map<String, dynamic> ch, double progress, String state) {
    final cs = Theme.of(context).colorScheme;

    String text;
    Color color;
    IconData icon;
    final points = ch['reward_points'] ?? 0;

    switch (state) {
      case 'completed':
        text = points > 0
            ? 'Objetivo alcanzado (+$points pts)'
            : 'Objetivo alcanzado';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'failed':
        text = 'Desafío fallido';
        color = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;
      default:
        text = 'En progreso (${progress.toStringAsFixed(0)}%)';
        color = cs.onSurface.withOpacity(0.8);
        icon = Icons.timelapse_outlined;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _buildChallengeHint(Map<String, dynamic> ch) {
    final type = (ch['type'] ?? '') as String;
    final payload = ChallengeUtils.decodePayload(ch['payload']);
    final target = ch['target_amount'];
    final symbol = ChallengeUtils.symbolOf(ch);

    String fmtNum(num n) =>
        n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(0);

    switch (type) {
      case 'SAVE_AMOUNT':
        final num? amount =
            (target is num) ? target : (payload['amount'] as num?);
        return amount != null
            ? 'Ahorrá $symbol${fmtNum(amount)}'
            : 'Ahorrá un monto personalizado';
      case 'REDUCE_SPENDING_PERCENT':
        final int windowDays = (payload['window_days'] as num?)?.toInt() ?? 30;
        final num? maxAllowed = payload['max_allowed'] is num
            ? payload['max_allowed']
            : (payload['max_allowed'] is String
                ? num.tryParse(payload['max_allowed'])
                : null);
        if (maxAllowed != null) {
          return 'No superes ${symbol}${maxAllowed.toStringAsFixed(0)} en gastos.\n'
              'Se evaluará durante $windowDays días desde que aceptes.';
        }
        return 'Se evaluará durante $windowDays días desde que aceptes.';
      case 'ADD_TRANSACTIONS':
        final int? count = (payload['count'] as num?)?.toInt() ??
            (target is num ? target.toInt() : null);
        return count != null
            ? 'Registrá $count movimientos'
            : 'Registrá tus movimientos esta semana';
      default:
        return (ch['description'] as String?) ?? '';
    }
  }
}
