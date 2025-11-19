import 'dart:io';
//import 'package:flutter/material.dart';
import 'package:frontend/models/category.dart';
import 'package:frontend/models/investment_rate.dart';
import 'package:frontend/models/money_maker_type.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/money_maker.dart';
import '../models/currency.dart';
import '../models/register.dart';
import '../models/goal.dart';

// URLs base
//const String baseUrl = "http://192.168.1.113:8000"; //Jaz
const String baseUrl = "http://192.168.0.106:8000"; // Jaz 2
//const String baseUrl = "http://192.168.1.45:8000"; //Jaz 3
//const String baseUrl = "http://192.168.0.162:8000";// guardo el mio je
//const String baseUrl = "http://127.0.0.1:8000"; //compu local
//const String baseUrl = "http://172.16.195.79:8000"; // IP de la facu
const String apiUrl = "$baseUrl/api";
// Instancia de almacenamiento seguro
final storage = const FlutterSecureStorage();

// Excepción personalizada para manejar el error 429 (Too Many Requests)
class CooldownException implements Exception {
  final int status;
  final String message;
  final String? nextRefreshAt; // ISO8601
  final String? serverNow;     // ISO8601

  CooldownException({
    required this.status,
    required this.message,
    this.nextRefreshAt,
    this.serverNow,
  });

  @override
  String toString() => 'CooldownException($status): $message';
}

class ChallengeBlockedException implements Exception {
  final String message;
  ChallengeBlockedException(this.message);
  @override
  String toString() => 'ChallengeBlockedException: $message';
}


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

//////////////////////////////////////////////// Solicitar recuperacion contraseña
Future<Map<String, dynamic>> sendForgotPassword(String email) async {
  final url = Uri.parse('$apiUrl/forgot-password');
  try {
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (data['status'] == 'passwords.sent') {
      return {
        'success': true,
        'message': 'Se envió un email con instrucciones para recuperar tu contraseña.'
      };
    }

    if (data['status'] == 'passwords.user') {
      return {
        'success': true,
        'message': 'Si el correo está registrado, recibirás un email con instrucciones.'
      };
    }
    return {'success': false, 'error': 'Error inesperado'};
  } catch (e) {
    return {'success': false, 'error': 'No se pudo conectar con el servidor'};
  }
}

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('$apiUrl/reset-password');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar con el servidor'};
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

// Marcar extra como mostrado
Future<bool> markExtraShown(int extraId) async {
  final token = await storage.read(key: 'token');
  if (token == null) throw Exception('Usuario no logueado');

  final res = await http.post(
    Uri.parse('$apiUrl/house/extras/mark-shown'),
    headers: jsonHeaders(token),
    body: jsonEncode({'extra_id': extraId}),
  );

  return res.statusCode == 200;
}

////////////////////////////////////////////////////////////////// Crear transacción ingreso/gasto
Future<Map<String, dynamic>?> createTransaction(
  String type,
  double balance,
  String name, {
  int? moneyMakerId,
  int? categoryId,
  int? currencyId,
  int? goalId,
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

    if (goalId != null) {
      request.fields['goal_id'] = goalId.toString();
    }
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

///////////////////////////////////////////////////////////// Asignar dinero reservado a fuentes de dinero
Future<Map<String, dynamic>> assignReservedToMoneyMakers(int goalId) async {
  final token = await storage.read(key: 'token');
  if (token == null) throw Exception('Usuario no logueado');

  final url = Uri.parse('$apiUrl/goals/assign-reserved');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // << token agregado
    },
    body: jsonEncode({'goal_id': goalId}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error al asignar dinero reservado: ${response.body}');
  }
}
// Obtener metas vencidas 

Future<List<dynamic>> getExpiredGoals() async {
  final token = await storage.read(key: 'token');
  final response = await http.get(
    Uri.parse('$apiUrl/goals/expired'),
    headers: jsonHeaders(token),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['expired_goals'] ?? [];
  }
  return [];
}

Future<List<Register>> getAllRegister({
  String type = "all",
  String? category,
  DateTime? from,
  DateTime? to,
  String search = "",
}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return [];

  // Parámetros opcionales
  final params = {
    'type': type,
    'search': search,
  };

  if (category != null) params['category'] = category;
  if (from != null) params['from'] = from.toIso8601String();
  if (to != null) params['to'] = to.toIso8601String();

  // Construir URL con query
  final uri = Uri.parse('$apiUrl/transactions')
      .replace(queryParameters: params);

  final res = await http.get(uri, headers: jsonHeaders(token));

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['registers'] as List)
        .map((j) => Register.fromJson(j))
        .toList();
  }

  return [];
}

