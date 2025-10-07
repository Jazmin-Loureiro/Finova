import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';

class CurrencyConverterScreen extends StatelessWidget {
  const CurrencyConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      title: 'Conversor',
      currentRoute: 'currency_converter',
      body: Center(
        child: Text(
          'Pantalla de Conversor de Divisas',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
