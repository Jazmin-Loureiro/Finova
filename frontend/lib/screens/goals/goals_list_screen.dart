import 'package:flutter/material.dart';
import 'package:frontend/widgets/custom_refresh_wrapper.dart';
import 'package:frontend/widgets/info_icon_widget.dart';
import 'package:frontend/widgets/dialogs/success_dialog_widget.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/format_utils.dart';
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
       // Verificar si hay metas vencidas
    await _checkExpiredGoals();
    } catch (e) {
      debugPrint('Error al cargar metas: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

Future<void> _checkExpiredGoals() async {
  try {
    final expiredGoals = await api.getExpiredGoals();

    if (expiredGoals.isNotEmpty) {
      for (final goal in expiredGoals) {
        //  Diálogo "Meta vencida" — animación desde arriba
        await showGeneralDialog(
          context: context,
          barrierLabel: "expiredGoal",
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.25), // desde arriba
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: SuccessDialogWidget(
                  isFailure: true,
                  title: 'Meta Vencida',
                  message:
                      'Tu meta "${goal['name']}" ha vencido.\nLos fondos serán liberados automáticamente.',
                  buttonText: 'Entiendo',
                ),
              ),
            );
          },
        );

        // 🧹 Liberar meta en backend
        await api.deleteGoal(goal['id']);

        // Diálogo "Meta liberada" — animación desde abajo
        await showGeneralDialog(
          context: context,
          barrierLabel: "goalReleased",
          barrierDismissible: true,
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4), // desde abajo con rebote
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: SuccessDialogWidget(
                  title: 'Meta liberada',
                  message:
                      'Los fondos de la meta "${goal['name']}" han sido liberados correctamente.',
                ),
              ),
            );
          },
        );

        await _fetchGoals();
      }
    }
  } catch (e) {
    debugPrint('Error al verificar metas vencidas: $e');
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
        InfoIcon(
          title: 'Metas financieras',
          message:
              'Las metas financieras te ayudan a planificar y administrar tu dinero para alcanzar objetivos concretos.\n\n'
              'Establecé un monto y un plazo estimado, y al generar una transacción, Finova reservará automáticamente el dinero que asignes a esa meta para ayudarte a cumplirla.',
        ),
        /*
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchGoals,
        ),
        */
         Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            tooltip: 'Agregar nueva meta',
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
      ),
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
                    CustomRefreshWrapper(
                      onRefresh: _fetchGoals,
                      child: _buildGoalsList(_filterGoals('in_progress')),
                    ),
                    CustomRefreshWrapper(
                      onRefresh: _fetchGoals,
                      child: _buildGoalsList(_filterGoals('completed')),
                    ),
                    CustomRefreshWrapper(
                      onRefresh: _fetchGoals,
                      child: _buildGoalsList(_filterGoals('disabled')),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> filteredGoals) {
    if (filteredGoals.isEmpty) {
      return Column(
        children: const [
          SizedBox(height: 20),
          EmptyStateWidget(
            title: "Aún no tenés metas.",
            message:
                "Creá metas para reservar dinero y avanzar hacia tus objetivos financieros.",
            icon: Icons.flag,
          ),
        ],
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
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                  width: 1,)),
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
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progreso visual
                  if (goal.active) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso:',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: progress >= 1
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: progress >= 1
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.blue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  const SizedBox(height: 8),
                  ],
                  SizedBox(height: 8),

                  // Monto y saldo
                 Column(
                  crossAxisAlignment: CrossAxisAlignment.start  ,
                    children: [
                      Text('Objetivo: ${goal.currency?.symbol ?? ''}${formatCurrency(goal.targetAmount, goal.currency?.code ?? '')} ${goal.currency?.code ?? ''}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text('Saldo: ${goal.currency?.symbol ?? ''}${formatCurrency(goal.balance, goal.currency?.code ?? '')} ${goal.currency?.code ?? ''}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Fechas
                 Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Creado: ${goal.createdAt != null ? DateFormat('dd/MM/yyyy').format(goal.createdAt!.toLocal()) : '-'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      (() {
                        // Si la meta está completada → usar updatedAt
                        if (goal.state == 'completed') {
                          final finishedDate = goal.updatedAt != null ? DateFormat('dd/MM/yyyy').format(goal.updatedAt!.toLocal()): '-';

                          return Text('Completada el $finishedDate',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        }
                        if (goal.active && goal.state == 'in_progress') {
                          final today = DateTime.now();
                          final limit = goal.dateLimit!;
                          final daysLeft = limit.difference(today).inDays;

                          late String message;

                          if (daysLeft > 0) {
                            message = 'Te quedan $daysLeft días';
                          } else if (daysLeft == 0) {
                            message = 'Vence hoy';
                          } else {
                            message = 'Venció hace ${daysLeft.abs()} días';
                          }

                          return Text(
                            message,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        }
                        // Si está cancelada o inactiva
                        return const Text(
                          'Sin fecha límite',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      })(),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
