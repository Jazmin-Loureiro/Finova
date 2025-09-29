import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HouseProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  Map<String, dynamic>? houseData;
  Timer? _timer;

  HouseProvider() {
    _loadHouse(); // primera carga inmediata
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _loadHouse());
  }

  Future<void> _loadHouse() async {
    try {
      final data = await api.getHouseStatus();
      houseData = data;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error en getHouseStatus: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
