import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/casa_widget.dart';
import '../widgets/navigation_bar_widget.dart'; 
import '../widgets/home_info_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/success_dialog_widget.dart'; // 👈 importa tu diálogo

class HomeScreen extends StatefulWidget {
  final bool showSuccessDialog; // 👈 parámetro opcional

  const HomeScreen({super.key, this.showSuccessDialog = false}); // 👈 por defecto no muestra

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();

    if (widget.showSuccessDialog) {
      // 🔹 Mostrar el diálogo apenas la pantalla se pinte
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      // 👇 quitamos Colors.transparent para que no aparezca el “negro” detrás del FAB/notch
      appBar: CustomAppBar(
        title: 'Inicio',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          const CasaWidget(), // 👈 ocupa todo el fondo dinámico
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
      bottomNavigationBar: NavigationBarWidget.bottomAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: NavigationBarWidget.fab(context),
    );
  }
}
