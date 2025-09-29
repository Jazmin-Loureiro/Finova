import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isLoading = false; // 👈 nuevo estado

  void loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true); // 👈 mostramos loading

    try {
      final res = await api.login(email, password);

      if (!mounted) return;

      setState(() => isLoading = false); // 👈 quitamos loading

      if (res?['token'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(showSuccessDialog: true),
          ),
        );
      } else {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialogWidget(
            title: 'Error',
            message: res?['message'] ?? 'Error al iniciar sesión',
            buttonText: 'Aceptar',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialogWidget(
          title: 'Error',
          message: 'Ocurrió un error al iniciar sesión: $e',
          buttonText: 'Aceptar',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          labelText: 'Email', border: OutlineInputBorder()),
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
                          labelText: 'Contraseña', border: OutlineInputBorder()),
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
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text('No tienes cuenta? Registrate'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
