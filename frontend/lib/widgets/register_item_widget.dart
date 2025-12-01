import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/register_detail.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/helpers/format_utils.dart';
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
      onTap: () async {
         final updated =  await RegisterDetailSheet.show(context, r);
          if (updated == true) {
            // Si se devolvió un registro actualizado, refrescá la UI
            Navigator.pop(context, true); // notifica a la pantalla padre
          }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
           side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  size: 24,
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
                                r.category.name,
                                style:  TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$tipo • ${r.moneyMaker?.name}',
                                style: TextStyle(
                                fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Fecha
                        Text(
                          dateFormat.format(r.created_at.toLocal()),
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Meta asociada (opcional)
                    if (r.goal != null)
                      Text(
                        'Reservado: ${r.currency.symbol}${formatCurrency(r.reserved_for_goal, r.currency.code)} ${r.currency.code}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 4),

                    //  Monto
                    Text(
                      '${r.type == "income" ? "+" : "-"}${r.currency.symbol}${formatCurrency(r.balance, r.currency.code)} ${r.currency.code}',
                      style: TextStyle(
                        fontSize: 16,
                        color: r.type == "income" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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
