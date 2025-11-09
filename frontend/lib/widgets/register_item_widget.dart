import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/register_detail.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/models/register.dart';

class RegisterItemWidget extends StatelessWidget {
  final Register register;
  final DateFormat dateFormat;
  final Color Function(String) fromHex;

  const RegisterItemWidget({
    super.key,
    required this.register,
    required this.dateFormat,
    required this.fromHex,
  });

  @override
  Widget build(BuildContext context) {
    final r = register;
    final tipo = r.type == "income" ? "Ingreso" : "Gasto";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RegisterDetailScreen(register: r),
                ),
              );
            },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  Icono principal
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: fromHex(r.category.color),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.fromName(r.category.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + tipo/categoría + fecha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre + Tipo/Categoría
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$tipo • ${r.category.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Fecha
                        Text(
                          dateFormat.format(r.created_at),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Meta asociada (opcional)
                    if (r.goal != null)
                      Text(
                        'Meta: ${r.goal!.name} - Reservado: ${r.currency.symbol}${r.reserved_for_goal}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 4),

                    //  Monto
                    Text(
                      '${r.currency.symbol}${r.balance.toStringAsFixed(2)} ${r.currency.code}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
