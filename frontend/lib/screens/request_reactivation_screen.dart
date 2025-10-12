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

  void sendRequest() async {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reactivar cuenta')),
      body: isLoading
          ? const LoadingWidget(message: 'Enviando solicitud...')
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
                      child: const Text('Solicitar reactivación'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
