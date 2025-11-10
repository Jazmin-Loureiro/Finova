import 'package:frontend/models/currency.dart';

class Goal {
  final int id;
  final String name;
  final double targetAmount;
  final double balance;
  final Currency? currency;
  final String state;
  final bool active;
  final bool isChallengeGoal; // 👈 NUEVO
  final DateTime? createdAt;
  final DateTime? dateLimit;
  final DateTime? updatedAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.balance,
    this.currency,
    required this.state,
    required this.active,
    this.isChallengeGoal = false, // 👈 NUEVO
    this.createdAt,
    this.dateLimit,
    this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,

      name: json['name'] ?? '',

      targetAmount: json['target_amount'] is num
          ? (json['target_amount'] as num).toDouble()
          : double.tryParse(json['target_amount'].toString()) ?? 0.0,

      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance'].toString()) ?? 0.0,

      currency: json['currency'] != null
          ? Currency.fromJson(json['currency'])
          : null,

      state: json['state']?.toString() ?? '',

      active: json['active'] is bool
          ? json['active']
          : (json['active'].toString() == '1' ||
              json['active'].toString().toLowerCase() == 'true'),

      isChallengeGoal: json['is_challenge_goal'] == true ||
          json['is_challenge_goal'] == 1 ||
          json['is_challenge_goal']?.toString().toLowerCase() == 'true', // 👈 NUEVO

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      dateLimit: json['date_limit'] != null
          ? DateTime.tryParse('${json['date_limit']}T00:00:00')
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'balance': balance,
        'currency': currency,
        'state': state,
        'active': active,
        'is_challenge_goal': isChallengeGoal, // 👈 NUEVO
        'created_at': createdAt?.toIso8601String(),
        'date_limit': dateLimit?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
