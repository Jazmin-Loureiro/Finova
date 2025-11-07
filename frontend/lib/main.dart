import 'package:flutter/material.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'providers/house_provider.dart';
import 'providers/register_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home/onboarding_screen.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => HouseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finova',

      //  Tema claro
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7D2FFF), // Violeta Finova
          onPrimary: Colors.white,
          secondary: Color(0xFF00CC46), // Verde éxito
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF), // Tarjetas
          onSurface: Color(0xFF141414), // Texto principal
        ),
        scaffoldBackgroundColor: Color(0xFFF8F8F8), // Fondo claro general
        cardColor: Color(0xFFFFFFFF), // Fondo secundario
        shadowColor: Color(0xFFE0E0E0), // Bordes/sombras suaves
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF141414)),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF141414)),
          titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7D2FFF)),
          headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF3A00FF)),
        ),
        useMaterial3: true,
      ),

      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7D2FFF), // Violeta Finova
          onPrimary: Colors.black,
          secondary: Color(0xFF00FF4C), // Verde Neón
          onSecondary: Colors.white,
          surface: Color(0xFF151515), // Tarjetas
          onSurface: Color(0xFFFFFFFF), // Texto principal
        ),
        scaffoldBackgroundColor: Color(0xFF0A0A0A), // Fondo principal
        cardColor: Color.fromARGB(255, 39, 39, 39), // Fondo secundario
        shadowColor: Color.fromARGB(255, 89, 89, 89), // Bordes/íconos suaves
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: Color(0xFFB3B3B3)),
          titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7D2FFF)),
          headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF00FF4C)),
        ),
        useMaterial3: true,
      ),

      // 👇 Usa el tema según el sistema
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🕐 Fuerza formato 24 horas + fondo global degradado
      builder: (context, child) {
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final background = theme.scaffoldBackgroundColor;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                background.withOpacity(0.97),
                background.withOpacity(0.9),
                primary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },

      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

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
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent, // 👈 Deja ver el fondo global
      body: Center(child: LoadingWidget()),
    );
  }
}
