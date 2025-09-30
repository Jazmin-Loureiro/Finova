import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/user_widget.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/user_form_screen.dart';
import '../widgets/confirm_dialog_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';
import 'login_screen.dart'; // 👈 import directo

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>?> userFuture;
  
    bool _isDeleting = false; // 👈 flag para mostrar loading al eliminar

  @override
  void initState() {
    super.initState();
    userFuture = api.getUser();
  }

  void _refreshUser() {
    setState(() {
      userFuture = Future.value(null); // Limpia datos → muestra "Actualizando..."
    });
    // En el siguiente frame, pide de nuevo el usuario
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          userFuture = api.getUser();
        });
      }
    });
  }

  Future<void> _deleteAccount() async {
   setState(() {
      _isDeleting = true; // 👈 mostrar loading
    });

    final ok = await api.deleteUser();

    if (!mounted) return;

    if (ok) {
      // 👉 navegar con MaterialPageRoute al login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

        // 👉 después mostrar el success
      showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: "Éxito",
          message: "La cuenta fue eliminada correctamente.",
        ),
      );
    } else {
     setState(() {
        _isDeleting = false; // 👈 volvemos al estado normal si falla
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la cuenta")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      // 👈 pantalla completa con loading
      return const Scaffold(
        body: LoadingWidget(message: "Eliminando cuenta..."),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Usuario'),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: "Actualizando...");
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoadingWidget(message: "Actualizando...");
          }

          final user = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserWidget(user: user),
                const SizedBox(height: 20),

                                // --- Botones en fila ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // --- Editar usuario ---
                      Expanded(
                        child: ElevatedButton(
                          child: const Text("Editar usuario"),
                          onPressed: () async {
                            final formResult =
                                await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFormScreen(user: user),
                              ),
                            );

                            if (formResult != null) {
                              setState(() {
                                userFuture = Future.value(null);
                              });

                              final res = await api.updateUser(
                                name: formResult['name'],
                                email: formResult['email'],
                                password: formResult['password'],
                                passwordConfirmation:
                                    formResult['password_confirmation'],
                                currencyBase: formResult['currencyBase'],
                                balance: formResult['balance'],
                                icon: formResult['icon'],
                              );

                              if (res != null &&
                                  res['user'] != null &&
                                  mounted) {
                                _refreshUser(); // 👈 refresco desde el API
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // --- Eliminar cuenta ---
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Eliminar cuenta"),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const ConfirmDialogWidget(
                                title: "Eliminar cuenta",
                                message:
                                    "¿Seguro que querés eliminar tu cuenta? Esta acción no se puede deshacer.",
                                confirmText: "Eliminar",
                                cancelText: "Cancelar",
                                confirmColor: Colors.red,
                              ),
                            );

                            if (confirmed == true) {
                              _deleteAccount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBarWidget.bottomAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: NavigationBarWidget.fab(context),
    );
  }
}
