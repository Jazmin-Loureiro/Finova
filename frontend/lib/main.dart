import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

// Punto de entrada de la aplicación
void main() {
  runApp(const MyApp()); // Lanza la app y muestra MyApp
}

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finova: Gestiona Tus finanzas', // Título de la app (para Android task manager, etc.)
      theme: ThemeData(
        primarySwatch: Colors.purple, // Tema principal con color púrpura
      ),
      debugShowCheckedModeBanner: false, // Quita la etiqueta "Debug" de la esquina
      home: const SplashScreen(), // Pantalla inicial al abrir la app
    );
  }
}

// Pantalla de carga inicial (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState(); // Crea el estado asociado a esta pantalla 
}

// Estado de SplashScreen (maneja la lógica)
class _SplashScreenState extends State<SplashScreen> {
  final ApiService api = ApiService(); // Instancia del servicio de API para manejar autenticación y usuario 

  @override
  void initState() { // Método que se llama al crear el estado 
    super.initState(); // Llama al initState del padre 
    _checkLogin(); // Se ejecuta apenas se crea la pantalla
  }

  // Verifica si el usuario está logueado o no
  void _checkLogin() async {
    final user = await api.getUser(); // Llama al backend o storage para obtener el usuario
     // Verifica que el widget todavía esté montado
  if (!mounted) return;
  
    if (user != null) {
      // Si hay usuario, navega al Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Si no hay usuario, navega al Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras se verifica el login, muestra un loader en el centro
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
