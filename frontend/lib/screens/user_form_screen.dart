import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/confirm_dialog_widget.dart'; 
import '../widgets/success_dialog_widget.dart';

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
  String? selectedCurrency;
  File? newIcon;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);
    passwordController = TextEditingController();
    selectedCurrency = widget.user['currencyBase'];
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => newIcon = File(result.files.single.path!));
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'name': nameController.text,
      'email': emailController.text,
      'password': passwordController.text.isNotEmpty ? passwordController.text : null,
      'password_confirmation': passwordController.text.isNotEmpty ? passwordController.text : null,
      'currencyBase': selectedCurrency,
      'icon': newIcon,
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
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: _inputDecoration("Moneda base"),
                  items: ["ARG", "USD", "EUR"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCurrency = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const Icon(Icons.image, color: Colors.indigo),
                  title: const Text("Foto de perfil"),
                  subtitle: newIcon != null
                      ? Text(newIcon!.path.split('/').last)
                      : const Text("No seleccionada"),
                  trailing: IconButton(
                    icon: const Icon(Icons.upload),
                    onPressed: _pickFile,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final confirmed = await showDialog<bool>(
                        context: context,
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
