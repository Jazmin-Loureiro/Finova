import 'currency.dart';
import 'category.dart';
import 'goal.dart';
import 'money_maker.dart';

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
  final MoneyMaker? moneyMaker; //
  final Goal? goal;
  final String? file;

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
    this.moneyMaker,
    this.file,
    this.goal,
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    final data = json['register'] ?? json;
    return Register(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      balance: double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0,
      reserved_for_goal: data['reserved_for_goal'] != null
          ? double.tryParse(data['reserved_for_goal'].toString())
          : null,
      created_at: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      file: data['file'],
      category: 
           Category.fromJson(data['category']),
      currency: Currency.fromJson(data['currency']),
      moneyMakerId: data['money_maker_id'] is int
          ? data['money_maker_id']
          : int.tryParse(data['money_maker_id']?.toString() ?? '0') ?? 0,
      moneyMaker: data['money_maker'] != null
          ? MoneyMaker.fromJson(data['money_maker'])
          : null,
      goal: data['goal'] != null ? Goal.fromJson(data['goal']) : null,
    );
  
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'reserved_for_goal': reserved_for_goal,
      'created_at': created_at.toIso8601String(),
      'currency': currency.toJson(),
      'category': category.toJson(),
      'moneyMakerId': moneyMakerId,
      'moneyMaker': moneyMaker?.toJson(),
      'goal': goal?.toJson(),
      'file': file,
    };
  }
}
