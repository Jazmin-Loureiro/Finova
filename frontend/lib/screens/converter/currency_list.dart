import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class CurrencyList extends StatefulWidget {
  const CurrencyList({super.key});

  @override
  State<CurrencyList> createState() => _CurrencyListState();
}

class _CurrencyListState extends State<CurrencyList> {
  final ApiService api = ApiService();
  List<Currency> currencies = [];
  late Currency currencyUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  
Future<void> fetchRates() async {
  try {
    final fetchedCurrencies = await api.getCurrencies();
    final userBaseId = await api.getUserCurrency(); // este es un int
    Currency? baseCurrency = fetchedCurrencies.firstWhere(
      (c) => c.id == userBaseId,
      orElse: () => fetchedCurrencies.first,
    );
    fetchedCurrencies.removeWhere((c) => c.id == baseCurrency.id);
    setState(() {
      currencyUser = baseCurrency;   // Currency del usuario
      currencies = fetchedCurrencies;
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
    return  isLoading
          ? const Center(child: LoadingWidget())
          : ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];

                // Mapa de banderas
                final Map<String, String> flags = {
                  "USD": "🇺🇸",
                  "EUR": "🇪🇺",
                  "ARS": "🇦🇷",
                  "BRL": "🇧🇷",
                  "CLP": "🇨🇱",
                  "COP": "🇨🇴",
                  "MXN": "🇲🇽",
                  "GBP": "🇬🇧",
                  "JPY": "🇯🇵",
                  "CNY": "🇨🇳",
                };

                final fromRate = currency.rate ?? 1;       // moneda que estás mostrando
                final toRate = currencyUser.rate ?? 1;     // moneda base del usuario
                final finalValue = toRate / fromRate;     
                final formattedValue = formatCurrency(finalValue, currency.code);

                // Obtener bandera (o ícono default)
                final flag = flags[currency.code] ?? "🏳️";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      children: [
                        /// FLAG
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          child: Text(flag, style: const TextStyle(fontSize: 20)),
                        ),

                        const SizedBox(width: 12),

                        /// COLUMNA IZQUIERDA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "1 ${currency.code} → ${currencyUser.symbol}${formattedValue}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),

                              const SizedBox(height: 4),

                              /// Fecha de actualización
                              Text(
                               'Última actualización: ' + (currency.updatedAt != null
                                    ? DateFormat("dd MMM yyyy - HH:mm").format(currency.updatedAt!)
                                    : "Sin fecha"),
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        }
