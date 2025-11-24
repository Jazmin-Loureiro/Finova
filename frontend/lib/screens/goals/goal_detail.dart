import 'package:flutter/material.dart';
import 'package:frontend/models/goal.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/models/register.dart';
import 'package:frontend/screens/goals/goal_form_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/register_item_widget.dart';
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
  late Goal currentGoal;

  @override
  void initState() {
    super.initState();
    currentGoal = widget.goal; // meta inicial
    _fetchRegistersGoal();
  }

  //  Refrescar la meta desde el backend
  Future<void> _refreshGoal() async {
    try { final updatedGoal = await api.fetchGoal(currentGoal.id);
      setState(() { currentGoal = updatedGoal; });
      await _fetchRegistersGoal();
    } catch (e) {
      debugPrint("Error refrescando meta: $e");
    }
  }

Future<void> _fetchRegistersGoal() async {
  try {
    final data = await api.fetchRegistersByGoal(currentGoal.id);
    setState(() {
      registers = data;
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
    final currencySymbol = currentGoal.currency?.symbol ?? '';
    final hasRegisters = registers.isNotEmpty;
    final progress =(currentGoal.balance / currentGoal.targetAmount).clamp(0.0, 1.0);

    return CustomScaffold(
      title: 'Detalle de ${currentGoal.name}',
      currentRoute: '/goal-detail',
      showNavigation: false,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                          width: 1,)),
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
                                  currentGoal.name,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !currentGoal.active ?
                                  Colors.grey.withOpacity(0.2)
                                      : currentGoal.state == 'completed'
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentGoal.state == 'completed'
                                      ? 'Completada'
                                      : currentGoal.active
                                          ? 'En progreso'
                                          : 'Cancelada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: !currentGoal.active
                                        ? Colors.grey[600]
                                        : currentGoal.state == 'completed'
                                            ? Colors.green[800]
                                            : Colors.blue[800],
                                  ),
                                ),
                              ),
                              if (currentGoal.active && currentGoal.state == 'in_progress')
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Editar meta',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GoalFormScreen( goal: currentGoal,
                                        ),
                                      ),
                                    ).then((value) {
                                       if (value == true) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        _refreshGoal(); 
                                      }
                                    });
                                },
                              ),
                            ],
                          ),
                          
                         const SizedBox(height: 10),
                              Text(
                                'Objetivo: $currencySymbol${formatCurrency(currentGoal.targetAmount, currentGoal.currency?.code ?? '')} ${currentGoal.currency?.code ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                'Saldo actual: $currencySymbol${formatCurrency(currentGoal.balance, currentGoal.currency?.code ?? '')} ${currentGoal.currency?.code ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Progreso:'),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: progress >= 1 ? Colors.green
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color:progress >= 1 ? Colors.green : Colors.blue,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Aviso si la meta es parte de un desafío
                          if (currentGoal.isChallengeGoal)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    color: Theme.of(context).colorScheme.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Esta meta está vinculada a un desafío activo.',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Creado: ${currentGoal.createdAt != null ? dateFormat.format(currentGoal.createdAt!.toLocal()) : '-'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'Límite: ${currentGoal.dateLimit != null ? dateFormat.format(currentGoal.dateLimit!.toLocal()) : '-'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                 //  Lista de registros asociados 
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
                        final r = registers[index];
                        return RegisterItemWidget(
                          register: r,
                          dateFormat: dateFormat,
                          fromHex: (hex) {
                            hex = hex.toUpperCase().replaceAll("#", "");
                            if (hex.length == 6) hex = "FF$hex";
                            return Color(int.parse(hex, radix: 16));
                          },
                        );
                      },
                    )
                  : const EmptyStateWidget(
                      title: "Aún no hay registros.",
                      message: "No has reservado ninguna cantidad aún.",
                      icon: Icons.receipt_long,
                    )
                ],
              ),
            ),
    );
  }
}
