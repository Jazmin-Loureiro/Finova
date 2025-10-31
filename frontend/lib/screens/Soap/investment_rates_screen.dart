import 'package:flutter/material.dart';
import '../../models/investment_rate.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';

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
                final formattedDate = DateFormat('dd/MM/yyyy – HH:mm')
                  .format(DateTime.parse(rate.updatedAt));
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      rate.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Tipo: ${rate.type} | Fuente: ${rate.fuente}',
                          style:  TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Última actualización: ${formattedDate}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${rate.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  )

                );
              },
            ),
    );
  }
}
