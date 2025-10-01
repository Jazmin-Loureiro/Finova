class Currency {
  final int id;     // ID en la base de datos
  final String code;   // Código ISO, ej: USD
  final String name;   // Nombre en español, ej: Dólar estadounidense
  final String symbol; // Símbolo, ej: $
  final double? rate;  // Tasa de cambio respecto a una moneda base (opcional)

  Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.rate,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'] ?? json['code'], 
      rate: json['rate'] != null
          ? (json['rate'] is num
              ? (json['rate'] as num).toDouble()
              : double.tryParse(json['rate'].toString()) ?? 0.0)
          : null,
    );
  }
   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'rate': rate,
    };
}
}
