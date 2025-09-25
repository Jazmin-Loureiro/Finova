import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
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
  String currencyBase = 'USD';
  String balanceStr = '';
  File? icon;

  final List<String> currencyBases = ['USD', 'ARG', 'EUR'];
  final ImagePicker _picker = ImagePicker();

  // Función para seleccionar imagen
  Future<void> pickIcon() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        icon = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Selector de imagen
                GestureDetector(
                  onTap: pickIcon,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        icon != null ? FileImage(icon!) : null,
                    child: icon == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (val) => name = val,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obligatorio' : null,
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
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obligatorio' : null,
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Confirmar Contraseña'),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Obligatorio';
                    if (val != password) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: currencyBase,
                  items: currencyBases
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) currencyBase = val;
                  },
                  decoration: const InputDecoration(labelText: 'Moneda Base'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obligatorio' : null,
                ),

                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Saldo Inicial (opcional)'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => balanceStr = val,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  child: const Text('Registrar'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registrando...')),
                      );

                      final double balance = double.tryParse(balanceStr) ?? 0;

                      await api.register(
                      name,
                      email,
                      password,
                      currencyBase: currencyBase,
                      balance: balance,
                      icon: icon, 
                    );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Registro exitoso. Por favor, verifique su email antes de iniciar sesión.'),
                        ),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Ya tienes cuenta? Ingresar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
