import 'package:flutter/material.dart';
import 'package:frontend/screens/Soap/investment_rates_screen.dart';
import 'package:frontend/screens/converter/currency_list.dart';
import 'package:frontend/widgets/custom_scaffold.dart';

class RatesTabScreen extends StatelessWidget {
  const RatesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: CustomScaffold(
        title: 'Mercado Financiero',
        currentRoute: '/rates_tab',
        showNavigation: false,
        body: Column(
          children: [
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(icon: Icon(Icons.trending_up), text: "Inversiones"),
                  Tab(icon: Icon(Icons.attach_money), text: "Monedas"),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  InvestmentRatesScreen(),
                  CurrencyList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
