import 'currency.dart';
class Register {
  final int id;
  final String name;
  final String type;
  final double balance;
  final DateTime created_at;
  final Currency currency; 

  Register({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.created_at,
    required this.currency,
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    return Register(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance'].toString()) ?? 0.0,
      created_at: DateTime.parse(json['created_at']),
      currency: json['currency'] = Currency.fromJson(json['currency']), // 👈 parsea el objeto Currency
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
    };
  }
}
