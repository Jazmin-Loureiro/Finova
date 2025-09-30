import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';

import '../widgets/confirm_dialog_widget.dart'; 
import '../widgets/success_dialog_widget.dart';
import '../services/api_service.dart';
import '../models/currency.dart';
import '../widgets/user_avatar_widget.dart';

class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserFormScreen({super.key, required this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  Currency? selectedCurrency;
  File? newIcon;
  String? selectedAvatarSeed; // 👈 nuevo

  List<Currency> currencies = [];
  bool isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);
    passwordController = TextEditingController();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    try {
      final data = await ApiService().getCurrencies();
      setState(() {
        currencies = data;
        if (currencies.isNotEmpty) {
          selectedCurrency = currencies.firstWhere(
            (c) => c.id == widget.user['currency_id'],
            orElse: () => currencies[0],
          );
        }
        isLoadingCurrencies = false;
      });
    } catch (_) {
      setState(() => isLoadingCurrencies = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        newIcon = File(result.files.single.path!);
        selectedAvatarSeed = null; // 👈 limpiamos avatar si subió foto
      });
    }
  }

  void _showAvatarPicker() async {
    final base = emailController.text.isNotEmpty ? emailController.text : 'default';
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
        newIcon = null; // limpiamos si eligió avatar
      });
    }
  }

  void _submitForm() {
  if (!_formKey.currentState!.validate()) return;

  dynamic iconValue;
  if (newIcon != null) {
    iconValue = newIcon; // File
  } else if (selectedAvatarSeed != null) {
    iconValue = selectedAvatarSeed; // String
  }

    Navigator.pop(context, {
      'name': nameController.text,
      'email': emailController.text,
      'password': passwordController.text.isNotEmpty ? passwordController.text : null,
      'password_confirmation': passwordController.text.isNotEmpty ? passwordController.text : null,
      'currencyBase': selectedCurrency?.id, // ✅ ahora devuelve el ID correcto
      'icon':  iconValue, // 👈 unificado en un solo campo
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                UserAvatarWidget(
                  iconFile: newIcon,
                  avatarSeed: selectedAvatarSeed ?? widget.user['icon'],
                  radius: 50,
                  onTap: () {
                    showModalBottomSheet<String>(
                      context: context,
                      builder: (_) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text("Subir desde galería"),
                                onTap: () {
                                  Navigator.pop(context, "gallery");
                                  _pickFile();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.auto_awesome),
                                title: const Text("Elegir avatar generado"),
                                onTap: () {
                                  Navigator.pop(context, "avatar");
                                  _showAvatarPicker();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration("Nombre"),
                  validator: (v) => v == null || v.isEmpty ? "Ingrese un nombre" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration("Email"),
                  validator: (v) => v == null || !v.contains('@') ? "Email inválido" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("Nueva contraseña (opcional)"),
                ),
                const SizedBox(height: 12),
                isLoadingCurrencies
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<Currency>(
                        value: selectedCurrency,
                        decoration: _inputDecoration("Moneda base"),
                        items: currencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.symbol} ${c.code} - ${c.name}'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedCurrency = v),
                      ),
                const SizedBox(height: 12),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => ConfirmDialogWidget(
                          title: "Guardar cambios",
                          message: "¿Querés guardar los cambios del perfil?",
                          confirmText: "Guardar",
                          cancelText: "Revisar",
                          confirmColor: Theme.of(context).colorScheme.primary,
                        ),
                      );

                      if (confirmed == true) {
                        final success = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const SuccessDialogWidget(
                            title: "¡Éxito!",
                            message: "Los cambios se guardaron correctamente.",
                          ),
                        );

                        if (success == true) {
                          _submitForm();
                        }
                      }
                    },
                    child: const Text("Guardar cambios"),
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
