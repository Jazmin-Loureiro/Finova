import 'package:flutter/material.dart';
import 'package:frontend/models/money_maker_type.dart';
import 'package:frontend/widgets/bottom_sheet_pickerField.dart';
import 'package:frontend/widgets/buttons/button_delete.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import '../../services/api_service.dart';
import '../../models/currency.dart';
import '../../models/money_maker.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/success_dialog_widget.dart';
import '../../widgets/color_pickerfield.widget.dart';
import '../../widgets/custom_scaffold.dart';

class MoneyMakerFormScreen extends StatefulWidget {
  final MoneyMaker? moneyMaker;

  const MoneyMakerFormScreen({super.key, this.moneyMaker});

  @override
  State<MoneyMakerFormScreen> createState() => _MoneyMakerFormScreenState();
}

class _MoneyMakerFormScreenState extends State<MoneyMakerFormScreen> {
  final ApiService api = ApiService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  Color? selectedColor;
  int typeSelected = 1;
  bool _isLoading = true;
  bool isSaving = false;
  List<Currency> currencies = [];
  Currency? selectedCurrency;

  List<MoneyMakerType> typeMoneyMaker = [];
  MoneyMakerType? selectedType;

  @override
  void initState() {
    super.initState();
    if (widget.moneyMaker != null) {
      final m = widget.moneyMaker!;
      nameController.text = m.name;
      balanceController.text = m.balance.toString();
      selectedColor = Color(int.parse(m.color.replaceAll('#', '0xFF')));
      selectedType = m.type;
  }
    loadFormData();
  }

  Future<void> loadFormData() async {
    final fetchedCurrencies = await api.getCurrencies();
    final fetchedTypes = await api.getMoneyMakerTypes();
    final userBaseCurrency = await api.getUserCurrency();
    if (!mounted) return;
    setState(() {
      currencies = fetchedCurrencies;
      selectedCurrency = currencies.firstWhere(
        (c) => c.id == userBaseCurrency,
        orElse: () => currencies.first,
      );
      typeMoneyMaker = fetchedTypes;
      _isLoading = false;
    });
  }

  Future<void> saveMoneyMaker() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final isEditing = widget.moneyMaker != null;
    final name = nameController.text.trim();
    final balance = double.tryParse(balanceController.text) ?? 0;
    final colorHex =
        '#${selectedColor!.toARGB32().toRadixString(16).substring(2)}';

    setState(() => isSaving = true);

    dynamic newSource;
    if (isEditing) { newSource = await api.updatePaymentSource( widget.moneyMaker!.id,name,selectedType!.id, colorHex,);
    } else {newSource = await api.addPaymentSource(name, selectedType!.id, balance, selectedCurrency!, colorHex, );}
    setState(() => isSaving = false);

    if (newSource != null) {
      final confirmed = await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: isEditing ? 'Fuente Actualizada' : 'Fuente Agregada',
          message: isEditing
              ? 'La fuente se actualizó exitosamente.'
              : 'La fuente se agregó exitosamente.',
          buttonText: 'Aceptar',
        ),
      );
      if (confirmed && mounted) Navigator.pop(context, newSource);
    } 
  }

  Future<void> _deleteMoneyMaker() async {
  if (widget.moneyMaker == null) return;
  try {
    await api.deleteMoneyMaker(widget.moneyMaker!.id);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => const SuccessDialogWidget(
        title: "Fuente eliminada",
        message: "La fuente fue eliminada exitosamente.",
        buttonText: "Aceptar",
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => SuccessDialogWidget(
        isFailure: true,
        title: "No se pudo eliminar",
        message: e.toString().replaceAll("Exception: ", ""),
      ),
    );
  }
}

  @override
Widget build(BuildContext context) {
  if (_isLoading) return const Scaffold(body: Center(child: LoadingWidget()));

  return CustomScaffold(
    title: widget.moneyMaker != null ? 'Editar Fuente' : 'Agregar Fuente',
    currentRoute: 'money_maker_form',
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Nombre
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la fuente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    counterText: '',
                    ),
                      maxLength: 15,
                  
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El nombre no puede estar vacío';
                    }
                    if (val.trim().length < 3) {
                      return 'Debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

               // Tipo de fuente
                BottomSheetPickerField<MoneyMakerType>(
                  label: 'Tipo de fuente',
                  items: typeMoneyMaker,
                  itemLabel: (t) => t.name,
                  itemIcon: (t) => CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  initialValue: selectedType,
                  onChanged: (value) => setState(() => selectedType = value),
                  validator: (value) =>
                      value == null ? 'Seleccione un tipo de fuente' : null,
                ),

                if (widget.moneyMaker == null) ...[
                  const SizedBox(height: 16),

                  // Tipo de moneda
                BottomSheetPickerField<Currency>(
                    label: 'Tipo de moneda',
                    items: currencies,
                    itemLabel: (c) => '${c.code} - ${c.name}',
                    itemIcon: (c) => CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        c.symbol,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    initialValue: selectedCurrency,
                    onChanged: (value) => setState(() => selectedCurrency = value),
                    validator: (value) =>
                        value == null ? 'Debes seleccionar una moneda' : null,
                  ),
                  const SizedBox(height: 16),

                  // Saldo inicial
                  CurrencyTextField(
                    controller: balanceController,
                    currencies: currencies,
                    selectedCurrency: selectedCurrency,
                    label: 'Saldo inicial (opcional)',
                  ),
                ],

                const SizedBox(height: 16),

                // Selector de color
                ColorPickerField(
                  initialColor: selectedColor,
                  onSaved: (color) => selectedColor = color,
                  validator: (color) =>
                      color == null ? 'Seleccione un color' : null,
                  label: 'Color de la fuente',
                ),

                 const SizedBox(height: 15),

                ButtonSave(
                  title: "Guardar Fuente",
                  message: "¿Seguro que quieres guardar esta fuente?",
                  onConfirm: saveMoneyMaker,
                  formKey: _formKey,
                ),

                const SizedBox(height: 12),

                if (widget.moneyMaker != null)
                  ButtonDelete(
                    title: "Eliminar Fuente",
                    message: "¿Seguro que quieres deshabilitar esta fuente?",
                    onConfirm: _deleteMoneyMaker,
                  ),
                ],
            ),
          ),
        ),

        //Overlay de guardado
        if (isSaving)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: LoadingWidget(message: 'Guardando fuente de dinero...'),
              ),
            ),
          ),
      ],
    ),
  );
}
}
