class MoneyMaker {
  final int id;      
  final String name;
  final String type;
  final String typeMoney;
  final double balance;
  final double balanceConverted; // saldo convertido a moneda base
  final String color; 
  final String? currencyBase; // moneda base del usuario
  String? currencySymbol; // símbolo de la moneda

  MoneyMaker({
    required this.id,
    required this.name,
    required this.type,
    required this.typeMoney,
    required this.balance,
    required this.balanceConverted, // saldo convertido a moneda base
    required this.color,
    this.currencyBase, // moneda base del usuario
    this.currencySymbol, // símbolo de la moneda
  });

  factory MoneyMaker.fromJson(Map<String, dynamic> json) {
    return MoneyMaker(
      id: json['id'],  
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      typeMoney: json['typeMoney'] ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      balanceConverted: double.tryParse(json['balanceConverted'].toString()) ?? 0.0,
      color: json['color'] ?? 'FFFFFF',
      currencyBase: json['currencyBase'],
      currencySymbol: json['currencySymbol'],
    );
  }
}
