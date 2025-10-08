import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';
import 'request_reactivation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isLoading = false;
  bool showResend = false;

  /// 🔹 Inicia sesión
  void loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      showResend = false;
    });

    try {
      final res = await api.login(email, password);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (res == null) {
        await _showError('No se pudo conectar con el servidor.');
        return;
      }

      // ✅ Login exitoso
      if (res['token'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(showSuccessDialog: true),
          ),
        );
        return;
      }

      final message = (res['message'] ?? 'Error al iniciar sesión').toLowerCase();

      // 🟣 Caso: usuario no existe → ofrecer registrarse
      if (message.contains('no existe')) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialogWidget(
            title: 'Error',
            message: 'No existe una cuenta registrada con ese correo. Podés crear una nueva cuenta en Finova.',
            buttonText: 'Registrarme',
          ),
        ).then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        });
        return;
      }

      // 🔴 Caso: correo o contraseña incorrectos
      if (message.contains('correo o contraseña')) {
        await _showError('Correo o contraseña incorrectos. Verificá los datos e intentá nuevamente.');
        return;
      }

      // 🟡 Caso: cuenta dada de baja
      if (message.contains('dada de baja')) {
        await _showError('Tu cuenta fue dada de baja. Podés reactivarla desde el botón de abajo.');
        return;
      }

      // 📬 Caso: falta verificación → mostrar botón reenviar
      setState(() {
        showResend = message.contains('verificar');
      });

      await _showError(res['message'] ?? 'Error al iniciar sesión.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      await _showError('Ocurrió un error al iniciar sesión: $e');
    }
  }

  /// 🔹 Muestra diálogo de error genérico reutilizando tu widget
  Future<void> _showError(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialogWidget(
        title: 'Error',
        message: message,
        buttonText: 'Aceptar',
      ),
    );
  }

  /// 🔹 Reenvía el correo de verificación (con o sin token)
  Future<void> resendEmail() async {
    setState(() => isLoading = true);

    final tokenExists = await api.hasToken();
    Map<String, dynamic>? res;

    if (tokenExists) {
      res = await api.resendVerification();
    } else {
      res = await api.resendVerificationByEmail(email);
    }

    setState(() => isLoading = false);

    final message = res?['message'] ?? 'Te enviamos un nuevo correo de verificación.';

    await showDialog(
      context: context,
      builder: (_) => SuccessDialogWidget(
        title: 'Correo reenviado',
        message: message,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 🔹 UI principal
  @override
  Widget build(BuildContext context) {
    final violet = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: isLoading
          ? const LoadingWidget(message: "Ingresando...")
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => email = val,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Obligatorio';
                        if (!val.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onChanged: (val) => password = val,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loginUser,
                      child: const Text('Ingresar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('¿No tienes cuenta? Registrate'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestReactivationScreen(),
                          ),
                        );
                      },
                      child: const Text('¿Tu cuenta fue dada de baja? Reactívala'),
                    ),
                    if (showResend)
                      TextButton(
                        onPressed: resendEmail,
                        child: Text(
                          '¿No recibiste el correo de verificación?',
                          style: TextStyle(
                            color: violet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
