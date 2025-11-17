import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:multiavatar/multiavatar.dart';
import '../services/api_service.dart';
import '../models/currency.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/custom_scaffold.dart'; // 👈 reemplaza AppBar y NavBar

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
  String? selectedAvatarSeed;

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
        selectedAvatarSeed = null;
      });
    }
  }

  bool _isRotating = false;

  List<String> _currentSeeds = [];

  void _showAvatarPicker() async {
    void generateSeeds() {
      final base = emailController.text.isNotEmpty
          ? emailController.text
          : 'default';

      _currentSeeds = List.generate(
        6,
        (i) => "$base-${DateTime.now().microsecondsSinceEpoch}-$i",
      );
    }

    generateSeeds();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setModalState(() {
                        _isRotating = true;      // activar animación
                        generateSeeds();         // refrescar avatares
                      });

                      // detener animación después de 600ms
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) {
                          setModalState(() => _isRotating = false);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícono refrescar con animación
                          AnimatedRotation(
                            turns: _isRotating ? 1 : 0,
                            duration: const Duration(milliseconds: 550),
                            curve: Curves.easeOut,
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Regenerar avatares",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 🟣 GRID
                SizedBox(
                  height: 360,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _currentSeeds.length,
                    itemBuilder: (context, index) {
                      final seed = _currentSeeds[index];
                      final svgCode = multiavatar(seed);

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, seed),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          child: SvgPicture.string(svgCode),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedAvatarSeed = selected;
        newIcon = null;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    dynamic iconValue;
    if (newIcon != null) {
      iconValue = newIcon;
    } else if (selectedAvatarSeed != null) {
      iconValue = selectedAvatarSeed;
    }

    Navigator.pop(context, {
      'name': nameController.text,
      'email': emailController.text,
      'password':
          passwordController.text.isNotEmpty ? passwordController.text : null,
      'password_confirmation': passwordController.text.isNotEmpty
          ? passwordController.text
          : null,
      'currencyBase': selectedCurrency?.id,
      'icon': iconValue,
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Editar Usuario",
      currentRoute: "/user/form",
      showNavigation: false,
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
                  validator: (v) =>
                      v == null || v.isEmpty ? "Ingrese un nombre" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration("Email"),
                  validator: (v) =>
                      v == null || !v.contains('@') ? "Email inválido" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                      _inputDecoration("Nueva contraseña (opcional)"),
                ),
                const SizedBox(height: 12),
                isLoadingCurrencies
                    ? const CircularProgressIndicator()
                    :  BottomSheetPickerField<Currency>(
                          label: 'Tipo de moneda',
                          items: currencies,
                          itemLabel: (c) => '${c.code} - ${c.name}',
                          itemIcon: (c) => CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text( c.symbol,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary,fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            initialValue: selectedCurrency,
                            onChanged: (value) => setState(() => selectedCurrency = value),
                            validator: (value) => value == null ? 'Debes seleccionar una moneda' : null,
                        ),
                const SizedBox(height: 15),
              
                 ButtonSave(
                    title: "Guardar actualizacion",
                    message: "¿Seguro que quieres guardar los datos de tu perfil?",
                    onConfirm: _submitForm,
                    formKey: _formKey,
                    label: "Guardar Cambios",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
