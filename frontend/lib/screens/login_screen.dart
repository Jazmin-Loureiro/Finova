import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
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
              child: Text('Login'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final res = await api.login(email, password);
                  if (res['token'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login correcto')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
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
