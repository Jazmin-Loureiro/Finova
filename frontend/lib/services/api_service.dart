import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
final String baseUrl = 'http://192.168.0.162:8000/api';
 // Para emulador Android

  // Registro
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      print('Registro statusCode: ${response.statusCode}');
      print('Registro body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'message': errorData['message'] ?? 'Error del servidor'};
      }
    } catch (e) {
      print('Error al registrar: $e');
      return {'message': 'Error de conexión'};
    }
  }

  // Login (ahora dentro de la clase)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login statusCode: ${response.statusCode}');
      print('Login body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'message': errorData['message'] ?? 'Error del servidor'};
      }
    } catch (e) {
      print('Error al loguear: $e');
      return {'message': 'Error de conexión'};
    }
  }
}
