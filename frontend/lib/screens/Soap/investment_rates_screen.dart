import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/widgets/loading_widget.dart';
import '../../models/investment_rate.dart';
import '../../services/api_service.dart';
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

  // 🔹 Nombres amigables
  final Map<String, String> prettyNames = {
    'tasa_prestamos_personales': 'Tasa de Préstamos Personales',
    'tasa_plazo_fijo': 'Tasa de Plazo Fijo',
    'tasa_uva': 'Tasa UVA',
    'inflacion_mensual': 'Inflación Mensual',
    'inflacion_interanual': 'Inflación Interanual',
    'comparativa_pf_inflacion': 'Comparativa PF vs Inflación',
    'market_cripto_bitcoin': 'Bitcoin (BTC)',
    'market_cripto_ethereum': 'Ethereum (ETH)',
    'market_cripto_solana': 'Solana (SOL)',
    'market_cripto_dogecoin': 'Dogecoin (DOGE)',
    'market_cripto_cardano': 'Cardano (ADA)',
    'market_accion_aapl': 'Apple (AAPL)',
    'market_accion_msft': 'Microsoft (MSFT)',
    'market_accion_tsla': 'Tesla (TSLA)',
    'market_accion_googl': 'Google (GOOGL)',
    'market_bono_tlt': 'Bono TLT',
    'market_bono_bnd': 'Bono BND',
    'market_bono_lqd': 'Bono LQD',
    'market_bono_ief': 'Bono IEF',
    'reservas_internacionales': 'Reservas Internacionales',
    'merval': 'Índice Merval',
  };

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    try {
      final fetchedRates = await api.getInvestmentRates();
      fetchedRates.removeWhere((r) => r.name.toLowerCase().contains('ppa'),);
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

  IconData _getIcon(String name, String type) {
    if (name.contains('reservas')) return Icons.savings_outlined;
    if (name.contains('merval')) return Icons.trending_up_outlined;
    if (name.contains('inflacion_mensual')) return Icons.trending_flat_outlined;
    if (name.contains('inflacion_interanual')) return Icons.show_chart_outlined;
    if (name.contains('comparativa_pf_inflacion')) return Icons.compare_arrows_outlined;
    if (name.contains('tasa_prestamos_personales')) return Icons.account_balance_wallet_outlined;

    switch (type.toLowerCase()) {
      case 'cripto':
        return Icons.currency_bitcoin_outlined;
      case 'accion':
        return Icons.show_chart_outlined;
      case 'bono':
        return Icons.account_balance_outlined;
      case 'tasa':
        return Icons.percent_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColor(String name, String type) {
    if (name.contains('reservas')) return Colors.teal;
    if (name.contains('merval')) return Colors.indigo;
    if (name.contains('inflacion')) return Colors.redAccent;
    if (name.contains('comparativa')) return Colors.amber[800]!;
    if (name.contains('prestamos')) return Colors.deepOrangeAccent;

    switch (type.toLowerCase()) {
      case 'cripto':
        return Colors.orangeAccent;
      case 'accion':
        return Colors.blueAccent;
      case 'bono':
        return Colors.green;
      case 'tasa':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  /// 🔹 Determina el formato del valor según el nombre
  String _formatValue(InvestmentRate rate) {
    final value = rate.balance;
    final name = rate.name;
    final type = rate.type;

    // Porcentajes
    if (name.contains('tasa_') ||
        name.contains('inflacion') ||
        name.contains('comparativa_pf_inflacion') ||
        name.contains('merval')) {
      return '${value.toStringAsFixed(2)}%';
    }

    // En dólares
    if (type == 'bono' || type == 'accion' || type == 'cripto' || name.contains('reservas')) {
      return '\$${formatCurrency(value, 'USD')} USD';
    }

    // Por defecto: pesos
    return '\$${value.toStringAsFixed(2)} ARS';
  }

  @override
  Widget build(BuildContext context) {
    return  isLoading
          ? const Center(child: LoadingWidget())
          : ListView.builder(
              itemCount: rates.length,
              itemBuilder: (context, i) {
                final rate = rates[i];
                final name = prettyNames[rate.name] ?? rate.name;
                final color = _getColor(rate.name, rate.type);
                final icon = _getIcon(rate.name, rate.type);
                final formattedValue = _formatValue(rate);

                // 🔹 Formatea la fecha de actualización
                String formattedDate = '';
                try {
                  formattedDate =DateFormat("dd MMM yyyy - HH:mm")
                      .format(DateTime.parse(rate.updatedAt).toLocal());
                } catch (_) {
                  formattedDate = 'Fecha no disponible';
                }

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
                        // ICONO A LA IZQUIERDA
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          radius: 22,
                          child: Icon(icon, color: color, size: 20),
                        ),

                        const SizedBox(width: 12),

                        // INFORMACIÓN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NOMBRE
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // TIPO + FUENTE
                              Text(
                                'Tipo: ${rate.type}  •  Fuente: ${rate.fuente}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Theme.of(context).colorScheme.primary,        
                                ),
                              ),

                              const SizedBox(height: 4),

                               Text(
                                formattedValue,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              
                              const SizedBox(height: 6),
                              // FECHA
                              Text(
                                'Última actualización: $formattedDate',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
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
