import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/models/register.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';


class RegisterDetailSheet extends StatefulWidget {
  final Register register;
  const RegisterDetailSheet({super.key, required this.register});

  // Método para mostrar el modal como bottom sheet
  static Future<bool?> show(BuildContext context, Register register) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RegisterDetailSheet(register: register),
  );
}


  @override
  State<RegisterDetailSheet> createState() => _RegisterDetailSheetState();
}

class _RegisterDetailSheetState extends State<RegisterDetailSheet> {
  final ApiService api = ApiService();
  bool isLoading = true;
  late Register register = widget.register;

  @override
  void initState() {
    super.initState();
    _fetchDataRegister();
  }

  Color _getMoneyMakerColor() {
    return Color(
      int.parse(register.moneyMaker?.color.substring(1) ?? '0', radix: 16) + 0xFF000000,
    );
  }

Future<bool> _cancelReserve() async {
  try {
    final success = await api.cancelReserve(register.id);
    if (success) {
      await _fetchDataRegister(); 
      if (mounted) {
        setState(() {});
      }
    }
    return success;
  } catch (e) {
    debugPrint(' Error al cancelar reserva: $e');
    return false;
  }
}


  Future<void> _fetchDataRegister() async {
    try {
      final data = await api.getDataRegister(register.id);
      if (data != null) setState(() => register = data);
    } catch (e) {
      debugPrint('Error al cargar detalle del registro: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _openFile(BuildContext context, String fileUrl) async {
    try {
      final Uri uri = Uri.parse(fileUrl);
      final bool launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await showDialog(
          context: context,
          builder: (_) => ConfirmDialogWidget(
            title: 'Error',
            message: 'No se pudo abrir el archivo adjunto.',
            confirmText: "Aceptar",
            confirmColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint(' Error al abrir enlace: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al abrir el archivo adjunto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = register.type == 'income';
    final currencySymbol = register.currency.symbol;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.90,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  Indicador superior
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    //  Título
                    Center(
                      child: Text(
                        isIncome
                            ? 'Detalle de ingreso'
                            : 'Detalle de gasto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Monto
                   Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, // Color de fondo del contenedor
                      border: Border.all(
                        color: Colors.grey.shade300, // Color del borde
                        width: 1,                  // Grosor del borde
                      ),
                      borderRadius: BorderRadius.circular(10), // Bordes redondeados
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.15),
                          child: Icon(
                            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 30,
                            color: isIncome ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currencySymbol}${register.balance.toStringAsFixed(2)} ${register.currency.code}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.green[800] : Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${register.name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              //  Fecha
                              const SizedBox(height: 4),
                              Text(
                                'Creado: ${dateFormat.format(register.created_at)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
  
                    //  Categoría +  Fuente de dinero
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    if (register.reserved_for_goal != null && register.reserved_for_goal! > 0)
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child:  Icon(
                                   Icons.track_changes_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Meta',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${register.goal?.name} - ${currencySymbol}${register.reserved_for_goal} ${register.currency.code}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          //  Categoría
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(
                                  int.parse(register.category.color.substring(1), radix: 16) + 0xFF000000,
                                ).withOpacity(0.15),
                                child: Icon(
                                  AppIcons.fromName(register.category.icon),
                                  color: Color(
                                    int.parse(register.category.color.substring(1), radix: 16) + 0xFF000000,
                                  ),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Categoría',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      register.category.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Fuente de dinero
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child:  Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 18,
                                   color: _getMoneyMakerColor(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                      'Fuente de dinero',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      ),
                                    
                                    Text(
                                      register.moneyMaker?.name ?? 'Sin fuente de dinero',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(height: 20),
                    // Archivo adjunto
                    if (register.file != null)
                      GestureDetector(
                        onTap: () =>
                            _openFile(context, register.file!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            ),
                            color: Theme.of(context) .colorScheme.primary.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file_rounded,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Abrir archivo adjunto',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded,
                                  color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        ),
                      ),

                      if (register.reserved_for_goal != null && register.reserved_for_goal! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child:

                             ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                foregroundColor: Theme.of(context).colorScheme.error,
                                elevation: 0,
                                
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => ConfirmDialogWidget(
                                    title: 'Cancelar reserva',
                                    message: '¿Seguro que querés liberar este monto reservado?',
                                    confirmText: 'Sí, cancelar',
                                    cancelText: 'No',
                                    confirmColor: Theme.of(context).colorScheme.error,
                                  ),
                                );

                               if (confirm == true) {
                                final resp = await _cancelReserve();

                                if (resp) {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => ConfirmDialogWidget(
                                      title: 'Reserva cancelada',
                                      message: 'El monto reservado ha sido liberado exitosamente.',
                                      confirmText: 'Aceptar',
                                      confirmColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                    Navigator.pop(context, true); 

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error al cancelar la reserva')),
                                  );
                                }
                              }

                              },
                              child: const Text(
                                'Cancelar reserva',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                ),
              ),
            ),
    );
  }
}
