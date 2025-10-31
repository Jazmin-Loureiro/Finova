import 'package:flutter/material.dart';
import 'package:frontend/models/goal.dart';
import 'package:frontend/models/register.dart';
import 'package:frontend/screens/goals/goal_form_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';

class GoalDetailScreen extends StatefulWidget  {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});
  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final ApiService api = ApiService();
  List<Register> registers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRegistersGoal();
  }

Future<void> _fetchRegistersGoal() async {
  try {
    final data = await api.fetchRegistersByGoal(widget.goal.id);
    setState(() {
      registers = data; // registers es List<Register>
    });
  } catch (e) {
    debugPrint('Error al cargar registros: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencySymbol = widget.goal.currency?.symbol ?? '';
    final hasRegisters = registers.isNotEmpty;

    return CustomScaffold(
      title: 'Detalle de ${widget.goal.name}',
      currentRoute: '/goal-detail',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Datos de la meta
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.goal.name,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !widget.goal.active ?
                                  Colors.grey.withOpacity(0.2)
                                  : widget.goal.state == 'completed'
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.goal.state == 'completed'
                                      ? 'Completada'
                                      : widget.goal.active
                                          ? 'En progreso'
                                          : 'Cancelada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: !widget.goal.active ?
                                  Colors.grey.withOpacity(0.2)
                                  : widget.goal.state == 'completed'
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                                
                                
                              ),
                             IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Editar meta',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GoalFormScreen(goal: widget.goal)),
                            ).then((value) {
                              if (value == true) {
                                // Si se editó la meta, recargar los datos
                                setState(() {});
                              }
                             
                            });
                          },
                        ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Objetivo: $currencySymbol${widget.goal.targetAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Saldo actual: $currencySymbol${widget.goal.balance.toStringAsFixed(2)} ${widget.goal.currency?.code ?? ''}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (widget.goal.balance / widget.goal.targetAmount)
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(10),
                            backgroundColor: Colors.grey[300],
                            color: widget.goal.balance >= widget.goal.targetAmount
                                ? Colors.green
                                : Colors.blueAccent,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Creado: ${widget.goal.createdAt != null ? dateFormat.format(widget.goal.createdAt!.toLocal()) : '-'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'Límite: ${widget.goal.dateLimit != null ? dateFormat.format(widget.goal.dateLimit!.toLocal()) : '-'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                 //  Lista de registros asociados por ahora simple 
                  const SizedBox(height: 24),
                  Text(
                    'Registros Asociados (${registers.length})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  hasRegisters
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: registers.length,
                          itemBuilder: (context, index) {
                            final register = registers[index];
                            return Card(
                              child: ListTile(
                                title: Text(register.name),
                                subtitle: Text(
                                    'Reservado: ${register.currency.symbol}${register.balance.toStringAsFixed(2)} ${register.currency.code}'),
                                trailing: Text(
                                    'Creado: ${dateFormat.format(register.created_at.toLocal())}'),
                              ),
                            );
                          },
                        )
                      : const Text('No hay registros asociados a esta meta.'),
                ],
              ),
            ),
    );
  }
}
