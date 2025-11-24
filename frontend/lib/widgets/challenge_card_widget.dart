import 'package:flutter/material.dart';
import '../helpers/challenge_utils.dart';
import '../helpers/format_utils.dart';
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
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
                      iconSize: 25,
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

    final currencyCode = ch['currency_code'] ?? p['currency_code'] ?? 'ARS';
    final currencySymbol = ch['currency_symbol'] ?? p['currency_symbol'] ?? '\$';

    Widget progressContainer(double value, Color fillColor) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: value,
          color: fillColor,
          backgroundColor: Colors.grey[300],
          minHeight: 6,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    // SAVE_AMOUNT
    if (type == 'SAVE_AMOUNT') {
      final double goal = (p['goal_amount'] ?? p['amount'] ?? 0).toDouble();
      final double saved = (p['total_ahorro'] ?? 0).toDouble();
      final double realProgress = goal > 0 ? (saved / goal).clamp(0.0, 1.0) : 0.0;

      final savedFmt = formatCurrency(saved, currencyCode, symbolOverride: currencySymbol);
      final goalFmt = formatCurrency(goal, currencyCode, symbolOverride: currencySymbol);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          progressContainer(realProgress, state == 'completed' ? Colors.green : cs.primary),
          const SizedBox(height: 8),
          Text(
            'Llevás ahorrado $savedFmt de $goalFmt',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // REDUCE_SPENDING_PERCENT
    if (type == 'REDUCE_SPENDING_PERCENT') {
      final num? maxAllowed = p['max_allowed'] is num
          ? p['max_allowed']
          : (p['max_allowed'] is String ? num.tryParse(p['max_allowed']) : null);
      final num? currentSpent = p['current_spent'] is num
          ? p['current_spent']
          : (p['current_spent'] is String ? num.tryParse(p['current_spent']) : null);

      if (maxAllowed != null && currentSpent != null) {
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

        final remainingFmt = formatCurrency(
          remaining.toDouble(),
          currencyCode,
          symbolOverride: currencySymbol,
        );

        final maxFmt = formatCurrency(
          maxAllowed.toDouble(),
          currencyCode,
          symbolOverride: currencySymbol,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            progressContainer(percent, color),
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? 'Te queda $remainingFmt de $maxFmt'
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

    // % genérico
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
  BuildContext context,
  Map<String, dynamic> ch,
  double progress,
  String state,
) {
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

  // ===============================
  //   FECHAS SEGURAS + NULL CHECK
  // ===============================
  String? startStr = ch['pivot']?['start_date'];
  String? failedAtStr = ch['pivot']?['failed_at'] ?? ch['pivot']?['updated_at'];
  String? completedAtStr =
      ch['pivot']?['completed_at'] ?? ch['pivot']?['updated_at'];
  int? durationDays = ch['duration_days'] is int
      ? ch['duration_days']
      : int.tryParse('${ch['duration_days']}');

  // 🔹 NUEVO: end_date real desde backend (si existe)
  final endStr = ch['pivot']?['end_date'];
  final endDate =
      endStr != null ? DateTime.tryParse(endStr)?.toLocal() : null;

  String? remainingInfo;

  // Si NO hay start_date → no podemos calcular nada
  if (startStr == null) {
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
      ],
    );
  }

  // Convertir fecha de inicio
  final startDate = DateTime.tryParse(startStr)?.toLocal();

  if (startDate == null) {
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
      ],
    );
  }

  // 🔹 Si el backend mandó end_date → LO USAMOS
  // 🔹 Si no, usamos start + durationDays (fallback)
  final safeEndDate = endDate ??
      (durationDays != null
          ? startDate.add(Duration(days: durationDays))
          : null);

  final now = DateTime.now();

  // ===============================
  //       ESTADOS / MENSAJES
  // ===============================

  if (state == 'failed') {
    if (failedAtStr != null) {
      final failedAt = DateTime.tryParse(failedAtStr)?.toLocal();
      if (failedAt != null) {
        remainingInfo =
            '❌ Falló el ${failedAt.day}/${failedAt.month}';
      } else {
        remainingInfo = '❌ Falló antes del fin';
      }
    } else {
      remainingInfo = '❌ Falló antes del fin';
    }
  }

  else if (state == 'completed') {
    if (completedAtStr != null) {
      final completedAt = DateTime.tryParse(completedAtStr)?.toLocal();
      if (completedAt != null) {
        remainingInfo =
            '✅ Completado el ${completedAt.day}/${completedAt.month}';
      }
    } else if (safeEndDate != null) {
      remainingInfo =
          '✅ Completado el ${safeEndDate.day}/${safeEndDate.month}';
    }
  }

  else {
    // En progreso
    if (safeEndDate == null) {
      remainingInfo = null;
    } else {
      final remaining = safeEndDate.difference(now);

      if (remaining.isNegative) {
        remainingInfo =
            '📅 Finalizado el ${safeEndDate.day}/${safeEndDate.month}';
      } else if (remaining.inDays >= 1) {
        remainingInfo =
            '⏳ Faltan ${remaining.inDays} día${remaining.inDays == 1 ? '' : 's'} '
            '(termina el ${safeEndDate.day}/${safeEndDate.month})';
      } else {
        final hours = remaining.inHours;
        remainingInfo =
            '⏰ Faltan $hours hora${hours == 1 ? '' : 's'} '
            '(termina el ${safeEndDate.day}/${safeEndDate.month})';
      }
    }
  }

  // ===============================
  //         RETURN FINAL
  // ===============================

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

    final currencyCode = payload['currency_code'] ?? 'ARS';
    final currencySymbol = payload['currency_symbol'] ?? '\$';

    switch (type) {
      case 'SAVE_AMOUNT':
        final num? amount =
            (target is num) ? target : (payload['amount'] as num?);

        if (amount != null) {
          final amountFmt = formatCurrency(
            amount.toDouble(),
            currencyCode,
            symbolOverride: currencySymbol,
          );
          return 'Ahorrá $amountFmt';
        }
        return 'Ahorrá un monto personalizado';

      case 'REDUCE_SPENDING_PERCENT':
        final int windowDays = (payload['window_days'] as num?)?.toInt() ?? 30;
        final num? maxAllowed = payload['max_allowed'] is num
            ? payload['max_allowed']
            : (payload['max_allowed'] is String
                ? num.tryParse(payload['max_allowed'])
                : null);

        if (maxAllowed != null) {
          final maxFmt = formatCurrency(
            maxAllowed.toDouble(),
            currencyCode,
            symbolOverride: currencySymbol,
          );
          return 'No superes $maxFmt en gastos.\n'
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
