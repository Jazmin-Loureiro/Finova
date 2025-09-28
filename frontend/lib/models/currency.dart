class Currency {
  final String code;   // Código ISO, ej: USD
  final String name;   // Nombre en español, ej: Dólar estadounidense
  final String symbol; // Símbolo, ej: $

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'] ?? json['code'], 
    );
  }
}
