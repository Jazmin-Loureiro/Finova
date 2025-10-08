import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/currency.dart';
import '../services/api_service.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/currency_text_field.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final ApiService api = ApiService();
  List<Currency> currencies = [];
  Currency? fromCurrency;
  Currency? toCurrency;
  final TextEditingController amountController = TextEditingController();
  double? convertedValue;
  bool isLoading = true;

  // Simulación de fecha de actualización (si tu API no la devuelve aún)
  final DateTime mockLastUpdated = DateTime.now().subtract(const Duration(hours: 5));

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadCurrencies();
  }

  Future<void> loadCurrencies() async {
    try {
      currencies = await api.getCurrencies();
      setState(() {
        fromCurrency = currencies.firstWhere((c) => c.code == 'ARS', orElse: () => currencies.first);
        toCurrency = currencies.firstWhere((c) => c.code == 'USD', orElse: () => currencies.last);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar monedas: $e')),
      );
    }
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;

      // 🔹 Opción 1: limpiar resultado (recomendado)
      convertedValue = null;

      // 🔹 Opción 2 (activar si querés recalcular automáticamente):
      // convertLocal();
    });
  }

  void convertLocal() {
    if (fromCurrency == null || toCurrency == null) return;
    final amount = double.tryParse(amountController.text.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
    if (amount <= 0) return;

    final result = amount * (toCurrency!.rate! / fromCurrency!.rate!);
    setState(() => convertedValue = result);
  }

  String _formatElapsedTime(DateTime lastUpdated) {
    final difference = DateTime.now().difference(lastUpdated);
    if (difference.inMinutes < 1) return 'hace unos segundos';
    if (difference.inMinutes < 60) return 'hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'hace ${difference.inHours} h';
    return 'hace ${difference.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final background = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return CustomScaffold(
      title: 'Conversor',
      currentRoute: 'currency_converter',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              background.withOpacity(0.97),
              background.withOpacity(0.85),
              primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Converzor de monedas',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 💳 Tarjeta translúcida
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CurrencyTextField(
                            controller: amountController,
                            currencies: currencies,
                            selectedCurrency: fromCurrency,
                            label: 'Monto a convertir',
                            onChanged: (val) {
                              // 🔹 Ejemplo de debounce si más adelante querés recalcular automáticamente
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(const Duration(milliseconds: 600), () {
                                // convertLocal(); // <— activar si querés recalcular al escribir
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildDropdown(true, theme)),
                              IconButton(
                                icon: Icon(Icons.swap_horiz, color: primary, size: 32),
                                onPressed: swapCurrencies,
                              ),
                              Expanded(child: _buildDropdown(false, theme)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🟩 Botón principal Finova
                    ElevatedButton(
                      onPressed: convertLocal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      child: const Text('Convertir'),
                    ),

                    const SizedBox(height: 35),

                    // 💰 Resultado animado + texto de tasa
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: convertedValue == null
                          ? const SizedBox.shrink()
                          : Column(
                              key: ValueKey(convertedValue),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: surface.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: primary.withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Resultado',
                                        style: TextStyle(
                                            color: textColor.withOpacity(0.7), fontSize: 15),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        NumberFormat.currency(symbol: toCurrency?.symbol ?? '')
                                            .format(convertedValue),
                                        style: TextStyle(
                                          fontSize: 34,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 💬 Texto informativo de tasa
                                Text(
                                  '1 ${fromCurrency?.code ?? ''} = '
                                  '${NumberFormat("#,##0.####").format(toCurrency!.rate! / fromCurrency!.rate!)} '
                                  '${toCurrency?.code ?? ''}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(Tasa actualizada ${_formatElapsedTime(mockLastUpdated)})',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // 🔽 Dropdown con solo iniciales y limpieza de resultado
  Widget _buildDropdown(bool isFrom, ThemeData theme) {
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: surface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          value: isFrom ? fromCurrency : toCurrency,
          dropdownColor: surface.withOpacity(0.95),
          icon: Icon(Icons.arrow_drop_down, color: primary),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
          menuMaxHeight: 300,
          isExpanded: true,
          items: currencies
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.code}', // 👈 solo iniciales
                    style: TextStyle(color: textColor, fontSize: 15),
                  ),
                ),
              )
              .toList(),
          onChanged: (c) => setState(() {
            if (isFrom) {
              fromCurrency = c;
            } else {
              toCurrency = c;
            }

            // 🔹 Opción 1: limpiar resultado para evitar confusión
            convertedValue = null;

            // 🔹 Opción 2: recalcular automáticamente
            // convertLocal();
          }),
        ),
      ),
    );
  }
}
