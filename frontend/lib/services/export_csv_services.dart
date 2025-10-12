import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/money_maker.dart';

class ExportCsvServices {
  static Future<void> exportCsv({
    required List<MoneyMaker> moneyMakers,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final buffer = StringBuffer();

    // Cabecera del reporte
    buffer.writeln(
      'Reporte de Movimientos, Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'
    );
    buffer.writeln(); // Línea en blanco

    for (final m in moneyMakers) {
      if (m.registers.isEmpty) continue;

      // Título de la sección
      buffer.writeln('Fuente de dinero: ${m.name}');
      // Encabezado de columnas
      buffer.writeln('Fecha,Nombre,Categoría,Tipo,Monto,Moneda');

      double total = 0;

      for (final r in m.registers) {
        final formattedDate = DateFormat('dd/MM/yyyy').format(r.created_at);
        final tipo = r.type == "income" ? "Ingreso" : "Gasto";
        final moneda = m.currency?.code ?? '';
        final monto = r.balance.toStringAsFixed(2);

        total += r.balance;

        buffer.writeln(
          '$formattedDate,${r.name},${r.category.name},$tipo,$monto,$moneda'
        );
      }

      // Total por fuente de dinero
      buffer.writeln(', , ,Total,${total.toStringAsFixed(2)},${m.currency?.code ?? ""}');
      buffer.writeln(); // Línea en blanco para separar secciones
    }

    if (buffer.isEmpty) {
      buffer.writeln('No se encontraron registros en el rango seleccionado.');
    }

    // Guardar archivo
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);
    final fileName = 'reporte_$startStr-$endStr.csv';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);

    await OpenFilex.open(file.path);
  }
}