Future<List<Register>> getRegistersByMoneyMaker(
  int moneyMakerId, {
  String type = "all",
  String? category,
  DateTime? from,
  DateTime? to,
  String search = "",
}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return [];
  final params = {'type': type,'search': search,};
  if (category != null) params['category'] = category;
  if (from != null) params['from'] = from.toIso8601String();
  if (to != null) params['to'] = to.toIso8601String();

  final uri = Uri.parse('$apiUrl/transactions/moneyMaker/$moneyMakerId')
      .replace(queryParameters: params);

  final res = await http.get(uri, headers: jsonHeaders(token));

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['registers'] as List)
        .map((j) => Register.fromJson(j))
        .toList();
  }
  return [];
}

Future<Register?> getDataRegister(int id) async {
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final res = await http.get(
    Uri.parse('$apiUrl/transactions/$id'),
    headers: jsonHeaders(token),
  );
  if (res.statusCode == 200) {
  return Register.fromJson(jsonDecode(res.body)); 
  }

  return null;
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
  int typeSelected,
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

Future<dynamic> updatePaymentSource( int id,String name, int type, String color,) async {
  final token = await storage.read(key: 'token');
  if (token == null) return false;
  final response = await http.put(
    Uri.parse('$apiUrl/moneyMakers/$id'),
        headers: jsonHeaders(token),
    body: jsonEncode({
      'name': name,
      'type': type,
      'color': color,
    }),
  );
  if (response.statusCode == 200) {
    return MoneyMaker.fromJson(jsonDecode(response.body));
  } else {
    return null;
  }
}

  ////////////////////////////////////////////////////////// Eliminar fuente de pago
Future<void> deleteMoneyMaker(int id) async {
  final token = await storage.read(key: 'token');
  if (token == null) return;
  final response = await http.delete(
    Uri.parse('$apiUrl/moneyMakers/$id'),
    headers: jsonHeaders(token),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode != 200) {
    throw Exception(data['message']);
  }
}
///////////////////////////////////////////////////////// Activar fuente de pago
Future<void> activeMoneyMaker(int id) async {
  final token = await storage.read(key: 'token');
  if (token == null) return;
  final response = await http.post(
    Uri.parse('$apiUrl/moneyMakers/$id/activate'),
    headers: jsonHeaders(token),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode != 200) {
    throw Exception(data['message']);
  }
}

//// Tipos de fuente
Future<List<MoneyMakerType>> getMoneyMakerTypes() async {
  final token = await storage.read(key: 'token');
  if (token == null) return [];

  final response = await http.get(
    Uri.parse('$apiUrl/moneyMakerTypes'),
    headers: jsonHeaders(token),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map((t) => MoneyMakerType.fromJson(t)).toList();
    }
  }
  return [];
}
//////////////////////////////////////////////////////
//// Categorías
/////////////////////////////////////////////////////

   ///////////////////////////////////////////////// // Agregar nueva categoría
   Future<Category?> addCategory({
  required String name,
  required String type,
  required String color,
  required String icon,
}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final response = await http.post(
    Uri.parse('$apiUrl/categories'),
    headers: jsonHeaders(token),
    body: jsonEncode({
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return Category.fromJson(data['data']); 
  }

  return null;
}

//////////////////////////////////////////// Obtener lista de categorías por tipo (ingreso/gasto)
  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return [];
  // Si tiene tipo, agregamos el parámetro; si no, pedimos todas
  final url = type != null
      ? '$apiUrl/categories?type=${type.toLowerCase()}'
      : '$apiUrl/categories';

  final res = await http.get(
    Uri.parse(url),
    headers: jsonHeaders(token),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['categories'] ?? []);
  } else {
    throw Exception('Error al obtener categorías: ${res.statusCode}');
  }
}

/////////////Editar categoria
Future<bool> updateCategory({required int id, required Map<String, dynamic> data}) async {
  final token = await storage.read(key: 'token');
  if (token == null) return false;
  final response = await http.put(
    Uri.parse('$apiUrl/categories/$id'),
    headers: jsonHeaders(token),
    body: jsonEncode(data),
  );
  return response.statusCode == 200;
}

Future<bool> deleteCategory(int id) async {
  final token = await storage.read(key: 'token');
  if (token == null) return false;
  final response = await http.delete(
    Uri.parse('$apiUrl/categories/$id'),
    headers: jsonHeaders(token),
  );
  return response.statusCode == 200;
}

