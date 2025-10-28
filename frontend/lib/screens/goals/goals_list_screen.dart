import 'package:flutter/material.dart';
import 'package:frontend/screens/goals/goal_detail.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/goal.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/loading_widget.dart';
import '../../services/api_service.dart';
import 'goal_form_screen.dart';


class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Goal> goals = [];


  @override
  void initState() {
    super.initState();
    _fetchGoals();// metodo
  }

  Future<void> _fetchGoals() async {
  setState(() => isLoading = true);
  try {
    final data = await api.getGoals();
    setState(() { goals = data;});
  } catch (e) {
    debugPrint('Error al cargar metas: $e');
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Metas',
      currentRoute: 'goals_list',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchGoals,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(context, 
              MaterialPageRoute(builder: (context) => const GoalFormScreen())
            ).then((value) {
              if (value == true) {
                _fetchGoals(); // recargar metas
              }
            });
          },
        )
      ],
      body: isLoading
    ? const LoadingWidget(message: 'Cargando metas...')
    : Padding(
        padding: const EdgeInsets.all(16.0),
        child: goals.isEmpty
            ? const Center(
                child: Text(
                  'No tenés metas aún',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final progress = (goal.balance / goal.targetAmount)
                      .clamp(0.0, 1.0); // evitar errores

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                   child: InkWell(
                  borderRadius: BorderRadius.circular(16), 
                  onTap: goal.active ? () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => GoalDetailScreen(goal: goal),
                    )).then((value) {
                      if (value == true) {
                        _fetchGoals(); // recargar metas al volver
                      }
                    });
                    // Navegar a detalles de la meta
                  } : null, // deshabilitar si no está activa
                    
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre de la meta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !goal.active ?
                                  Colors.grey.withOpacity(0.2)
                                  : goal.state == 'completed'
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  !goal.active ? 
                                  'Cancelada' :
                                  goal.state == 'completed'
                                      ? 'Completada'
                                      : 'En progreso',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: goal.state == 'completed'
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                                
                              ),
                              !goal.active || goal.state == 'completed' ? const SizedBox.shrink() :
                               IconButton(
                              icon: const Icon(Icons.edit, size: 20, ),
                              tooltip: 'Editar meta',
                              onPressed: () {
                                Navigator.push( context,
                                  MaterialPageRoute(
                                    builder: (context) => GoalFormScreen(goal: goal),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    _fetchGoals(); // recargar metas al volver
                                  }
                                });
                              },
                            ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progreso visual
                          !goal.active ? const SizedBox.shrink() :
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: progress >= 1
                                ? Colors.green
                                : Colors.blueAccent,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 8),

                          // Monto y saldo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              !goal.active ? const SizedBox.shrink() :
                              Text(
                                'Saldo: ${goal.currency?.symbol ?? ''}${goal.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Objetivo: ${goal.currency?.symbol ?? ''}${goal.targetAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Fecha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Creado: ${goal.createdAt != null ? DateFormat('dd/MM/yyyy').format(goal.createdAt!.toLocal()) : '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Fecha Limite: ${goal.dateLimit != null ? DateFormat('dd/MM/yyyy').format(goal.dateLimit!.toLocal()) : '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        ],
                      ),
                    ),
                   )
                  );
                
                },
              ),
      ),

    );
    
  }
}
