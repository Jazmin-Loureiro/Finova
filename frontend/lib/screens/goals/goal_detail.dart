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
                            if (widget.goal.active && widget.goal.state == 'in_progress')
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
                          
                         const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // ← alinea a la izquierda
                            children: [
                              Text(
                                'Objetivo: $currencySymbol${formatCurrency(widget.goal.targetAmount, widget.goal.currency?.code ?? '')} ${widget.goal.currency?.code ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 6), // ← separación entre ambos textos
                              Text(
                                'Saldo actual: $currencySymbol${formatCurrency(widget.goal.balance, widget.goal.currency?.code ?? '')} ${widget.goal.currency?.code ?? ''}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: (widget.goal.balance / widget.goal.targetAmount)
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(10),
                            backgroundColor: Colors.grey[300],
                            color: widget.goal.balance >= widget.goal.targetAmount
                                ? Theme.of( context).colorScheme.secondary
                                : Colors.blue,
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Aviso si la meta es parte de un desafío
                          if (widget.goal.isChallengeGoal)
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
