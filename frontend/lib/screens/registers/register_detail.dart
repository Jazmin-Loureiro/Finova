import 'package:flutter/material.dart';
import 'package:frontend/widgets/confirm_dialog_widget.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/models/register.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_scaffold.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 nuevo

class RegisterDetailScreen extends StatefulWidget {
  final Register register;

  const RegisterDetailScreen({super.key, required this.register});

  @override
  State<RegisterDetailScreen> createState() => _RegisterDetailScreenState();
}

class _RegisterDetailScreenState extends State<RegisterDetailScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  late Register register = widget.register;

  @override
  void initState() {
    super.initState();
    _fetchDataRegister();
  }

  Future<void> _fetchDataRegister() async {
    try {
      final data = await api.getDataRegister(register.id);
      if (data != null) setState(() => register = data);
     } catch (e) {
      debugPrint('Error al cargar el detalle del registro: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
   Future<void> _openFile(BuildContext context, String fileUrl) async {
  try {
    final Uri uri = Uri.parse(fileUrl);
    //  Fuerza el modo navegador externo
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ConfirmDialogWidget(
            title: 'Error',
            message: 'No se pudo abrir el archivo adjunto.',
            confirmText: "Aceptar",
            cancelText: "Cancelar",
            confirmColor: Theme.of(context).colorScheme.primary,
          );
      }
    } catch (e) {
      debugPrint('❌ Error al abrir enlace: $e');
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

    return CustomScaffold(
      title: isIncome ? 'Detalle de ingreso' : 'Detalle de gasto',
      currentRoute: '/register-detail',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monto + tipo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: (isIncome
                                    ? Colors.green
                                    : Colors.red)
                                .withOpacity(0.15),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 30,
                              color: isIncome
                                  ? Colors.green[700]
                                  : Colors.red[700],
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
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isIncome
                                        ? Colors.green[800]
                                        : Colors.red[700],
                                  ),
                                ),
                                if (register.reserved_for_goal != null &&
                                    register.reserved_for_goal! > 0)
                                  Text(
                                    '${currencySymbol}${register.reserved_for_goal} ${register.currency.code} (Reservado)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nombre: ${register.name}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Categoría
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(
                              int.parse(
                                      register.category.color.substring(1),
                                      radix: 16) +
                                  0xFF000000,
                            ).withOpacity(0.15),
                            child: Icon(
                              AppIcons.fromName(register.category.icon),
                              color: Color(
                                int.parse(
                                        register.category.color.substring(1),
                                        radix: 16) +
                                    0xFF000000,
                              ),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            register.category.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Fuente de dinero
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            register.moneyMaker?.name ?? 'Sin fuente de dinero',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Fecha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha: ${dateFormat.format(register.created_at)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      //  Archivo adjunto (opcional)
                      if (register.file != null)
                        GestureDetector(
                          onTap: () => _openFile(context, register.file!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                   'Abrir archivo adjunto',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                 Icon(Icons.open_in_new_rounded,
                                    size: 18, color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
