import 'dart:io';
//import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/money_maker.dart';
import '../models/currency.dart';
import '../models/register.dart';

// URLs base
//const String baseUrl = "http://192.168.1.113:8000";
const String baseUrl = "http://192.168.0.162:8000";// guardo el mio je
//const String baseUrl = "http://172.16.89.42:8000"; // IP de la facu
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
  //required String currencyBase,
    required Currency currencyBase, // CAMBIO: ahora es Currency
  double? balance,
  File? icon,
  String? avatarSeed, // 👈 nuevo
}) async {
  try {
    final uri = Uri.parse('$apiUrl/register');
    var request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['password_confirmation'] = password
      ..fields['currency_id'] = currencyBase.id.toString()
      ..fields['balance'] = (balance ?? 0).toString();

    if (icon != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'icon',
        icon.path,
        filename: basename(icon.path),
      ));
    } else if (avatarSeed != null) {
      // si no hay icon, mandamos el seed en el mismo campo
      request.fields['icon'] = avatarSeed;
    }

    final streamedResponse = await request.send();
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

  ///////////////////////////////////////// Reenviar email de verificación
  Future<Map<String, dynamic>?> resendVerification() async {
    final token = await storage.read(key: 'token');
    if (token == null) return {'message': 'No hay sesión activa'};

    final res = await http.post(
      Uri.parse('$apiUrl/email/resend'),
      headers: jsonHeaders(token),
    );

    try {
      return jsonDecode(res.body);
    } catch (_) {
      return {'message': 'No se pudo reenviar el correo'};
    }
  }

// ✅ Nuevo: saber si hay token guardado
  Future<bool> hasToken() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }

// ✅ Nuevo: reenviar correo sin login (solo con email)
  Future<Map<String, dynamic>?> resendVerificationByEmail(String email) async {
    final res = await http.post(
      Uri.parse('$apiUrl/resend-verification'),
      headers: jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return {'message': 'Error al reenviar el correo'};
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

  if (res.statusCode == 200) {
    final Map<String, dynamic> user = jsonDecode(res.body);

    final icon = user['icon'] as String?;
    String? fullIconUrl;
    bool isSeed = false;

    if (icon != null && icon.isNotEmpty) {
      if (icon.startsWith('icons/')) {
        fullIconUrl = '$baseUrl/storage/$icon';
      } else {
        isSeed = true; // 👈 el backend guardó un avatarSeed en vez de un archivo
      }
    }

    return {
      ...user,
      'full_icon_url': fullIconUrl,
      'is_avatar_seed': isSeed,
      'balance_converted': user['balance_converted'] ?? user['balance'],
      'currency_symbol': user['currency_symbol'] ?? '',
    };
  }
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

  ///////////////////////////////////////////////////////////////// Actualizar usuario
  Future<Map<String, dynamic>?> updateUser({
  String? name,
  String? email,
  String? password,
  String? passwordConfirmation,
  int? currencyBase,
  double? balance,
  dynamic icon, // 👈 puede ser File o String
}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  try {
    final uri = Uri.parse('$apiUrl/user');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['_method'] = 'PUT';

    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (password != null) {
      request.fields['password'] = password;
      request.fields['password_confirmation'] =
          passwordConfirmation ?? password;
    }
    if (currencyBase != null) request.fields['currency_id'] = currencyBase.toString();
    if (balance != null) request.fields['balance'] = balance.toString();

    // 👇 acá chequeamos qué tipo de icon recibimos
    if (icon != null) {
      if (icon is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'icon',
          icon.path,
          filename: basename(icon.path),
        ));
      } else if (icon is String) {
        request.fields['icon'] = icon; // semilla
      }
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      final Map<String, dynamic> user = jsonDecode(res.body)['user'];

      final iconVal = user['icon'] as String?;
      String? fullIconUrl;
      bool isSeed = false;

      if (iconVal != null && iconVal.isNotEmpty) {
        if (iconVal.startsWith('icons/')) {
          fullIconUrl = '$baseUrl/storage/$iconVal';
        } else {
          isSeed = true;
        }
      }

      return {
        ...jsonDecode(res.body),
        'user': {
          ...user,
          'full_icon_url': fullIconUrl,
          'is_avatar_seed': isSeed,
        },
      };
    } else {
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return {'error': 'Error al actualizar usuario'};
      }
    }
  } catch (e) {
    return {'error': 'No se pudo conectar con el servidor'};
  }
}

  ///////////////////////////////////////////////////////////////// Eliminar usuario
  Future<bool> deleteUser() async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    final res = await http.delete(
      Uri.parse('$apiUrl/user'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      await storage.delete(key: 'token');
      return true;
    }
    return false;
  }

  ///////////////////////////////////////// Solicitar reactivación de cuenta
  Future<Map<String, dynamic>> requestReactivation(String email) async {
  try {
    final res = await http.post(
      Uri.parse('$apiUrl/users/request-reactivation'),
      headers: jsonHeaders(),
      body: jsonEncode({'email': email}),
    );

    return jsonDecode(res.body);
  } catch (e) {
    return {'error': 'No se pudo conectar con el servidor'};
  }
}


  ///////////////////////////////////////// Obtener estado de la casa
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
  int? currencyId,
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
            ..headers['Accept'] = 'application/json'


      ..fields['type'] = type
      ..fields['balance'] = balance.toString()
      ..fields['name'] = name
      ..fields['moneyMaker_id'] = moneyMakerId?.toString() ?? ''
      ..fields['category_id'] = categoryId?.toString() ?? ''
      ..fields['currency_id'] = currencyId?.toString() ?? ''
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
//////////////////////////////////////////////////////////////////

