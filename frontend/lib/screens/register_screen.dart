import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String name = '', email = '', password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre'),
              onChanged: (val) => name = val,
              validator: (val) => val == null || val.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => email = val,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Obligatorio';
                if (!val.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              onChanged: (val) => password = val,
              validator: (val) => val == null || val.isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Registrar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registrando...')));
                  final res = await api.register(name, email, password);

                  if (res?['token'] != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res?['message'] ?? 'Error')),
                    );
                  }
                }
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: const Text('Ya tienes cuenta? Ingresar'),
            ),
          ]),
        ),
      ),
    );
  }
}
