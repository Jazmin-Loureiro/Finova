import 'package:flutter/material.dart';
import '../../models/investment_rate.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_scaffold.dart';

class InvestmentRatesScreen extends StatefulWidget {
  const InvestmentRatesScreen({super.key});

  @override
  State<InvestmentRatesScreen> createState() => _InvestmentRatesScreenState();
}

class _InvestmentRatesScreenState extends State<InvestmentRatesScreen> {
  final ApiService api = ApiService();
  List<InvestmentRate> rates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    try {
      final fetchedRates = await api.getInvestmentRates();
      setState(() {
        rates = fetchedRates;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tasas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Tasas de Inversión',
      currentRoute: '/investment-rates',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: rates.length,
              itemBuilder: (context, i) {
                final rate = rates[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                   
                    title: Text(rate.name),
                    subtitle: Text('Tipo: ${rate.type}, Fuente: ${rate.fuente}'),
                    trailing: Text('Balance: \$${rate.balance.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
    );
  }
}
