import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import '../services/api_service.dart';
import '../widgets/dialogs/success_dialog_widget.dart';
import '../widgets/loading_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String password = '';
  String confirmPassword = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final res = await api.resetPassword(
      email: widget.email,
      token: widget.token,
      password: password,
      passwordConfirmation: confirmPassword,
    );
    setState(() => isLoading = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialogWidget(
        title: res['success'] ? 'Exito!' : 'Error',
        message: res['message'] ?? res['error'] ?? 'Error inesperado',
        buttonText: 'Aceptar',
        isFailure: res['success'] != true,
      ),
    );

    if (res['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 3,
      ),
      body: isLoading
          ? const LoadingWidget(message: "Procesando...")
          : Container(
             width: double.infinity,
              height: double.infinity,  
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.12),
                    cs.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TITULO PRINCIPAL
                    Text(
                      "Restablecé tu contraseña",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white.withOpacity(0.95)
                            : cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Ingresá tu nueva contraseña para finalizar el proceso.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // CARD DEL FORM 🍞
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surface.withOpacity(0.9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      // FORM
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Nueva contraseña
                            TextFormField(
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Nueva contraseña",
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(12)),
                                ),
                              ),
                              onChanged: (val) => password = val,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Ingresá una contraseña';
                                }
                                if (val.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirmar contraseña
                            TextFormField(
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Confirmar contraseña",
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(12)),
                                ),
                              ),
                              onChanged: (val) => confirmPassword = val,
                              validator: (val) {
                                if (val != password) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Botón
                            ElevatedButton(
                              onPressed: submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                minimumSize:
                                    const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Restablecer contraseña",
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }
}
