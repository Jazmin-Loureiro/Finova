import 'package:flutter/material.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'providers/house_provider.dart';
import 'providers/register_provider.dart';
import 'providers/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:frontend/screens/reset_password_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 👇 Agregamos el observador global
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

   // Bloquea la orientación a solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => HouseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  StreamSubscription? _deepLinkSub;

  @override
  void initState() {
    super.initState();

    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen((uri) {
      if (uri.host == "reset-password") {
        final email = uri.queryParameters["email"];
        final token = uri.queryParameters["token"];

        if (email != null && token != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                email: email,
                token: token,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Finova',

      //  Tema claro
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7D2FFF),
          onPrimary: Colors.white,
          secondary: Color(0xFF00CC46),
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF141414),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        cardColor: const Color(0xFFFFFFFF),
        shadowColor: const Color(0xFFE0E0E0),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF141414)),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF141414)),
          titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF7D2FFF)),
          headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF3A00FF)),
          titleMedium: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF141414)),
        ),
        useMaterial3: true,
      ),

      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF914DFF),
          onPrimary: Colors.black,
          secondary: Color(0xFF00FF4C),
          onSecondary: Colors.white,
          surface: Color(0xFF151515),
          onSurface: Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color.fromARGB(255, 39, 39, 39),
        shadowColor: const Color.fromARGB(255, 89, 89, 89),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFB3B3B3)),
          titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF7D2FFF)),
          headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF00FF4C)),
        ),
        useMaterial3: true,
      ),

      themeMode: context.watch<ThemeProvider>().themeMode,
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

      // 👇 Registramos el observador
      navigatorObservers: [routeObserver],
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
      backgroundColor: Colors.transparent,
      body: Center(child: LoadingWidget()),
    );
  }
}
