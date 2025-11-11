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

/// Devuelve el locale apropiado según la moneda.
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
      return 'en_US';
  }
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
