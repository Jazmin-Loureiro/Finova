import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';
import 'package:animate_do/animate_do.dart';


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
  Currency? currencyBase;
  File? icon;
  String? selectedAvatarSeed;
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
        selectedAvatarSeed = null;
      });
    }
  }

  Future<void> fetchCurrencies() async {
    try {
      final data = await api.getCurrencies();
      setState(() {
        currencyBases = data;
        if (data.isNotEmpty) {
          currencyBase = data.first;
        }
        isLoading = false;
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
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text("Subir desde galería"),
                  onTap: () => Navigator.pop(context, "gallery"),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text("Elegir avatar generado"),
                  onTap: () => Navigator.pop(context, "avatar"),
                ),
              ],
            ),
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
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                backgroundColor: Colors.grey[100],
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
        icon = null;
      });
    }
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final double balance = double.tryParse(
            balanceStr.replaceAll(RegExp('[^0-9.]'), '')) ??
        0;

    setState(() => isLoading = true);

    try {
      await api.register(
        name,
        email,
        password,
        currencyBase: currencyBase!,
        balance: balance,
        icon: icon,
        avatarSeed: selectedAvatarSeed,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SuccessDialogWidget(
          title: '¡Registro exitoso!',
          message:
              'Te enviamos un email para confirmar tu cuenta antes de iniciar sesión.',
          buttonText: 'Aceptar',
        ),
      );

      if (mounted) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: isLoading
          ? const LoadingWidget(message: "Registrando usuario...")
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.08),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface.withOpacity(0.85)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                "¡Creá tu cuenta!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                "Gestioná tus finanzas, ahorrá y cumplí tus metas con Finova.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            FadeIn(
                              duration: const Duration(milliseconds: 900),
                              child: UserAvatarWidget(
                                iconFile: icon,
                                avatarSeed: selectedAvatarSeed,
                                radius: 55,
                                onTap: _showAvatarOptions,
                              ),
                            ),
                            const SizedBox(height: 24),

                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                onChanged: (val) => name = val,
                                validator: (val) =>
                                    val == null || val.isEmpty
                                        ? 'Obligatorio'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            FadeInUp(
                              delay: const Duration(milliseconds: 500),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (val) => email = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Obligatorio';
                                  }
                                  if (!val.contains('@')) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            FadeInUp(
                              delay: const Duration(milliseconds: 600),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                obscureText: true,
                                onChanged: (val) => password = val,
                                validator: (val) =>
                                    val == null || val.isEmpty
                                        ? 'Obligatorio'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                             FadeInUp(
                                    delay:
                                        const Duration(milliseconds: 700),
                                    child: DropdownButtonFormField<Currency>(
                                      value: currencyBase,
                                      items: currencyBases
                                          .map((c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(
                                                    '${c.symbol} ${c.code} - ${c.name}'),
                                              ))
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => currencyBase = val),
                                      decoration: const InputDecoration(
                                        labelText: 'Moneda Base',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                        ),
                                      ),
                                      validator: (val) => val == null
                                          ? 'Obligatorio'
                                          : null,
                                    ),
                                  ),
                            const SizedBox(height: 16),

                            FadeInUp(
                              delay: const Duration(milliseconds: 800),
                              child: CurrencyTextField(
                                controller: balanceController,
                                currencies: currencyBases,
                                selectedCurrency: currencyBase,
                                label: 'Saldo Inicial (opcional)',
                                onChanged: (val) => balanceStr = val,
                              ),
                            ),
                            const SizedBox(height: 24),

                            BounceInUp(
                              duration: const Duration(milliseconds: 900),
                              child: ElevatedButton(
                                onPressed: registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                ),
                                child: Text(
                                  'Registrarme',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            FadeInUp(
                              delay: const Duration(milliseconds: 1000),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  '¿Ya tenés cuenta? Iniciá sesión',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
