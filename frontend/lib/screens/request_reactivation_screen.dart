import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/loading_widget.dart';

class RequestReactivationScreen extends StatefulWidget {
  const RequestReactivationScreen({super.key});

  @override
  State<RequestReactivationScreen> createState() => _RequestReactivationScreenState();
}

class _RequestReactivationScreenState extends State<RequestReactivationScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool isLoading = false;

  Future<void> sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final res = await api.requestReactivation(email);

    setState(() => isLoading = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialogWidget(
        title: res['error'] == null ? 'Solicitud enviada' : 'Error',
        message: res['message'] ?? res['error'] ?? 'Error inesperado',
        buttonText: 'Aceptar',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactivar cuenta'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: isLoading
          ? const LoadingWidget(message: 'Enviando solicitud...')
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.12),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20), // 👈 más arriba
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
            
                      Text(
                        "¿Tu cuenta fue dada de baja?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Podés solicitar la reactivación fácilmente. Ingresá tu email y te contactaremos.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 30),

                    
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surface.withOpacity(0.85)
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                onChanged: (val) => email = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Obligatorio';
                                  if (!val.contains('@')) return 'Email inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: sendRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Solicitar reactivación',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
            ),
    );
  }
}
