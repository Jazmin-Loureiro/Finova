import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String name = '', email = '', password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Nombre'),
              onChanged: (val) => name = val,
              validator: (val) => val!.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (val) => email = val,
              validator: (val) => val!.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              onChanged: (val) => password = val,
              validator: (val) => val!.isEmpty ? 'Obligatorio' : null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Registrar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registrando...')));
                  final res = await api.register(name, email, password);

                  if (res['token'] != null) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? 'Error')));
                  }
                }
              },
            ),
          ]),
        ),
      ),
    );
  }
}
