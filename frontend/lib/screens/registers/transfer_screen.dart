import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/models/money_maker.dart';
import 'package:frontend/screens/registers/register_list_screen.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:frontend/widgets/currency_text_field.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/dialogs/success_dialog_widget.dart';
import 'package:frontend/widgets/info_icon_widget.dart';
import 'package:frontend/widgets/loading_widget.dart';

import '../../services/api_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>(); 
  final ApiService api = ApiService();

  MoneyMaker? fromMoneyMaker;
  MoneyMaker? toMoneyMaker;

  final TextEditingController amountController = TextEditingController();

  bool isLoading = true;
  List<MoneyMaker> _moneyMakers = [];
  List<MoneyMaker> get moneyMakers => _moneyMakers;
  List<Currency> currencies = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await loadCurrencies();
    await loadMoneyMaker();
    if (_moneyMakers.isNotEmpty) {
      fromMoneyMaker = _moneyMakers.first;
    }
    setState(() => isLoading = false);
  }


  Future<bool> transferir() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
      final amount =parseCurrency(amountController.text, fromMoneyMaker!.currency!.code);
      final res = await api.createTransfer(amount,fromMoneyMaker!.id,toMoneyMaker!.id);
    setState(() => isLoading = false);
    if (res != null) {
      await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: "Éxito",
          message: "Transferencia creada correctamente",
        ),
      );
       Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterListScreen(
          moneyMakerId: fromMoneyMaker!.id,
          moneyMakerName: fromMoneyMaker!.name,
        ),
      ),
    );

    }
    return true;
  }

  Future<void> loadCurrencies() async {
    try {
      currencies = await api.getCurrencies();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar monedas: $e')),
      );
    }
  }

  Future<void> loadMoneyMaker() async {
    try {
      final response = await api.getMoneyMakersFull();
      _moneyMakers = List<MoneyMaker>.from(response['moneyMakers']);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar fuentes de dinero: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScaffold(
      title: 'Transferir dinero',
      currentRoute: 'transfer',
      showNavigation: false,
      actions: [
        InfoIcon(
          title: 'Transferencias',
          message:
              'Las transferencias te permiten mover dinero entre diferentes fuentes de dinero dentro de tu cuenta.\n\n'
              'Solo puedes transferir dinero entre fuentes que utilizan la misma moneda.',
        ),
      ],
      body: isLoading
          ? const Center(child: LoadingWidget())
          : Form (
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                       Column(
                          children: [
                           Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.40), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ------- MONTO -------
                                  CurrencyTextField(
                                    controller: amountController,
                                    currencies: currencies,
                                    selectedCurrency: fromMoneyMaker?.currency,
                                    label: 'Monto a transferir',
                                    onChanged: (val) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingrese un monto';
                                      }
                              
                                      String clean = val;
                                      clean = clean.replaceAll(RegExp(r'(?<=\d)[.,](?=\d{3}\b)'), '');
                                      clean = clean.replaceAll(',', '.');

                                      final parsed = double.tryParse(clean);
                                      if(parsed! > fromMoneyMaker!.balance) {
                                        return 'El gasto supera el monto disponible (${fromMoneyMaker!.currency!.symbol}${formatCurrency(fromMoneyMaker!.balance, fromMoneyMaker!.currency!.code)})';
                                      }
                                      if (parsed <= 0) return 'Monto inválido';
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),
                                  // ------- DESDE -------
                                  _buildDropdown(true, theme),
                            
                                  // ------- HACIA -------
                                  const SizedBox(height: 18),
                                  _buildDropdown(false, theme),
                                
                              
                                const SizedBox(height: 20),
                                ButtonSave(
                              title: 'Transferir',
                              message: '¿Estás seguro de que deseas realizar esta transferencia?',
                              onConfirm: () {
                                transferir();
                              },
                              formKey: _formKey,
                              label: 'Transferir'),
                              ],
                              ),
                            ),
                      ],
                  )
                ],
              ),
            ),
          )
        );
      }

      Widget _buildDropdown(bool isFrom, ThemeData theme) {
        final filteredItems = moneyMakers.where((m) {
          if (isFrom) {
            if (toMoneyMaker != null && m.id == toMoneyMaker!.id) return false;
            return true;
          } else {
            if (fromMoneyMaker == null) return false;
            if (m.id == fromMoneyMaker!.id) return false;
            return m.currency!.code == fromMoneyMaker!.currency!.code;
          }
        }).toList();

        MoneyMaker? initial = isFrom ? fromMoneyMaker : toMoneyMaker;

        if (isFrom == false && initial != null) {
          if (!filteredItems.any((m) => m.id == initial!.id)) {
            initial = null;
          }
        }

        return BottomSheetPickerField<MoneyMaker>(
          key: ValueKey('${isFrom ? 'from' : 'to'}-${initial?.id ?? 'null'}'),
          label: 'Fuentes ${isFrom ? 'origen' : 'destino'}',
          items: filteredItems,
          initialValue: initial,   
          itemLabel: (m) => m.name,
          itemIcon: (m) => CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              m.currency!.symbol,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              if (isFrom) {
                fromMoneyMaker = value;
                toMoneyMaker = null;    
              } else {
                toMoneyMaker = value;  
              }
            });
          },
          validator: (value) => value == null ? 'Debes seleccionar una fuente' : null,
        );
      }
    }
