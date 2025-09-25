class MoneyMaker {
  final int id;       // int, no String
  final String name;
  final String type;
  final String typeMoney;
  final double balance;
  final String color;

  MoneyMaker({
    required this.id,
    required this.name,
    required this.type,
    required this.typeMoney,
    required this.balance,
    required this.color,
  });

  factory MoneyMaker.fromJson(Map<String, dynamic> json) {
    return MoneyMaker(
      id: json['id'],  
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      typeMoney: json['typeMoney'] ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      color: json['color'] ?? 'FFFFFF',
    );
  }
}
