import 'currency.dart';
import 'category.dart';
import 'goal.dart';

class Register {
  final int id;
  final String name;
  final String type;
  final double balance;
  final double? reserved_for_goal;
  final DateTime created_at;
  final Currency currency; 
  final Category category; // 
  final int moneyMakerId;
  final Goal? goal;

  Register({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.reserved_for_goal,
    required this.created_at,
    required this.currency,
    required this.category,
    required this.moneyMakerId,
    this.goal,
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    return Register(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance'].toString()) ?? 0.0,
      reserved_for_goal: json['reserved_for_goal'] is num
          ? (json['reserved_for_goal'] as num).toDouble()
          : double.tryParse(json['reserved_for_goal'].toString()) ?? 0.0,
      created_at: DateTime.parse(json['created_at']),
      currency: Currency.fromJson(json['currency']),   // 
      category: Category.fromJson(json['category']),   // 
      moneyMakerId: json['moneyMaker_id'] is int
          ? json['moneyMaker_id']
          : int.tryParse(json['moneyMaker_id'].toString()) ?? 0,
      goal: json['goal'] != null ? Goal.fromJson(json['goal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'created_at': created_at.toIso8601String(),
      'currency': currency.toJson(),
      'category': category.toJson(),
      'moneyMakerId': moneyMakerId,
      'goal': goal?.toJson(),
    };
  }
}
