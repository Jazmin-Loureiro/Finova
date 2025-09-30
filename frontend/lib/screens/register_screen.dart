import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/currency.dart';
import '../widgets/currency_text_field.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';



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
  Currency? currencyBase; // CAMBIO: ahora es Currency? en vez de String
   File? icon;

  List<Currency> currencyBases = [];
  bool isLoadingCurrencies = true;
  bool isLoading = false; // 👈 nuevo estado de loading

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
      final data = await api.getCurrencies(); // List<Currency>
      setState(() {
        currencyBases = data; // 👈 Guardamos todas las monedas
        if (data.isNotEmpty) {
          currencyBase = data.first; // CAMBIO: seleccionamos la primera moneda por defecto
        }
        isLoadingCurrencies = false;
      });
    } catch (_) {
      setState(() => isLoadingCurrencies = false);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SuccessDialogWidget(
          title: 'Error',
          message: 'Error al cargar las monedas.',
          buttonText: 'Aceptar',
        ),
      );
    }
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final double balance = double.tryParse(
            balanceStr.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
            
    setState(() => isLoading = true); // 👈 mostramos loading

    try {
      await api.register(
        name,
        email,
        password,
        currencyBase: currencyBase!, // CAMBIO: ahora pasamos el objeto Currency
        balance: balance,
        icon: icon,
      );

      if (!mounted) return;

      setState(() => isLoading = false); // 👈 quitamos loading

      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SuccessDialogWidget(
          title: 'Registro exitoso',
          message:
              'Te enviamos un email. Debes confirmar tu cuenta antes de poder iniciar sesión.',
          buttonText: 'Aceptar',
        ),
      );

      if (result == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          message: 'Ocurrió un error en el registro: $e',
          buttonText: 'Aceptar',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: isLoading
          ? const LoadingWidget(message: "Registrando usuario...")
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Nombre', border: OutlineInputBorder()),
                        onChanged: (val) => name = val,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
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
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            border: OutlineInputBorder()),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Obligatorio';
                          if (val != password) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      isLoadingCurrencies
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<Currency>(
                          value: currencyBase ?? (currencyBases.isNotEmpty ? currencyBases.first : null), // CAMBIO: valor inicial como Currency
                          items: currencyBases
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.symbol} ${c.code} - ${c.name}'),
                                  ))
                              .toList(),
                          onChanged: (Currency? val) {
                            if (val != null) setState(() => currencyBase = val);
                          },
                          decoration: const InputDecoration(
                              labelText: 'Moneda Base',
                              border: OutlineInputBorder()),
                          validator: (val) => 
                          val == null ? 'Obligatorio' : null,
                        ),
                      const SizedBox(height: 16),

                      CurrencyTextField(
                        controller: balanceController,
                        currencies: currencyBases,
                        selectedCurrency: currencyBase,
                        label: 'Saldo Inicial (opcional)',
                        onChanged: (val) => balanceStr = val,
                      ),
                      const SizedBox(height: 16),

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
