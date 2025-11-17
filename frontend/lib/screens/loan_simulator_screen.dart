import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/widgets/currency_text_field.dart';
import '../services/api_service.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/simulation_result_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class LoanSimulatorScreen extends StatefulWidget {
  const LoanSimulatorScreen({super.key});

  @override
  State<LoanSimulatorScreen> createState() => _LoanSimulatorScreenState();
}

class _LoanSimulatorScreenState extends State<LoanSimulatorScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController capitalController = TextEditingController();

  int cuotas = 12;
  Map<String, dynamic>? resultado;
  bool isLoading = false;

  Future<void> simulateLoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      resultado = null;
    });

    final res = await api.simulateLoan(
      capital:  parseCurrency(capitalController.text, fromCurrency.code),
      cuotas: cuotas,
    );

    setState(() {
      isLoading = false;
      resultado = res;
    });
  }

  int? userCurrencyId;
  bool isLoadingCurrency = true;
  late List<Currency> currencies;
  late Currency fromCurrency;

  @override
  void initState() {
    super.initState();
    _checkCurrency();
  }

  Future<void> _checkCurrency() async {
    currencies = await api.getCurrencies();
    fromCurrency = currencies.firstWhere((c) => c.code == 'ARS');
    final id = await api.getUserCurrency();
    setState(() {
      userCurrencyId = id;
      isLoadingCurrency = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    
    return CustomScaffold(
      title: 'Simulador',
      currentRoute: 'loan_simulation',
      showNavigation: false,
      body:isLoadingCurrency
    ? const Center(child: LoadingWidget())
    : (userCurrencyId != 3)
        ? const EmptyStateWidget(
            icon: Icons.block,
            title: "Función no disponible",
            message:
                "Esta sección solo puede usarse si tu moneda base es el Peso Argentino (ARS). "
                "Podés cambiarla desde tu perfil si querés acceder al simulador de inversiones.",
          )
        :  Container(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Simulá tu préstamo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              //  Tarjeta principal del simulador
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: surface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                       CurrencyTextField(
                          controller: capitalController,
                          currencies: currencies,
                          selectedCurrency: fromCurrency,
                          label: 'Monto a convertir',
                          validator: (value) {
                              if (value == null || value.trim().isEmpty)  return 'Ingresá un monto';
                              final clean = value.replaceAll('.', '').replaceAll(',', '.');
                              final parsed = double.tryParse(clean);
                              if (parsed == null || parsed < 10000) return 'El monto mínimo es \$10.000';
                              return null;
                            },
                          ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: cuotas,
                        decoration: InputDecoration(
                          labelText: 'Cantidad de cuotas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [6, 12, 18, 24, 36, 48, 60]
                            .map((e) => DropdownMenuItem<int>(
                                  value: e,
                                  child: Text('$e cuotas'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => cuotas = val);
                        },
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : simulateLoan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor: primary.withOpacity(0.4),
                            elevation: 8,
                          ),
                          child: const Text('Simular préstamo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              //  Loading o resultado
              if (isLoading)
                const LoadingWidget(message: "Calculando préstamo..."),
              if (!isLoading && resultado != null) ...[
                const SizedBox(height: 20),
                if (resultado!['error'] != null)
                  Text(
                    resultado!['error'],
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                else
                  SimulationResultCard(
                    resultado: resultado!,
                    ultimaActualizacion:
                        resultado!['ultima_actualizacion']?.toString(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
