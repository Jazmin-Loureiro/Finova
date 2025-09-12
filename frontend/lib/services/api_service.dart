import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Ajustá según dispositivo:
  // Android emulator -> 10.0.2.2
  // iOS simulator -> localhost
  // Physical device -> http://192.168.x.x:8000 (IP de tu PC)
  final String baseUrl = "http://192.168.0.162:8000/api";
  final storage = const FlutterSecureStorage();

  Map<String, String> jsonHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Map<String,dynamic>?> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      await storage.write(key: 'token', value: data['token']);
      return data;
    } else {
      // devuelve el error para mostrar en UI
      return jsonDecode(res.body);
    }
  }

  Future<Map<String,dynamic>?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
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

  Future<Map<String,dynamic>?> getUser() async {
    final token = await storage.read(key: 'token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: jsonHeaders(token),
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<void> logout() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;
    await http.post(Uri.parse('$baseUrl/logout'), headers: jsonHeaders(token));
    await storage.delete(key: 'token');
  }
}
