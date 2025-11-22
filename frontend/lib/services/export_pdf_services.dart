import 'dart:io';
import 'package:flutter/services.dart'; // Para rootBundle y cargar fuentes
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:pdf/pdf.dart'; // Librería PDF
import 'package:pdf/widgets.dart' as pw; // Widgets PDF con alias pw
import 'package:path_provider/path_provider.dart'; // Para obtener directorios
import 'package:open_filex/open_filex.dart'; // Para abrir archivos
import '../models/money_maker.dart'; // Modelo MoneyMaker
import '../helpers/format_utils.dart';


class ExportPdfServices {
  static Future<void> exportPDF({
    required List<MoneyMaker> moneyMakers,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    if (startDate == null || endDate == null) return;

    // Cargar fuente personalizada 
    final fontData = await rootBundle.load(
      'assets/font/Roboto/Roboto-Italic-VariableFont_wdth,wght.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    // Crear documento PDF con fuente personalizada
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttf,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Reporte de Movimientos',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1, color: PdfColors.grey),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount} — Generado por Finova',
            style: const pw.TextStyle(color: PdfColors.grey),
          ),
        ),
        build: (context) {
          List<pw.Widget> content = [];
          for (var moneyMaker in moneyMakers) {
            if (moneyMaker.registers.isEmpty) continue;

            final totalLocal = moneyMaker.registers.fold<double>(
              0,
              (sum, r) => sum + (r.type == 'income' ? r.balance : -r.balance),
            );
            content.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Fuente de dinero: ${moneyMaker.name}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Tabla de registros
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2),
                      1: pw.FlexColumnWidth(2.5),
                      2: pw.FlexColumnWidth(1.5),
                      3: pw.FlexColumnWidth(1),
                      4: pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          for (var h in [
                            'Fecha',
                            'Descripción',
                            'Categoría',
                            'Tipo',
                            'Monto'
                          ])
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                h,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      ...moneyMaker.registers.map((r) {
                        final cells = [
                          DateFormat('dd/MM/yyyy').format(r.created_at),
                          r.name,
                          r.category.name,
                          r.type == 'income' ? 'Ingreso' : 'Gasto',
                          '${formatCurrency(r.balance, moneyMaker.currency?.code ?? '', symbolOverride: moneyMaker.currency?.symbol ?? '')} ${r.currency.code}',
                        ];
                        return pw.TableRow(
                          children: [
                            for (var cell in cells)
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  cell,
                                  style: pw.TextStyle(
                                    fontWeight: cell == cells.last
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),

                  pw.SizedBox(height: 8),

                  // Totales
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Total: ${formatCurrency(totalLocal, moneyMaker.currency?.code ?? '', symbolOverride: moneyMaker.currency?.symbol ?? '')} ${moneyMaker.currency?.code ?? ''}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 20),
                ],
              ),
            );
          }

          if (content.isEmpty) {
            content.add(
              pw.Center(
                child: pw.Text(
                  'No se encontraron registros en el rango seleccionado.',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ),
            );
          }
          return content;
        },
      ),
    );
    // Guardar el archivo
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'Reporte_${DateFormat('dd-MM-yyyy').format(startDate)}_${DateFormat('dd-MM-yyyy').format(endDate)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
