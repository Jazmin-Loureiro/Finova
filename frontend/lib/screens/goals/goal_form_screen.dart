import 'package:flutter/material.dart';
import 'package:frontend/widgets/buttons/button_delete.dart';
import 'package:frontend/widgets/buttons/button_save.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:frontend/widgets/success_dialog_widget.dart';
import '../../services/api_service.dart';
import '../../models/currency.dart';
import '../../models/goal.dart';
import '../../widgets/currency_text_field.dart';

class GoalFormScreen extends StatefulWidget {
    final Goal? goal; // Meta opcional para edición

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  String? _name;
  DateTime? _dateLimit;
  Currency? selectedCurrency;
  bool _isLoading = true;
  bool isSaving = false;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _dateLimit = widget.goal!.dateLimit;
      selectedCurrency = widget.goal!.currency;
      _amountController.text = widget.goal!.targetAmount.toString();
    }
      _loadCurrencies();
  }

  List<Currency> currencies = [];

  Future<void> _loadCurrencies() async {
  try {
    final data = await api.getCurrencies();
    setState(() {
      currencies = data;
      if (widget.goal != null) {
        // buscamos la moneda que coincide con la meta
        selectedCurrency = currencies.firstWhere(
          (c) => c.id == widget.goal!.currency?.id,
          orElse: () => currencies.first,
        );
      } else if (currencies.isNotEmpty) {
        selectedCurrency = currencies.first;
      }
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Error cargando monedas: $e');
  }
}


  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final parsedAmount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final data = {
        'name': _name,
        'target_amount': parsedAmount,
        'currency_id': selectedCurrency?.id,
        'date_limit': _dateLimit?.toIso8601String().split('T').first, 
      };
      setState(() => isSaving = true);
      try {
        if (widget.goal != null) {
          await api.editGoal(widget.goal!.id, data);
        } else {
          await api.createGoal(data);
        }
        setState(() => isSaving = false);
          await showDialog(
            context: context,
            builder: (_) => SuccessDialogWidget(
              title: "Éxito",
              message:
                  "${widget.goal != null ? "Meta actualizada" : "Meta creada"} con éxito.",
        ),
      );
        Navigator.pop(context,true);
      } catch (e) {
        debugPrint('Error al crear meta: $e');
      }
    }
  }

  Future<void> _deleteGoal() async {
    if (widget.goal == null) return;
    try {
      await api.deleteGoal(widget.goal!.id);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error al eliminar meta: $e');
    }
  }

  @override
Widget build(BuildContext context) {
      if (_isLoading) return const Scaffold(body: Center(child: LoadingWidget()));
  return CustomScaffold(
    title: widget.goal != null ? 'Editar Meta' : 'Crear Meta',
    currentRoute: 'goal_form',
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
                  initialValue: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    counterText: '',
                  ),
                  maxLength: 30,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                  onSaved: (val) => _name = val,
                ),

                const SizedBox(height: 16),

                // Moneda
                widget.goal != null && selectedCurrency != null
                    ? TextFormField(
                        readOnly: true,
                        initialValue:
                            '${selectedCurrency!.name} (${selectedCurrency!.code})',
                        decoration: const InputDecoration(
                          labelText: 'Moneda',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<Currency>(
                        decoration: const InputDecoration(
                          labelText: 'Moneda',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        value: selectedCurrency,
                        items: currencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.name} (${c.code})'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCurrency = value),
                        validator: (value) =>
                            value == null ? 'Seleccione una moneda' : null,
                      ),

                const SizedBox(height: 16),

                // Monto objetivo
                CurrencyTextField(
                  controller: _amountController,
                  currencies: selectedCurrency != null
                      ? [selectedCurrency!]
                      : currencies,
                  selectedCurrency: selectedCurrency,
                  label: 'Monto Objetivo',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingrese un monto';
                    }
                    final parsed =
                        double.tryParse(val.replaceAll(',', '.')) ?? 0;
                    if (parsed <= 0) return 'Ingrese un monto válido';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Fecha límite
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _dateLimit != null
                        ? '${_dateLimit!.day.toString().padLeft(2, '0')}/${_dateLimit!.month.toString().padLeft(2, '0')}/${_dateLimit!.year}'
                        : '',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fecha Límite',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (_) =>
                      _dateLimit == null ? 'Seleccione una fecha' : null,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateLimit ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 20),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateLimit = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),

                ButtonSave(
                  title: "Guardar Meta",
                  message: "¿Seguro que quieres guardar esta meta?",
                  onConfirm: _submitForm,
                  formKey: _formKey,
                ),
                const SizedBox(height: 12),
                if (widget.goal != null)
                  ButtonDelete(
                    title: "Eliminar Meta",
                    message: widget.goal!.isChallengeGoal
                        ? "⚠️ Esta meta pertenece a un desafío activo.\n\n"
                          "Si la eliminás, el desafío será marcado como fallido y perderás su progreso.\n\n"
                          "¿Querés continuar?"
                        : "¿Seguro que querés deshabilitar esta meta?",
                    onConfirm: _deleteGoal,
                  ),
              ],
            ),
          ),
        ),

        // Overlay de guardado
        if (isSaving)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: LoadingWidget(message: 'Guardando meta...'),
              ),
            ),
          ),
      ],
    ),
  );
}
}
