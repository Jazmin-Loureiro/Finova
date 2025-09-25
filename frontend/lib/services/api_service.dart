import 'dart:io';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/money_maker.dart';
// URLs base
const String baseUrl = "http://192.168.0.162:8000";
//const String baseUrl = "http://192.168.0.162:8000"; guardo el mio je
const String apiUrl = "$baseUrl/api";

class ApiService {
  final storage = const FlutterSecureStorage();

  // Encabezados JSON con token opcional
  Map<String, String> jsonHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  ///////////////////////////////////////// Registro de usuario
  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password, {
    required String currencyBase,
    double? balance,
    File? icon,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/register');
      var request = http.MultipartRequest('POST', uri)
        ..fields['name'] = name
        ..fields['email'] = email
        ..fields['password'] = password
        ..fields['password_confirmation'] = password
        ..fields['currencyBase'] = currencyBase
        ..fields['balance'] = (balance ?? 0).toString();

      if (icon != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'icon',
          icon.path,
          filename: basename(icon.path),
        ));
      }

      final streamedResponse = await request.send(); // Enviar la solicitud a la API
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        try {
          return jsonDecode(res.body);
        } catch (_) {
          return {'error': 'Error en el registro, intente nuevamente'};
        }
      }
    } catch (e) {
      return {'error': 'No se pudo conectar con el servidor'};
    }
  }

  /////////////////////////////////////////////////////////////////// Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$apiUrl/login'),
      headers: jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await storage.write(key: 'token', value: data['token']);
      return data;
    } else {
      return jsonDecode(res.body);
    }
  }

  //////////////////////////////////////////////////////////////// Obtener usuario logueado
  Future<Map<String, dynamic>?> getUser() async {
    final token = await storage.read(key: 'token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse('$apiUrl/user'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  /////////////////////////////////////////////////////////////////Logout
  Future<void> logout() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    await http.post(
      Uri.parse('$apiUrl/logout'),
      headers: jsonHeaders(token),
    );

    await storage.delete(key: 'token');
  }

////////////////////////////////////////////////////////////////// Crear transacción ingreso/gasto
Future<Map<String, dynamic>?> createTransaction(
  String type,
  double balance,
  String name, {
  int? moneyMakerId,
  int? categoryId,
  String? typeMoney,
  File? file,
  bool? repetition,
  int? frequencyRepetition,
}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  try {
    final uri = Uri.parse('$apiUrl/transactions');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type'] = type
      ..fields['balance'] = balance.toString()
      ..fields['name'] = name
      ..fields['moneyMaker_id'] = moneyMakerId?.toString() ?? ''
      ..fields['category_id'] = categoryId?.toString() ?? ''
      ..fields['typeMoney'] = typeMoney ?? ''
      ..fields['repetition'] = (repetition ?? false) ? '1' : '0';

    if (frequencyRepetition != null) {
      request.fields['frequency_repetition'] = frequencyRepetition.toString();
    }

    // Adjuntar archivo si existe
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ));
    }

    // Enviar la solicitud
    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return {'error': 'Error al crear la transacción'};
      }
    }
  } catch (e) {
    return {'error': 'No se pudo conectar con el servidor'};
  }
}


///////////////////////////////////////////////////////////// Obtener lista de fuentes de dinero
Future<List<MoneyMaker>> getMoneyMakers() async {
  try {
    final token = await storage.read(key: 'token');
    if (token == null) return [];

    final res = await http.get(
      Uri.parse('$apiUrl/moneyMakers'),
      headers: jsonHeaders(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> list = data['moneyMakers'] ?? [];
      return list.map((e) => MoneyMaker.fromJson(e)).toList();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}


  ////////////////////////////////////////////////////////// Agregar nueva fuente de pago
Future<MoneyMaker?> addPaymentSource(
  String name,
  String typeSelected,
  double balance,
  String typeMoney,
  String color,
) async {
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final res = await http.post(
    Uri.parse('$apiUrl/moneyMakers'),
    headers: jsonHeaders(token),
    body: jsonEncode({
      'name': name,
      'type': typeSelected,
      'balance': balance,
      'typeMoney': typeMoney,
      'color': color,
    }),
  );

  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = jsonDecode(res.body);
    return MoneyMaker.fromJson(data['data']);
  }

  return null;
}


   ///////////////////////////////////////////////// // Agregar nueva categoría
    Future<bool> addCategory({
      required String name,
      required String type,
      required String color,
    }) async {
       final token = await storage.read(key: 'token'); 
    if (token == null) return false; 
      final response = await http.post(
        Uri.parse('$apiUrl/categories'),
        headers: jsonHeaders(token),
        body: jsonEncode({
          'name': name,
          'type': type,
          'color': color,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    }

//////////////////////////////////////////// Obtener lista de categorías por tipo (ingreso/gasto)
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final token = await storage.read(key: 'token');
    if (token == null) return [];
     final typeLower = type.toLowerCase(); // Convertir a minúsculas para consistencia
    final res = await http.get(
      Uri.parse('$apiUrl/categories?type=$typeLower'), // 
      headers: jsonHeaders(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }
    return [];
  }

  //////////////////////////////////////// creo q no se usa todavia Obtener lista de monedas
  Future<List<String>> getMonedas() async {
    final token = await storage.read(key: 'token');
    if (token == null) return [];

    final res = await http.get(
      Uri.parse('$apiUrl/monedas'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data['monedas'] ?? []);
    }
    return [];
  }

}
