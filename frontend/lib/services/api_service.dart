import 'dart:io';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/money_maker.dart';
import '../models/currency.dart';
// URLs base
const String baseUrl = "http://192.168.0.162:8000";
//const String baseUrl = "http://192.168.0.162:8000"; guardo el mio je
const String apiUrl = "$baseUrl/api";
// Instancia de almacenamiento seguro
final storage = const FlutterSecureStorage();

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

    // Obtener estado de la casa
  Future<Map<String, dynamic>> getHouseStatus() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('Usuario no logueado');

    final res = await http.get(
      Uri.parse('$apiUrl/house-status'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al cargar la casa: ${res.statusCode}');
    }
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


///////////////////////////////////////////////////////////// Obtener lista de fuentes de dinero + moneda base
Future<Map<String, dynamic>> getMoneyMakersFull() async {
  try {
    final token = await storage.read(key: 'token');
    if (token == null) return {'moneyMakers': [], 'currency_base': ''};
    final res = await http.get(
      Uri.parse('$apiUrl/moneyMakers'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> list = data['moneyMakers'] ?? [];
      final moneyMakers = list.map((e) => MoneyMaker.fromJson(e)).toList();
      final currencyBase = data['currency_base'] ?? '';
      final currencySymbol = data['currency_symbol'] ?? '';
      return {'moneyMakers': moneyMakers, 'currency_base': currencyBase, 'currency_symbol': currencySymbol};
    } else {
      return {'moneyMakers': [], 'currency_base': '', 'currency_symbol': ''};
    }
  } catch (e) {
    return {'moneyMakers': [], 'currency_base': '', 'currency_symbol': ''};
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
    return MoneyMaker.fromJson(data['moneyMaker']);
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

  ////////////////////////////////////////  Obtener lista de monedas no necesita token
    Future<List<dynamic>> getCurrencies() async {
    final response = await http.get(Uri.parse('$baseUrl/api/currencies'),
    headers: {
      'Accept': 'application/json',
    },);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar las monedas');
    }
  }

  ///////////////////////////////////////// Método que ya devuelve la lista de monedas parseadas
  Future<List<Currency>> getCurrenciesList() async {
    final List<dynamic> data = await getCurrencies();
    return data.map((e) => Currency.fromJson(e)).toList();
  }

  ///////////!!!!!!!!!!!!!!!!!!!!!!!!!Leer moneda base desde API
    Future<String?> getUserCurrency() async {
    final token = await storage.read(key: 'token'); 
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/userCurrency'),
      headers: jsonHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['userBaseCurrency'] as String?;
    }
    return null;
  }

  ////////////////////////////////////////////////////////// Obtener datos para formulario de transacción
Future<Map<String, dynamic>> getTransactionFormData(String type) async {
  // Traer categorías y fuentes de dinero + moneda base
  final results = await Future.wait([
    getCategories(type),       // List<Map<String, dynamic>>
    getMoneyMakersFull(),      // Map con moneyMakers y currency_base
    getCurrenciesList(),       // List<Currency>
  ]);

  final categories = results[0] as List<Map<String, dynamic>>;
  final moneyMakersData = results[1] as Map<String, dynamic>;
  final moneyMakers = moneyMakersData['moneyMakers'] as List<MoneyMaker>;
  final currencyCode = moneyMakersData['currency_base'] as String?;
  final currencies = results[2] as List<Currency>;

  // Moneda por defecto
  final defaultCurrency = currencyCode != null
      ? currencies.firstWhere(
          (c) => c.code == currencyCode,
          orElse: () => currencies.first,
        )
      : currencies.first;

  return {
    'categories': categories,
    'moneyMakers': moneyMakers,
    'currencies': currencies,
    'defaultCurrency': defaultCurrency,
  };
}



}