////////////////////////////////////////////////////
/// Monedas
/// ///////////////////////////////////////////////
  ////////////////////////////////////////  Obtener lista de monedas no necesita token
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
    getCategories(type: type),       // List<Map<String, dynamic>>
    getMoneyMakersFull(),      // Map con moneyMakers y currency_base
    getCurrencies(),       // List<Currency>
    getGoals()
  ]);

  final categories = results[0] as List<Map<String, dynamic>>;
  final moneyMakersData = results[1] as Map<String, dynamic>;
  final allMoneyMakers = moneyMakersData['moneyMakers'] as List<MoneyMaker>;
  final moneyMakers = allMoneyMakers.where((mm) => mm.active).toList();
  final currencyCode = moneyMakersData['currency_base'] as String?;
  final currencies = results[2] as List<Currency>;
  final goals = results[3] as List<Goal>;

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
    'goals': goals,
  };
}

 ////////////////////////////////////////////////////////////////
  /// 🔹 Desafíos (Challenges)
  ////////////////////////////////////////////////////////////////

  /// Obtener lista de desafíos disponibles + meta (tipado)
  Future<Map<String, dynamic>> getAvailableChallenges() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('Usuario no logueado');

    final res = await http.get(
      Uri.parse('$apiUrl/challenges/available'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      // Fuerza a Map<String,dynamic>
      final data = Map<String, dynamic>.from(jsonDecode(res.body));
       print('🔍 gamification/profile: ${jsonEncode(data)}'); // Revisa que devuelve el json
      return data;
    } else {
      throw Exception('Error al obtener desafíos');
    }
  }


  /// Aceptar un desafío por su ID
  Future<bool> acceptChallenge(int id) async {
  final token = await storage.read(key: 'token');
  if (token == null) return false;

  final res = await http.post(
    Uri.parse('$apiUrl/user-challenges/$id/accept'),
    headers: jsonHeaders(token),
  );

  if (res.statusCode == 200) {
    return true;
  } else if (res.statusCode == 409) {
    try {
      final data = jsonDecode(res.body);
      final msg = (data['message'] as String?) ??
                  (data['locked_reason'] as String?) ??
                  'Este desafío está bloqueado por otro en progreso.';
      throw ChallengeBlockedException(msg);
    } catch (_) {
      throw ChallengeBlockedException('Este desafío está bloqueado por otro en progreso.');
    }
  } else {
    return false;
  }
}


  /// 🔹 Obtener perfil completo de gamificación (nuevo endpoint principal)
  Future<Map<String, dynamic>> getGamificationProfile() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('Usuario no logueado');

    final res = await http.get(
      Uri.parse('$apiUrl/gamification/profile'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } else {
      throw Exception('Error al obtener perfil de gamificación');
    }
  }


    /// 🔄 Regenerar desafíos disponibles (devuelve lista + meta) con excepción tipada en 429
  Future<Map<String, dynamic>> refreshChallenges() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('Usuario no logueado');

    final res = await http.post(
      Uri.parse('$apiUrl/challenges/refresh'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(res.body));
      return data;
    } else if (res.statusCode == 429) {
      Map<String, dynamic> data = {};
      try {
        data = Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {}
      throw CooldownException(
        status: 429,
        message: (data['message'] as String?) ?? 'Tenés que esperar un poco.',
        nextRefreshAt: data['next_refresh_at'] as String?,
        serverNow: data['server_now'] as String?,
      );
    } else {
      throw Exception('Error al regenerar desafíos');
    }
  }
 
 ///cancelar reserva
Future<bool> cancelReserve(int registerId) async {
  final token = await storage.read(key: 'token');
  if (token == null) throw Exception('Usuario no logueado');

  try {
    final res = await http.post(
      Uri.parse('$apiUrl/reservations/$registerId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      return true;
    }
  } catch (e) {
    throw Exception('Error de conexión con el servidor');
  }
  return false;
}

  /////////////////////////////////////////////////////////////
  ///Metas
  /////////////////////////////////////////////////////////////
  Future<List<Goal>> getGoals() async {
    final token = await storage.read(key: 'token');
    if (token == null) return [];
    final res = await http.get(
      Uri.parse('$apiUrl/goals'),
      headers: jsonHeaders(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Goal>.from(data['goals']?.map((g) => Goal.fromJson(g)) ?? []);
    }
    throw Exception('Error al cargar metas (${res.statusCode})');
  }
////////////////////////////////////////////////////////// Crear nueva meta
  Future <void> createGoal(Map<String, dynamic> goalData) async {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('Usuario no logueado');
      final res = await http.post(
        Uri.parse('$apiUrl/goals'),
        headers: jsonHeaders(token),
        body: jsonEncode(goalData),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Error al crear la meta: ${res.statusCode}');
      }
  }

///////////////////////////////////////////////////////// Editar meta existente
  Future <void> editGoal(int goalId, Map<String, dynamic> goalData) async {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('Usuario no logueado');
      final res = await http.put(
        Uri.parse('$apiUrl/goals/$goalId'),
        headers: jsonHeaders(token),
        body: jsonEncode(goalData),
      );
      if (res.statusCode != 200) {
        throw Exception('Error al editar la meta: ${res.statusCode}');
      }
  }

///////////////////////////////////////////////////////// Desactivar meta existente // BorradoLogico 
  Future <void> deleteGoal(int goalId) async {
      final token = await storage.read(key: 'token'); 
      if (token == null) throw Exception('Usuario no logueado');
      final res = await http.delete(
        Uri.parse('$apiUrl/goals/$goalId'),
        headers: jsonHeaders(token),
      );
      if (res.statusCode != 200) {
        throw Exception('Error al eliminar la meta: ${res.statusCode}');
      }
  }

Future<List<Register>> fetchRegistersByGoal(int goalId) async {
  final token = await storage.read(key: 'token');
  if (token == null) throw Exception('Usuario no logueado');
  final res = await http.get(
    Uri.parse('$apiUrl/goals/$goalId/registers'),
    headers: jsonHeaders(token),
  );
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body)['registers'] as List;
    return data.map((json) => Register.fromJson(json)).toList();
  } else {
    throw Exception('Error al obtener registros: ${res.statusCode}');
  }
}

