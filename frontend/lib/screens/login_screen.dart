import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:animate_do/animate_do.dart';
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
  bool obscureText = true;

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

      if (res['token'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(showSuccessDialog: true),
          ),
        );
        return;
      }

      final message = (res['message'] ?? '').toLowerCase();

      if (message.contains('no existe')) {
        await _showError('No existe una cuenta registrada con ese correo.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        return;
      }

      if (message.contains('correo o contraseña')) {
        await _showError('Correo o contraseña incorrectos. Verificá los datos e intentá nuevamente.');
        return;
      }

      if (message.contains('dada de baja')) {
        await _showError('Tu cuenta fue dada de baja. Podés reactivarla desde el botón de abajo.');
        return;
      }

      setState(() => showResend = message.contains('verificar'));
      await _showError(res['message'] ?? 'Error al iniciar sesión.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      await _showError('Ocurrió un error al iniciar sesión: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: isLoading
          ? const LoadingWidget(message: "Ingresando...") :
        Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeInUp(
              duration: const Duration(milliseconds: 700),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ 
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surface.withOpacity(0.8)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                  
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                FadeInDown(
                                  duration: const Duration(milliseconds: 800),
                                  child: SvgPicture.asset(
                                    'assets/icon.svg',
                                    height: 100,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 800),
                                  child: Text(
                                    "¡Hola de nuevo!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      height: 1.1,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.95)
                                          : colorScheme.onSurface
                                              .withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 200),
                                  child: Text(
                                    "Inicia sesión para continuar.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 400),
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (val) => email = val,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Obligatorio';
                                      }
                                      if (!val.contains('@')) {
                                        return 'Email inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 600),
                                  child: TextFormField(
                                    obscureText: obscureText,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(() =>
                                            obscureText = !obscureText),
                                      ),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                    ),
                                    onChanged: (val) => password = val,
                                    validator: (val) => val == null ||
                                            val.isEmpty
                                        ? 'Obligatorio'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 800),
                                  child: ElevatedButton(
                                    onPressed: loginUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                    ),
                                    child: Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 1000),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '¿No tienes cuenta? Registrate',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                ),
                                Divider(color: Colors.grey[400]),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 12,
                                        runSpacing: -8,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              // TODO: recuperar contraseña
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 30),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Recuperar contraseña',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const RequestReactivationScreen(),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 30),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Reactivar cuenta',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (showResend)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: TextButton(
                                            onPressed: () async {
                                              await resendEmail();
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 30),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              '¿No recibiste el correo de verificación?',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
