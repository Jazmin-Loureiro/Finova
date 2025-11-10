import 'package:intl/intl.dart';

/// Formatea valores numéricos según el código de moneda del usuario.
/// `formatCurrency(12345.6, 'USD')` -> "12,345.60 USD"
/// `formatCurrency(12345.6, 'ARS')` -> "12.345,60 ARS"
String formatCurrency(double? value, String currencyCode, {String? symbolOverride}) {
  if (value == null) return '-';

  try {
    // Detectar locale según moneda
    final locale = _getLocaleForCurrency(currencyCode);

    // Crear formateador con símbolo o sin él
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbolOverride ?? '',
      name: currencyCode,
      decimalDigits: _getDecimalDigitsForCurrency(currencyCode),
    );

    return formatter.format(value);
  } catch (e) {
    return '$value $currencyCode';
  }
}

/// Devuelve un locale apropiado según la moneda.
String _getLocaleForCurrency(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'USD':
      return 'en_US';
    case 'EUR':
      return 'es_ES';
    case 'GBP':
      return 'en_GB';
    case 'JPY':
      return 'ja_JP';
    case 'BRL':
      return 'pt_BR';
    case 'ARS':
      return 'es_AR';
    case 'MXN':
      return 'es_MX';
    default:
      return 'en_US'; // fallback
  }
}

/// Ajusta cuántos decimales mostrar según la moneda.
int _getDecimalDigitsForCurrency(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY': // yenes no usan decimales
    case 'CLP':
      return 0;
    default:
      return 2;
  }
}
