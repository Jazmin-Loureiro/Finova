import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget { // Pantalla principal después de iniciar sesión
  const HomeScreen({super.key}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState(); 
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService(); // Instancia del servicio API 
  late Future<Map<String, dynamic>?> userFuture; // Futuro para obtener los datos del usuario 

  @override
  void initState() {
    super.initState();
    userFuture = api.getUser();
  }

  void logout() async {
    await api.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar el usuario'));
          } else {
            final user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenido, ${user['name']}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Email: ${user['email']}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
