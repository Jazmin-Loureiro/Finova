import 'package:flutter/material.dart';
import '../models/register.dart';
import '../models/money_maker.dart';
import '../services/api_service.dart';

class RegisterProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  List<Register> _registers = [];
  List<Register> get registers => _registers;

  double _balance = 0;
  double get balance => _balance;

  String _currencySymbol = '';
  String get currencySymbol => _currencySymbol;

  int? _moneyMakerId;
  int? get moneyMakerId => _moneyMakerId;

  List<MoneyMaker> _moneyMakers = [];
  List<MoneyMaker> get moneyMakers => _moneyMakers;

  String _currencyBase = '';
  String get currencyBase => _currencyBase;

  String _currencyBaseSymbol = '';
  String get currencyBaseSymbol => _currencyBaseSymbol;

  double _totalInBase = 0.0;
  double get totalInBase => _totalInBase;

  /// Cargar registros y balance de una fuente de dinero
  Future<void> loadRegisters(int moneyMakerId) async {
    _moneyMakerId = moneyMakerId;
    try {
      _registers = await api.getRegistersByMoneyMaker(moneyMakerId);
      _balance = _registers.fold(0.0, (sum, r) => r.type == 'income' ? sum + r.balance : sum - r.balance);
      if (_registers.isNotEmpty) _currencySymbol = _registers.first.currency.symbol;
    } catch (e) {
      _registers = [];
      _balance = 0;
    }
    notifyListeners();
  }

  /// Cargar todas las fuentes de dinero con balances convertidos
  
  Future<void> loadMoneyMakers() async {
    try {
      final response = await api.getMoneyMakersFull();
      
      _moneyMakers = List<MoneyMaker>.from(response['moneyMakers']);

      _currencyBase = response['currency_base'] ?? '';
      _currencyBaseSymbol = response['currency_symbol'] ?? '';
      
      //  Calcular total en base si balanceConverted es válido
      _totalInBase = _moneyMakers.fold(0.0, (sum, m) {
        final value = double.tryParse(m.balanceConverted.toString()) ?? 0.0;
        return sum + value;
      });

      notifyListeners();
    } catch (e) {
      _moneyMakers = [];
      _totalInBase = 0.0;
      notifyListeners();
    }
  }
}
