import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../models/currency.dart';
import '../widgets/currency_text_field.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController balanceController = TextEditingController();

  String name = '', email = '', password = '';
  String balanceStr = '';
  String currencyBase = '';
  File? icon;

  List<Currency> currencyBases = [];
  bool isLoadingCurrencies = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> pickIcon() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => icon = File(pickedFile.path));
    }
  }

  Future<void> fetchCurrencies() async {
    try {
      final data = await api.getCurrenciesList(); // List<Currency>
      setState(() {
        currencyBases = data;
        if (currencyBases.isNotEmpty) {
          currencyBase = currencyBases.first.code; // default
        }
        isLoadingCurrencies = false;
      });
    } catch (_) {
      setState(() => isLoadingCurrencies = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las monedas')),
      );
    }
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final double balance = double.tryParse(
            balanceStr.replaceAll(RegExp('[^0-9.]'), '')) ??
        0;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrando...')),
    );

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
              'Registro exitoso. Verifica tu email antes de iniciar sesión.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
                // Imagen de perfil
                GestureDetector(
                  onTap: pickIcon,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: icon != null ? FileImage(icon!) : null,
                    child: icon == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Campos de texto
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre',border: OutlineInputBorder()),
                  onChanged: (val) => name = val,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email',border: OutlineInputBorder()),
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
                  decoration: const InputDecoration(labelText: 'Contraseña',border: OutlineInputBorder()),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Confirmar Contraseña',border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Obligatorio';
                    if (val != password) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown de monedas
                isLoadingCurrencies
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<Currency>(
                        value: currencyBases.firstWhere(
                            (c) => c.code == currencyBase,
                            orElse: () => currencyBases.first),
                        items: currencyBases
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.symbol} ${c.code} - ${c.name}'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => currencyBase = val.code);
                        },
                        decoration:
                            const InputDecoration(labelText: 'Moneda Base', border: OutlineInputBorder()),
                        validator: (val) =>
                            val == null ? 'Obligatorio' : null,
                      ),
                const SizedBox(height: 16),

                // Saldo inicial
                CurrencyTextField(
                  controller: balanceController,
                  currencies: currencyBases,
                  selectedCurrency: currencyBase,
                  label: 'Saldo Inicial (opcional)',
                  onChanged: (val) => balanceStr = val,
                ),
                const SizedBox(height: 16),

                // Botón Registrar
                ElevatedButton(
                  onPressed: registerUser,
                  child: const Text('Registrar'),
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