//////////////////////////////////////////////////////////////////////
Future<Goal> fetchGoal(int id) async {
  final token = await storage.read(key: 'token');
  final uri = Uri.parse('$apiUrl/goals/$id');
  final res = await http.get(uri, headers: jsonHeaders(token));
  if (res.statusCode != 200) {
    throw Exception('Error ${res.statusCode}: ${res.reasonPhrase}');
  }
  final data = jsonDecode(res.body);
  return Goal.fromJson(data);
}


//////////////////////////////////////////////////////////////// Simulaciones financieras

  // 🔹 Simular préstamo personal
  Future<Map<String, dynamic>?> simulateLoan({
    required double capital,
    required int cuotas,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      final res = await http.post(
        Uri.parse('$apiUrl/simulate/loan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'capital': capital, 'cuotas': cuotas}),
      );
      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo realizar la simulación'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }


  // 🔹 Plazo fijo (GET, tal como tu backend)
  Future<Map<String, dynamic>?> simulatePlazoFijo({
    required double monto,
    required int dias,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      final res = await http.get(
        Uri.parse('$apiUrl/simulate/plazo-fijo?monto=$monto&dias=$dias'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo realizar la simulación'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }


  // 🔹 Criptomonedas (POST con body JSON)
  Future<Map<String, dynamic>?> simulateCrypto({
    required double monto,
    required int dias,
    String coin = 'bitcoin',
  }) async {
    try {
      final token = await storage.read(key: 'token');

      final res = await http.post(
        Uri.parse('$apiUrl/simulate/crypto'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', // 👈 agregamos token si existe
        },
        body: jsonEncode({'monto': monto, 'dias': dias, 'coin': coin}),
      );

      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo realizar la simulación'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }

  // 🔹 Acciones (POST con body JSON)
  Future<Map<String, dynamic>?> simulateStock({
    required double monto,
    required int dias,
    String symbol = 'AAPL',
  }) async {
    try {
      final token = await storage.read(key: 'token');

      final res = await http.post(
        Uri.parse('$apiUrl/simulate/stock'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'monto': monto, 'dias': dias, 'symbol': symbol}),
      );

      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo realizar la simulación'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }


  // 🔹 Bonos (POST con body JSON)
  Future<Map<String, dynamic>?> simulateBond({
    required double monto,
    required int dias,
    String bono = 'TLT',
  }) async {
    try {
      final token = await storage.read(key: 'token');

      final res = await http.post(
        Uri.parse('$apiUrl/simulate/bond'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'monto': monto, 'dias': dias, 'bono': bono}),
      );

      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo realizar la simulación'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }


  // 🔹 Cotización actual (GET, correcto)
  Future<Map<String, dynamic>?> marketQuote({
    required String type,
    required String symbol,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$apiUrl/market/$type/$symbol'),
        headers: jsonHeaders(),
      );
      return res.statusCode == 200
          ? jsonDecode(res.body)
          : {'error': 'No se pudo obtener la cotización'};
    } catch (e) {
      return {'error': 'Error de conexión con el servidor'};
    }
  }


  ///////////////////////////////////////// Obtener tasas de inversión SOAP
 Future<List<InvestmentRate>> getInvestmentRates() async {
    final response = await http.get(
      Uri.parse('$apiUrl/soap/investment-rates'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['rates'] as List;
      return data.map((json) => InvestmentRate.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar las tasas');
    }
  }


Future<Map<String, dynamic>> getStatistics(int range) async {
  final token = await storage.read(key: 'token');
  final uri = Uri.parse('$apiUrl/statistics').replace( queryParameters: {'range': range.toString()},);
  try {
    final res = await http.get(
      uri,
      headers: jsonHeaders(token),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Error ${res.statusCode}: ${res.reasonPhrase}',
      );
    }
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inválido');
    }
    return data;
  } catch (e) {
    throw Exception('No se pudieron cargar las estadísticas');
  }
}





}





