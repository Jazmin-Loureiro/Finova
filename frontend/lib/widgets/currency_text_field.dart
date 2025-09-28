import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/currency.dart';

class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedCurrency;
  final List<Currency> currencies;
  final String label;
  final void Function(String)? onChanged;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.currencies,
    this.selectedCurrency,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: currencies.isNotEmpty && selectedCurrency != null
    ? '${currencies.firstWhere((c) => c.code == selectedCurrency, orElse: () => currencies.first).symbol} '
    : '',

      ),
      onTap: () {
        if (controller.text.trim() == '0') controller.clear();
      },
      onEditingComplete: () {
        if (controller.text.isNotEmpty) {
          double value = double.tryParse(
                controller.text.replaceAll(RegExp('[^0-9.]'), ''),
              ) ??
              0;
          String formatted = NumberFormat.currency(
            symbol: selectedCurrency != null
                ? currencies.firstWhere((c) => c.code == selectedCurrency).symbol
                : '',
            decimalDigits: 2,
          ).format(value);
          controller.text = formatted;
        }
        FocusScope.of(context).unfocus();
      },
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final parsed = double.tryParse(val.replaceAll(RegExp('[^0-9.]'), ''));
        if (parsed == null || parsed < 0) {
          return 'Ingresa un número válido';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

// Clase de ejemplo para monedas
class CurrencyWidget {
  final String code;
  final String symbol;

  CurrencyWidget({required this.code, required this.symbol});
}
