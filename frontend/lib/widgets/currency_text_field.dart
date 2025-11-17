import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/currency.dart';

class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final Currency? selectedCurrency;
  final List<Currency> currencies;
  final String label;
  final void Function(String)? onChanged;
  final FormFieldValidator<String>? validator;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.currencies,
    this.selectedCurrency,
    required this.label,
    this.onChanged,
    this.validator,
  });

String _getLocaleForCurrency(String code) {
  final upper = code.toUpperCase();
  if (upper == 'USD' || upper == 'GBP' || upper == 'CNY' || upper == 'JPY' || upper == 'AUD' || upper == 'NZD') {
    return 'en_US'; // miles , decimales .
  }
  return 'es_ES';
}



  /// Formatter que respeta miles + decimales escritos por el usuario
  TextInputFormatter _currencyFormatter(Currency currency) {
    final locale = _getLocaleForCurrency(currency.code);
    final symbols = NumberFormat("#,##0.###", locale).symbols;

    final decimalSep = symbols.DECIMAL_SEP;
    final thousandSep = symbols.GROUP_SEP;

    return TextInputFormatter.withFunction((oldValue, newValue) {
      String text = newValue.text;
      if (text.isEmpty) {
        return const TextEditingValue(text: '');
      }

      if (text.startsWith(decimalSep)) {
        text = "0$decimalSep${text.substring(1)}";
      }
      List<String> parts = text.split(decimalSep);
      String integerPart = parts[0].replaceAll(thousandSep, '');
      String decimalPart = parts.length > 1 ? parts[1] : '';

      if (integerPart.isEmpty) integerPart = '0';

      // Re-formatear parte entera con miles
      final formatter = NumberFormat("#,##0", locale);
      String formattedInt = formatter.format(int.parse(integerPart));
      String result = formattedInt;
      if (parts.length > 1) {
        result += decimalSep + decimalPart;
      }
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Currency currency = selectedCurrency ?? currencies.first;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: 10,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        prefixText: selectedCurrency != null ? '${selectedCurrency!.symbol} ' : '',
        counterText: '',
      ),
      // FORMATEO QUE FUNCIONA PARA CUALQUIER MONEDA
      inputFormatters: [
        _currencyFormatter(currency),
      ],
      validator: validator,
      onChanged: onChanged,
    );
  }
}
