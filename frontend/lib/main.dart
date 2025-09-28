import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

// Punto de entrada de la aplicación
void main() {
  runApp(const MyApp());
}

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Finova',

  // 🎨 Tema claro
  theme: ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.deepPurple,
    onPrimary: Colors.white,
    secondary: Color(0xFF9575CD),
    onSecondary: Colors.white,
    surface: Colors.white,      // superficies claras
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: const Color.fromARGB(255, 232, 229, 229), // fondo general CREMITA
  useMaterial3: true,
),

darkTheme: ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Colors.deepPurple, // violeta claro
    onPrimary: Colors.black,
    secondary: Color(0xFF9575CD),
    onSecondary: Colors.white,
    surface: Color(0xFF121212), // 👈 NEGRO para barras/cards
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: Color.fromARGB(255, 48, 48, 48), // 👈 fondo más CLARO, GRIS CLARO
  useMaterial3: true,
),



  // 👇 Usa el tema según el sistema
  themeMode: ThemeMode.system,

  debugShowCheckedModeBanner: false,
  home: const SplashScreen(),
);


  }
}

// Pantalla de carga inicial (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final user = await api.getUser();
    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
