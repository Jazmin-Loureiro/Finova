import 'package:flutter/material.dart';
import 'package:frontend/widgets/success_dialog_widget.dart';
import 'package:intl/intl.dart';
import '../widgets/loading_widget.dart';
import '../models/money_maker.dart';
import '../services/api_service.dart';
import '../services/export_pdf_services.dart';
import '../services/export_xlsx_services.dart';
import '../services/export_csv_services.dart';
import '../widgets/custom_scaffold.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});
  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final apiService = ApiService();
  DateTime? startDate;
  DateTime? endDate;
  List<MoneyMaker> moneyMakers = [];
  bool isLoading = false;

  /// Selección de fecha
  Future<void> selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  /// Obtiene y filtra los MoneyMakers según fechas
  Future<List<MoneyMaker>> getFilteredMoneyMakers(
      DateTime start, DateTime end) async {
    final result = await apiService.getMoneyMakersFull();
    List<MoneyMaker> allMoneyMakers = result['moneyMakers'] ?? [];
    final currencySymbol = result['currency_symbol'] ?? '';

    final adjustedEnd =
        DateTime(end.year, end.month, end.day, 23, 59, 59); // Fin del día

    for (var m in allMoneyMakers) {
      final allRegisters = await apiService.getRegistersByMoneyMaker(m.id);
      m.registers.addAll(
        allRegisters.where((r) {
          final localDate = r.created_at.toLocal();
          return !localDate.isBefore(start) && !localDate.isAfter(adjustedEnd);
        }),
      );
      m.currencySymbol = currencySymbol;
    }

    allMoneyMakers = allMoneyMakers.where((m) {
      final hasRegisters = m.registers.isNotEmpty;
      final total = m.registers.fold<double>(0, (sum, r) => sum + r.balance);
      return hasRegisters && total != 0;
    }).toList();

    return allMoneyMakers;
  }

  /// Función genérica para manejar cualquier tipo de exportación
  Future<void> handleExport(
      Future<void> Function(List<MoneyMaker>) exportFn) async {
    if (startDate == null || endDate == null) {
      showDialog(
        context: context,
        builder: (context) => SuccessDialogWidget(
          title: 'Error',
          message: 'Seleccioná ambas fechas',
          buttonText: 'Aceptar',
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final allMoneyMakers = await getFilteredMoneyMakers(startDate!, endDate!);
      if (allMoneyMakers.isEmpty) {
        showDialog(
        context: context,
        builder: (context) => SuccessDialogWidget(
          title: 'Advertencia',
          message: 'No hay movimientos en el rango seleccionado',
          buttonText: 'Aceptar',
        ),
      );
        return;
      }
      setState(() => moneyMakers = allMoneyMakers);
      await exportFn(allMoneyMakers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Exportar PDF
  Future<void> exportPDF() async {
    await handleExport(
      (data) => ExportPdfServices.exportPDF(
        moneyMakers: data,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  /// Exportar CSV
  Future<void> exportCSV() async {
    await handleExport(
      (data) => ExportCsvServices.exportCsv(
        moneyMakers: data,
        startDate: startDate!,
        endDate: endDate!,
      ),
    );
  }

  /// Exportar XLSX
  Future<void> exportXLSX() async {
    await handleExport(
      (data) => ExportXlsxServices.exportXlsx(
        moneyMakers: data,
        startDate: startDate!,
        endDate: endDate!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Exportaciones',
      currentRoute: 'export',
      body: isLoading
          ? const LoadingWidget(message: 'Cargando...')
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Fecha Desde
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      leading: Icon(Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text("Desde"),
                      subtitle: Text(
                        startDate != null
                            ? DateFormat('dd MMM yyyy', 'es')
                                .format(startDate!)
                                .toLowerCase()
                            : "Seleccionar fecha",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () => selectDate(context, true),
                    ),
                    const SizedBox(height: 10),

                    // Fecha Hasta
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side:  BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      leading:
                          Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                      title: Text("Hasta"),
                      subtitle: Text(
                        endDate != null
                            ? DateFormat('dd MMM yyyy', 'es')
                                .format(endDate!)
                                .toLowerCase()
                            : "Seleccionar fecha",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () => selectDate(context, false),
                    ),
                    const SizedBox(height: 20),

                    // Botones de exportación
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: exportPDF,
                            icon: const Icon(Icons.picture_as_pdf,
                                color: Colors.white),
                            label: const Text('PDF',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: exportXLSX,
                            icon: const Icon(Icons.table_chart,
                                color: Colors.white),
                            label: const Text('XLS',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 46, 139, 49),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: exportCSV,
                            icon: const Icon(Icons.table_chart,
                                color: Colors.white),
                            label: const Text('CSV',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
