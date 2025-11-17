import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/casa_widget.dart';
import '../widgets/home_info_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/loading_widget.dart';   // 👈 AGREGAR IMPORT

class HomeScreen extends StatefulWidget {
  final bool showSuccessDialog;

  const HomeScreen({super.key, this.showSuccessDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  bool isLoading = true; // 👈 LOADING GENERAL

  @override
  void initState() {
    super.initState();

    // Dialog de inicio correcto
    if (widget.showSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => const SuccessDialogWidget(
            title: 'Inicio de sesión',
            message: 'Has iniciado sesión correctamente.',
            buttonText: 'Aceptar',
          ),
        );
      });
    }

    // Simular carga general de la screen mientras cargan los widgets
    Future.wait([
      Future.delayed(const Duration(milliseconds: 300)), 
    ]).then((_) {
      if (mounted) setState(() => isLoading = false);
    });
  }

  void logout() async {
    await api.logout();
    if (!mounted) return;

    await storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: CustomScaffold(
        title: 'Inicio',
        currentRoute: '/home',
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const CasaWidget(),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HomeInfoWidget(),
                  ],
                ),
              ),
            ),

            // 👇 LOADING GENERAL SOBRE TODA LA SCREEN
            if (isLoading)
              const Positioned.fill(
                child: LoadingWidget(message: "Cargando inicio..."),
              ),
          ],
        ),
      ),
    );
  }
}
