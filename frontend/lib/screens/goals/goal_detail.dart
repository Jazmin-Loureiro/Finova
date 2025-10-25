import 'package:flutter/material.dart';
import 'package:frontend/models/goal.dart';
import 'package:intl/intl.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${goal.name}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Saldo: ${goal.currency?.symbol ?? ''}${goal.balance.toStringAsFixed(2)}'),
            Text('Objetivo: ${goal.currency?.symbol ?? ''}${goal.targetAmount.toStringAsFixed(2)}'),
            Text('Estado: ${goal.state == 'completed' ? 'Completada' : 'En progreso'}'),
            Text('Moneda: ${goal.currency != null ? '${goal.currency!.name} (${goal.currency!.code})' : '-'}'),
            Text('Creado: ${goal.createdAt != null ? dateFormat.format(goal.createdAt!.toLocal()) : '-'}'),
            Text('Fecha Límite: ${goal.dateLimit != null ? dateFormat.format(goal.dateLimit!.toLocal()) : '-'}'),
            Text('Última Actualización: ${goal.updatedAt != null ? dateFormat.format(goal.updatedAt!.toLocal()) : '-'}'),
          ],
        ),
      ),
    );
  }
}
