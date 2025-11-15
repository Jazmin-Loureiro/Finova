import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/casa_widget.dart';
import '../widgets/home_info_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/custom_scaffold.dart';

class HomeScreen extends StatefulWidget {
  final bool showSuccessDialog;

  const HomeScreen({super.key, this.showSuccessDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();

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
  }

  void logout() async {
    await api.logout();
    if (!mounted) return;
    await storage.delete(key: 'token'); // Elimina el token almacenado
    Navigator.pushAndRemoveUntil( // Navega al login y elimina el historial
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false, // Elimina todas las rutas anteriores
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 🔒 Evita que el botón "atrás" cierre el Home o vuelva al login
        return false;
      },
      child: CustomScaffold(
        title: 'Inicio',
        currentRoute: '/home',
        extendBody: true,
        extendBodyBehindAppBar: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => ConfirmDialogWidget(
                  title: 'Cerrar sesión',
                  message: '¿Estás seguro de que deseas cerrar sesión?',
                  confirmText: 'Cerrar sesión',
                  cancelText: 'Cancelar',
                  confirmColor: Colors.red,
                ),
              );

              if (confirmed == true) {
                logout(); // tu método logout()
              }
            },
          ),
        ],
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
          ],
        ),
      ),
    );
  }
}