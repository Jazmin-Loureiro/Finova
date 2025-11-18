import 'currency.dart';
import 'register.dart';
import 'money_maker_type.dart';

class MoneyMaker {
  final int id;      
  final String name;
  final MoneyMakerType? type;
  final double balance;
  final double balanceConverted; // saldo convertido a moneda base
  final double balance_reserved; // saldo reservado
  final String color; 
  final Currency? currency;
 // final String? currencyBase; // moneda base del usuario
  String? currencySymbol; // símbolo de la moneda
   List<Register> registers ; // Lista de registros asociados
   final bool active; // Indica si la fuente de dinero está activa

  MoneyMaker({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.balanceConverted, // saldo convertido a moneda base
    required this.balance_reserved,
    required this.color,
    this.currency ,
   // this.currencyBase, // moneda base del usuario
    this.currencySymbol, // símbolo de la moneda
    this.registers = const [], // Inicializar con lista vacía
    this.active = true, // Por defecto está activa
  });

  factory MoneyMaker.fromJson(Map<String, dynamic> json) {
    return MoneyMaker(
      id: json['id'],  
      name: json['name'] ?? '',
      type:  json['type'] != null ? MoneyMakerType.fromJson(json['type']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      balanceConverted: double.tryParse(json['balanceConverted'].toString()) ?? 0.0,
      balance_reserved: double.tryParse(json['balance_reserved'].toString()) ?? 0.0,
      color: json['color'] ?? 'FFFFFF',
    //currencyBase: json['currencyBase']?.toString(), // 🔹 convertir a String
    currencySymbol: json['currencySymbol']?.toString(), // 🔹 convertir a String
    registers: json['registers'] != null
        ? (json['registers'] as List)
            .map((r) => Register.fromJson(r))
            .toList()
        : [],
      active: json['active'] is bool
    ? json['active']
    : json['active'] == 1 || json['active'] == "1",

    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyMaker &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'balanceConverted': balanceConverted,
      'balance_reserved': balance_reserved,
      'color': color,
      'currency': currency?.toJson(),
     // 'currencyBase': currencyBase,
      'currencySymbol': currencySymbol,
      'registers': registers.map((r) => r.toJson()).toList(),
      'active': active,
    };
  }

}
