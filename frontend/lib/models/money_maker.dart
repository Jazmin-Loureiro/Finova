import 'currency.dart';
class MoneyMaker {
  final int id;      
  final String name;
  final String type;
  final double balance;
  final double balanceConverted; // saldo convertido a moneda base
  final String color; 
  final Currency? currency;
  final String? currencyBase; // moneda base del usuario
  String? currencySymbol; // símbolo de la moneda

  MoneyMaker({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.balanceConverted, // saldo convertido a moneda base
    required this.color,
    this.currency ,
    this.currencyBase, // moneda base del usuario
    this.currencySymbol, // símbolo de la moneda
  });

  factory MoneyMaker.fromJson(Map<String, dynamic> json) {
    return MoneyMaker(
      id: json['id'],  
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      balanceConverted: double.tryParse(json['balanceConverted'].toString()) ?? 0.0,
      color: json['color'] ?? 'FFFFFF',
    currencyBase: json['currencyBase']?.toString(), // 🔹 convertir a String
    currencySymbol: json['currencySymbol']?.toString(), // 🔹 convertir a String
      
    );
  }
}
