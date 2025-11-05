import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/goal.dart';
import 'package:frontend/screens/goals/goal_detail.dart';
import 'package:frontend/screens/goals/goal_form_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Goal> goals = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() => isLoading = true);
    try {
      final data = await api.getGoals();
      setState(() => goals = data);
    } catch (e) {
      debugPrint('Error al cargar metas: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Goal> _filterGoals(String state) {
    return goals.where((g) => g.state == state).toList();
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
      : Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'En proceso'),
              Tab(text: 'Completadas'),
              Tab(text: 'Canceladas'),
            ],
          ),
          Expanded(
            child: isLoading
                ? const LoadingWidget(message: 'Cargando metas...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsList(_filterGoals('in_progress')),
                      _buildGoalsList(_filterGoals('completed')),
                      _buildGoalsList(_filterGoals('disabled')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> filteredGoals) {
    if (filteredGoals.isEmpty) {
      return EmptyStateWidget(
            title: "Aún no tenés metas.",
            message:
                "Las metas te ayudan a organizar y alcanzar tus objetivos financieros.",
            icon: Icons.flag,
          );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = filteredGoals[index];
        final progress = (goal.balance / goal.targetAmount).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => GoalDetailScreen(goal: goal),
                ),
              ).then((value) {
                if (value == true) _fetchGoals();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !goal.active
                              ? Colors.grey.withOpacity(0.2)
                              : goal.state == 'completed'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          !goal.active
                              ? 'Cancelada'
                              : goal.state == 'completed'
                                  ? 'Completada'
                                  : 'En progreso',
                          style: TextStyle(
                            fontSize: 14,
                            color: !goal.active
                                ? Colors.grey[800]
                                : goal.state == 'completed'
                                    ? Colors.green[800]
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      if (goal.active && goal.state == 'in_progress')
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Editar meta',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GoalFormScreen(goal: goal)),
                            ).then((value) {
                              if (value == true) _fetchGoals();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progreso visual
                  if (goal.active)
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: progress >= 1 ? Colors.green : Colors.blueAccent,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  const SizedBox(height: 8),

                  // Monto y saldo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (goal.active)
                        Text(
                          'Saldo: ${goal.currency?.symbol ?? ''}${goal.balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      Text(
                        'Objetivo: ${goal.currency?.symbol ?? ''}${goal.targetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Fechas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Creado: ${goal.createdAt != null ? DateFormat('dd/MM/yyyy').format(goal.createdAt!.toLocal()) : '-'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Fecha Limite: ${goal.dateLimit != null ? DateFormat('dd/MM/yyyy').format(goal.dateLimit!.toLocal()) : '-'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
