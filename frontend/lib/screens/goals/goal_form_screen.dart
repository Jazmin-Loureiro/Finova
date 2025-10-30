import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
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
      
      try {
        if (widget.goal != null) {
          await api.editGoal(widget.goal!.id, data);
        } else {
          await api.createGoal(data);
        }
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
    return CustomScaffold(
      title: widget.goal != null ? 'Editar Meta' : 'Crear Meta',
      currentRoute: 'goal_form',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Meta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                onSaved: (val) => _name = val,
              ),

              const SizedBox(height: 16),

              // Selección de moneda
              widget.goal != null && selectedCurrency != null
                  ? TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      initialValue: '${selectedCurrency!.name} (${selectedCurrency!.code})',
                    )
                  : DropdownButtonFormField<Currency>(
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                initialValue: selectedCurrency,
                items: currencies
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${c.code})'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedCurrency = value),
                validator: (value) =>
                    value == null ? 'Seleccione una moneda' : null,
              ),
              

              const SizedBox(height: 16),

              // Monto objetivo
              CurrencyTextField(
                controller: _amountController,
                currencies:
                    selectedCurrency != null ? [selectedCurrency!] : currencies,
                selectedCurrency: selectedCurrency,
                label: 'Monto Objetivo',
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Ingrese un monto';
                  final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                  if (parsed <= 0) return 'Ingrese un monto válido';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              FormField<DateTime>(
                validator: (value) =>
                    _dateLimit == null ? 'Seleccione una fecha' : null,
                builder: (field) {
                  return InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateLimit = picked;
                          field.didChange(picked); 
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha Límite',
                        border: const OutlineInputBorder(),
                        errorText: field.errorText, 
                      ),
                      child: Text(
                        _dateLimit != null
                            ? '${_dateLimit!.day}/${_dateLimit!.month}/${_dateLimit!.year}'
                            : 'Seleccione una fecha',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.goal != null ? 'Guardar Cambios' : 'Crear Meta'),
              ),
            
              if (widget.goal != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar Meta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ConfirmDialogWidget(
                      title: "Eliminar Meta",
                      message: "¿Seguro que querés eliminar esta meta?",
                      confirmText: "Eliminar",
                      cancelText: "Cancelar",
                      confirmColor: Colors.red,
                    ),
                  );
                  if (confirmed == true) {
                    _deleteGoal(); // o _deleteGoal() según tu función
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
