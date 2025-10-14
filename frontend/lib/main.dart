import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 import del provider
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'providers/house_provider.dart'; // 👈 tu nuevo provider

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Punto de entrada de la aplicación
void main() async {
    //  Inicializa los datos de localización para español (Argentina o genérico)
    WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => HouseProvider(), // 👈 se inicializa apenas arranca la app
      child: const MyApp(),
    ),
  );
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
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 232, 229, 229),
        useMaterial3: true,
      ),

      // 🎨 Tema oscuro
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          onPrimary: Colors.black,
          secondary: Color(0xFF9575CD),
          onSecondary: Colors.white,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 48, 48, 48),
        useMaterial3: true,
      ),

      // 👇 Usa el tema según el sistema
      themeMode: ThemeMode.system,
      //  Esto hace que todo (calendario, fechas, textos) use español
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (por si acaso)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🕐 Fuerza formato 24 horas global
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },

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
