class InvestmentRate {
  final int id;
  final String name;
  final String type;
  final String fuente;
  final double balance;

  InvestmentRate({
    required this.id,
    required this.name,
    required this.type,
    required this.fuente,
    required this.balance,
  });

  factory InvestmentRate.fromJson(Map<String, dynamic> json) {
    return InvestmentRate(
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'].toString(),
      fuente: json['fuente'].toString(),
      type: json['type'].toString(),
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }
}

