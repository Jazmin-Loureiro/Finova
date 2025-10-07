import 'package:flutter/material.dart';
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Inicio',
      currentRoute: 'inicio',
      extendBody: true,
      extendBodyBehindAppBar: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: logout,
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
    );
  }
}
