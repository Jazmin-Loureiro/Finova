import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/user_widget.dart';
import '../screens/user_form_screen.dart';
import '../widgets/confirm_dialog_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/custom_scaffold.dart'; // 👈 agregado
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>?> userFuture;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    userFuture = api.getUser();
  }

  void _refreshUser() {
    setState(() {
      userFuture = Future.value(null);
    });
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          userFuture = api.getUser();
        });
      }
    });
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    final ok = await api.deleteUser();

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: "Éxito",
          message: "La cuenta fue dada de baja correctamente.",
        ),
      );
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la cuenta")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return const Scaffold(
        body: LoadingWidget(message: "Eliminando cuenta..."),
      );
    }

    return CustomScaffold(
      title: 'Usuario',
      currentRoute: '/user',
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
                              setState(() => userFuture = Future.value(null));
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
                                _refreshUser();
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
                          child: const Text("Dar de baja"),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const ConfirmDialogWidget(
                                title: "Dar de baja cuenta",
                                message:
                                    "¿Seguro que querés dar de baja tu cuenta? Podrás reactivarla más adelante.",
                                confirmText: "Dar de baja",
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
    );
  }
}
