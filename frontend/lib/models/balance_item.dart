import 'package:frontend/models/currency.dart';

class BalanceItem {
  final double amount;
  final Currency currency;
  final String name;

  BalanceItem({
    required this.amount,
    required this.currency,
    required this.name,
  });

  factory BalanceItem.fromJson(Map<String, dynamic> json, String key) {
    return BalanceItem(
      name: key,
      amount: (json['amount'] as num).toDouble(),
      currency: Currency.fromJson(json['currency']),
    );
  }
}
