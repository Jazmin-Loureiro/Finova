import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HouseProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  Map<String, dynamic>? houseData;

  HouseProvider() {
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.getHouseStatus();
      houseData = data;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error en getHouseStatus: $e");
    }
  }

  // 🔥 Resetea la casa al cambiar usuario
  void reset() {
    houseData = null;
    notifyListeners();
  }
}


