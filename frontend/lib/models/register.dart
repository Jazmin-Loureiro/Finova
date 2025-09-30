class Register {
  final int id;
  final String name;
  final String type; // "income" o "expense"
  final double amount;
  final DateTime date;
  final int currencyId;

  Register({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.date,
    required this.currencyId,
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    return Register(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      amount: (json['balance'] as num).toDouble(), // asumimos que en la API se llama "balance"
      date: DateTime.parse(json['created_at']),   // parsea fecha de la API
      currencyId: json['currency_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'currency_id': currencyId,
    };
  }
}
