import 'dart:convert';

class ChallengeUtils {
  static Map<String, dynamic> decodePayload(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return {};
  }

  static String symbolOf(Map<String, dynamic> ch) {
    final pivotPayload = decodePayload(ch['pivot']?['payload']);
    final mainPayload = decodePayload(ch['payload']);
    return ch['currency_symbol'] ??
        pivotPayload['currency_symbol'] ??
        mainPayload['currency_symbol'] ??
        '\$';
  }

  static int extractDuration(Map<String, dynamic> ch) {
    final payload = decodePayload(ch['pivot']?['payload'] ?? ch['payload']);
    final type = (ch['type'] ?? '') as String;

    switch (type) {
      case 'SAVE_AMOUNT':
        return (payload['duration_days'] as num?)?.toInt() ??
            (ch['duration_days'] as num?)?.toInt() ??
            0;
      case 'REDUCE_SPENDING_PERCENT':
        return (payload['window_days'] as num?)?.toInt() ??
            (ch['duration_days'] as num?)?.toInt() ??
            0;
      case 'ADD_TRANSACTIONS':
        return (payload['duration_days'] as num?)?.toInt() ??
            (ch['duration_days'] as num?)?.toInt() ??
            0;
      default:
        return (ch['duration_days'] as num?)?.toInt() ?? 0;
    }
  }
}
