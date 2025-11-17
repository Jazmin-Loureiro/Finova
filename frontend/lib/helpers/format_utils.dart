import 'package:intl/intl.dart';

/// Formatea valores numéricos según la moneda.
/// Usa formato normal hasta 1.000 millones, y compacto por encima.
/// Siempre asegura que el símbolo esté pegado al número, sin espacios invisibles.
String formatCurrency(double? value, String currencyCode, {String? symbolOverride}) {
  if (value == null) return '-';

  try {
    final locale = _getLocaleForCurrency(currencyCode);
    String formatted;

    //  Compacto (≥ 1.000 millones)
    if (value.abs() >= 1e9) {
      final compactFormatter = NumberFormat.compact(locale: locale);
      formatted = compactFormatter.format(value);
      formatted = formatted.replaceAll(RegExp(r'[\u00A0\u202F\s]'), '');
    } 
    // Normal (menos de 1.000 millones)
    else {
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: '', // no dejamos que ponga su símbolo
        decimalDigits: _getDecimalDigitsForCurrency(currencyCode),
      );
      formatted = formatter.format(value);
    }

    //  Limpieza final
    formatted = formatted.replaceAll(RegExp(r'[\u00A0\u202F]'), '').trim();

    //  Retorno uniforme para todos los casos
    return '${symbolOverride ?? ''}$formatted';
  } catch (e) {
    return '${symbolOverride ?? ''}$value ';
  }
}

String _getLocaleForCurrency(String code) {
  final c = code.toUpperCase();
    if (c == 'USD' || c == 'GBP' || c == 'JPY' || c == 'CNY') {
      return 'en_US';
    }
    return 'es_ES'; 
}

/// Ajusta los decimales según la moneda.
int _getDecimalDigitsForCurrency(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'CLP':
      return 0;
    default:
      return 2;
  }
}

/// Convierte un string formateado (según la moneda) en double usable por el backend.

double parseCurrency(String formatted, String currencyCode) {
  if (formatted.isEmpty) return 0;
  final locale = _getLocaleForCurrency(currencyCode);
  // Obtener símbolos locales 
  final symbols = NumberFormat("#,##0.###", locale).symbols;
  final decimalSeparator = symbols.DECIMAL_SEP;   // ',' o '.'
  final thousandSeparator = symbols.GROUP_SEP;    // '.' o ','
  // 1) Remover separador de miles
  String cleaned = formatted.replaceAll(thousandSeparator, "");
  // 2) Reemplazar separador decimal por "."
  cleaned = cleaned.replaceAll(decimalSeparator, ".");
  return double.tryParse(cleaned) ?? 0.0;
}
