import 'dart:io';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "http://192.168.1.113:8000";
const String apiUrl = "http://192.168.1.113:8000/api";

class ApiService {
  final storage = const FlutterSecureStorage();

  Map<String, String> jsonHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Registro
  Future<Map<String, dynamic>?> register(
  String name,
  String email,
  String password, {
  required String monedaBase,
  double? saldo,
  File? icon,
}) async {
  try {
    final uri = Uri.parse('$apiUrl/register');

    var request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['password_confirmation'] = password
      ..fields['moneda_base'] = monedaBase
      ..fields['saldo'] = (saldo ?? 0).toString();

    if (icon != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'icon',
        icon.path,
        filename: basename(icon.path),
      ));
    }

    var streamedResponse = await request.send();
    var res = await http.Response.fromStream(streamedResponse);

    
    // Solo decodificamos si es JSON válido
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      // Puedes retornar el cuerpo como mapa si el backend devuelve JSON de error
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


  // Login
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

  // Usuario
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

  // Logout
  Future<void> logout() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    await http.post(
      Uri.parse('$apiUrl/logout'),
      headers: jsonHeaders(token),
    );

    await storage.delete(key: 'token');
  }
}
