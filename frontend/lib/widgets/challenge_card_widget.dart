import 'package:flutter/material.dart';
import '../helpers/challenge_utils.dart';
import 'meta_chips_widget.dart';
import 'info_icon_widget.dart';

class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool completed;
  const ChallengeCardWidget({super.key, required this.challenge, this.completed = false});

  @override
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
  margin: const EdgeInsets.only(bottom: 14),
  elevation: 3, // ✔ igual que Goals
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {}, // dejalo vacío o agregá acción si querés
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Título
          Row(
            children: [
              Expanded(
                child: Text(
                  ch['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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

          const SizedBox(height: 8),

          // 🔹 Descripción
          if ((ch['description'] as String?)?.isNotEmpty == true) ...[
            Text(
              ch['description'] ?? '',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 🔹 Hint
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
            return Text(
              hint,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            );
          }),

          const SizedBox(height: 12),

          // 🔹 Chips
          MetaChipsWidget(challenge: ch),

          const SizedBox(height: 12),

          // 🔹 Progreso
          _progressBar(context, ch, state, progress),

          const SizedBox(height: 12),

          // 🔹 Estado final
          _statusRow(context, ch, progress, state),
        ],
      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // ✔ igual que Goals
      child: LinearProgressIndicator(
        value: value,
        color: fillColor,
        backgroundColor: Colors.grey[300], // ✔ mismo fondo de Goals
        minHeight: 6,
        borderRadius: BorderRadius.circular(10), // ✔ igual que Goals
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
        const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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

  // Porcentaje genérico
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      progressContainer(
        (progress / 100).clamp(0.0, 1.0),
        state == 'completed' ? Colors.green : cs.primary,
      ),
    ],
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

    // 🗓️ Cálculo de fechas (inicio, fin, fallo o completado)
    String? startStr = ch['pivot']?['start_date'];
    String? failedAtStr = ch['pivot']?['failed_at'] ?? ch['pivot']?['updated_at'];
    String? completedAtStr = ch['pivot']?['completed_at'] ?? ch['pivot']?['updated_at'];
    int? durationDays = ch['duration_days'] is int
        ? ch['duration_days']
        : int.tryParse('${ch['duration_days']}');

    String? remainingInfo;
    if (startStr != null && durationDays != null) {
      final startDate = DateTime.tryParse(startStr)?.toLocal();
      if (startDate != null) {
        final endDate = startDate.add(Duration(days: durationDays));
        final now = DateTime.now();

        if (state == 'failed') {
          if (failedAtStr != null) {
            final failedAt = DateTime.tryParse(failedAtStr)?.toLocal();
            if (failedAt != null) {
              remainingInfo =
                  '❌ Falló el ${failedAt.day}/${failedAt.month}${failedAt.year != now.year ? "/${failedAt.year}" : ""}';
            } else {
              remainingInfo = '❌ Falló antes del fin';
            }
          } else {
            remainingInfo = '❌ Falló antes del fin';
          }
        } else if (state == 'completed') {
          if (completedAtStr != null) {
            final completedAt = DateTime.tryParse(completedAtStr)?.toLocal();
            if (completedAt != null) {
              remainingInfo =
                  '✅ Completado el ${completedAt.day}/${completedAt.month}${completedAt.year != now.year ? "/${completedAt.year}" : ""}';
            }
          } else {
            remainingInfo =
                '✅ Completado el ${endDate.day}/${endDate.month}';
          }
        } else {
          // En progreso
          final remaining = endDate.difference(now);
          if (remaining.isNegative) {
            remainingInfo = '📅 Finalizado el ${endDate.day}/${endDate.month}';
          } else if (remaining.inDays >= 1) {
            remainingInfo =
                '⏳ Faltan ${remaining.inDays} día${remaining.inDays == 1 ? '' : 's'} '
                '(termina el ${endDate.day}/${endDate.month})';
          } else {
            final hours = remaining.inHours;
            remainingInfo =
                '⏰ Faltan $hours hora${hours == 1 ? '' : 's'} '
                '(termina el ${endDate.day}/${endDate.month})';
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (remainingInfo != null) ...[
          const SizedBox(height: 6),
          Text(
            remainingInfo,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
