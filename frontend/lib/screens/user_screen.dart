import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/user_widget.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/user_form_screen.dart';
import '../widgets/confirm_dialog_widget.dart';
import '../widgets/loading_widget.dart'; // 👈 nuevo import

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>?> userFuture;

  @override
  void initState() {
    super.initState();
    userFuture = api.getUser(); // 👈 cargo datos iniciales
  }

  void _refreshUser() {
    setState(() {
      userFuture = api.getUser(); // 👈 refresco desde ApiService
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Usuario'),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: "Actualizando...");
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const LoadingWidget(message: "Actualizando...");
          }

          final user = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserWidget(user: user),
                const SizedBox(height: 20),

                // --- Botones en fila con padding ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
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
                              final ok = await api.deleteUser();
                              if (ok && context.mounted) {
                                Navigator.pushReplacementNamed(
                                    context, "/login");
                              }
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
