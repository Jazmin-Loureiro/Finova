import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/currency.dart';
import '../widgets/currency_text_field.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/user_avatar_widget.dart';

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
   File? icon; // archivo de imagen
  String? selectedAvatarSeed; // semilla de avatar generado

  List<Currency> currencyBases = [];
  bool isLoadingCurrencies = true;
  bool isLoading = false;

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
      setState(() {
        icon = File(pickedFile.path);
        selectedAvatarSeed = null; // si sube imagen, limpiamos avatar
      });
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

  void _showAvatarOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Subir desde galería"),
                onTap: () => Navigator.pop(context, "gallery"),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text("Elegir avatar generado"),
                onTap: () => Navigator.pop(context, "avatar"),
              ),
            ],
          ),
        );
      },
    );

    if (choice == "gallery") {
      pickIcon();
    } else if (choice == "avatar") {
      _showAvatarPicker();
    }
  }

  void _showAvatarPicker() async {
    final base = email.isNotEmpty ? email : 'default';
    final seeds = List.generate(
      6,
      (i) => "$base-${DateTime.now().microsecondsSinceEpoch}-$i",
    );

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: seeds.length,
          itemBuilder: (context, index) {
            final svgCode = multiavatar(seeds[index]);
            return GestureDetector(
              onTap: () => Navigator.pop(context, seeds[index]),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                child: SvgPicture.string(svgCode),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedAvatarSeed = selected;
        icon = null; // limpiamos si eligió avatar
      });
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
        avatarSeed: selectedAvatarSeed, // 👈 ahora lo mandamos
      );

      if (!mounted) return;

      setState(() => isLoading = false);

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
                      UserAvatarWidget(
                        iconFile: icon,
                        avatarSeed: selectedAvatarSeed,
                        radius: 60,
                        onTap: _showAvatarOptions,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder()),
                        onChanged: (val) => name = val,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder()),
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
                            labelText: 'Contraseña',
                            border: OutlineInputBorder()),
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
                          if (val != password) {
                            return 'Las contraseñas no coinciden';
                          }
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
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
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