Future<List<Register>> getRegistersByMoneyMaker(int moneyMakerId) async {
  final token = await storage.read(key: 'token');
  if (token == null) return [];

  final res = await http.get(
    Uri.parse('$apiUrl/transactions/moneyMaker/$moneyMakerId'),
    headers: jsonHeaders(token),
  );
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    // Si la API devuelve una lista directa
    return (data['registers'] as List)
        .map((json) => Register.fromJson(json))
        .toList();
  }

  return [];
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
  Currency currency, // CAMBIO: objeto completo 
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
      'currency_id': currency.id, // CAMBIO: enviamos id
      'color': color,
    }),
  );
  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = jsonDecode(res.body);
    return MoneyMaker.fromJson(data['moneyMaker']);
  }

  return null;
}
Future<dynamic> updatePaymentSource(int id, String name, String type, double balance, Currency currency, String color) async {
  final response = await http.put(
    Uri.parse('$baseUrl/moneyMakers/$id'),
    headers: await jsonHeaders(),
    body: jsonEncode({
      'name': name,
      'type': type,
      'balance': balance,
      'currency_id': currency.id,
      'color': color,
    }),
  );

  if (response.statusCode == 200) {
    return MoneyMaker.fromJson(jsonDecode(response.body));
  } else {
    return null;
  }
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
    /*Future<List<dynamic>> getCurrencies() async {
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
  */
  Future<List<Currency>> getCurrencies() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/currencies'),
    headers: {'Accept': 'application/json'},
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Currency.fromJson(e)).toList();
  } else {
    throw Exception('Error al cargar las monedas');
  }
}


  ///////////!!!!!!!!!!!!!!!!!!!!!!!!!Leer moneda base desde API
    Future<int?> getUserCurrency() async {
    final token = await storage.read(key: 'token'); 
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/userCurrency'),
      headers: jsonHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['userBaseCurrency'] as int?;
    }
    return null;
  }

  ////////////////////////////////////////////////////////// Obtener datos para formulario de transacción
Future<Map<String, dynamic>> getTransactionFormData(String type) async {
  // Traer categorías y fuentes de dinero + moneda base
  final results = await Future.wait([
    getCategories(type),       // List<Map<String, dynamic>>
    getMoneyMakersFull(),      // Map con moneyMakers y currency_base
    getCurrencies(),       // List<Currency>
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
