import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/info_icon_widget.dart';
import 'package:frontend/widgets/loading_widget.dart';
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
  final _formKey = GlobalKey<FormState>(); 
  final ApiService api = ApiService();
  List<Currency> currencies = [];
  Currency? fromCurrency;
  Currency? toCurrency;
  final TextEditingController amountController = TextEditingController();
  double? convertedValue;
  late DateTime lastUpdated;
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
        lastUpdated = toCurrency!.updatedAt!.toLocal();
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
      amountController.clear(); // hay q limpiar el monto también si no se rompe por la separación de miles

      // 🔹 Opción 2 (activar si querés recalcular automáticamente):
      // convertLocal();
    });
  }

  void convertLocal() {
    if (fromCurrency == null || toCurrency == null) return;
    final amount = parseCurrency(amountController.text, fromCurrency!.code);
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
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return CustomScaffold(
      title: 'Conversor',
      currentRoute: 'currency_converter',
      showNavigation: false,
      body: isLoading
          ? const Center(child: LoadingWidget())
          : Form (
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity( 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.30),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Conversor de monedas',
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InfoIcon(
                                    title: 'Conversión de moneda',
                                    message:
                                        'Fuente: Open Exchange Rates\n'
                                        'Última actualización: ${DateFormat('dd/MM/yyyy').format(toCurrency!.updatedAt!)}\n\n'
                                        'Este valor es estimativo y puede variar según el mercado.',
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              CurrencyTextField(
                                controller: amountController,
                                currencies: currencies,
                                selectedCurrency: fromCurrency,
                                label: 'Monto a convertir',
                                onChanged: (val) {
                                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                                  _debounce = Timer(const Duration(milliseconds: 600), () {});
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingrese un monto';
                                  }
                                  // Elimina separadores de miles y arregla decimales
                                    String clean = val;
                                      clean = clean.replaceAll(RegExp(r'(?<=\d)[.,](?=\d{3}\b)'), '');
                                      if (clean.contains(',')) {
                                        clean = clean.replaceAll(',', '.');
                                      }   
                                      final parsed = double.tryParse(clean);
                                      if (parsed == null || parsed <= 0) {
                                      return 'Ingrese un monto válido';
                                    }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              Row(
                                children: [
                                  Expanded(child: _buildDropdown(true, theme)),
                                  const SizedBox(width: 1),
                                  IconButton(
                                    icon: Icon(Icons.swap_horiz, color: primary, size: 32),
                                    onPressed: swapCurrencies,
                                  ),
                                  const SizedBox(width: 1),
                                  Expanded(child: _buildDropdown(false, theme)),
                                ],
                              ),

                              const SizedBox(height: 26),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      convertLocal();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                    elevation: 8,
                                  ),
                                  child: const Text('Convertir'),
                                ),
                              ),
                            ],
                          ),
                        ),


                        const SizedBox(height: 15),

                        //  Resultado animado + texto de tasa
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
                                            Border.all(color: primary.withOpacity(0.30), width: 1.5),
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
                                            '${toCurrency?.symbol ?? ''}' +
                                            formatCurrency(
                                              convertedValue!,
                                              toCurrency!.code,
                                            ),
                                            style: TextStyle(
                                              fontSize: 34,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${fromCurrency?.symbol ?? ''}1 ${fromCurrency?.code ?? ''} = '
                                            '${toCurrency?.symbol ?? ''}' '${NumberFormat("#,##0.####").format(toCurrency!.rate! / fromCurrency!.rate!)} '
                                            '${toCurrency?.code ?? ''}',
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.8),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '(Tasa actualizada ${_formatElapsedTime(lastUpdated)})',
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
                      ],
                    ),
                  ),
            )
        );
      }

        Widget _buildDropdown(bool isFrom, ThemeData theme) {
          return Container(
            child: BottomSheetPickerField<Currency>(
        key: ValueKey(isFrom ? fromCurrency?.id : toCurrency?.id),
        label: 'Divisa',
        items: currencies,
        itemLabel: (c) => '${c.code}',
        itemIcon: (c) => CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            c.symbol,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        initialValue: isFrom ? fromCurrency : toCurrency,
        onChanged: (value) => setState(() {
          if (isFrom) {
            fromCurrency = value;
          } else {
            toCurrency = value;
          }
          convertedValue = null;
        }),
        validator: (value) => value == null ? 'Debes seleccionar una moneda' : null,
      )
    );
  }
}
