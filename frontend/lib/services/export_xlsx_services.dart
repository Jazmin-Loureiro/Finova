import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../models/money_maker.dart';


class ExportXlsxServices {
  static Future<void> exportXlsx({
    required List<MoneyMaker> moneyMakers,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Reporte');
    final sheet = excel['Reporte'];   
    // Estilos
    final boldStyle = CellStyle(bold: true, fontSize: 11);
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    int rowIndex = 0;
    final totalPorMoneda = <String, double>{};

    for (final m in moneyMakers) {
      // Título de la fuente
      sheet
          .cell(CellIndex.indexByString('A${rowIndex + 1}'))
          .value = TextCellValue('Fuente: ${m.name}');
      sheet
          .cell(CellIndex.indexByString('A${rowIndex + 1}'))
          .cellStyle = boldStyle;
      rowIndex++;

      // Encabezados 
      final headers = ['Fecha', 'Nombre', 'Categoría', 'Tipo', 'Símbolo', 'Monto', 'Moneda'];
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }
      rowIndex++;

      final subtotalPorMoneda = <String, double>{};
      final startRow = rowIndex;

      // Registros
      for (final r in m.registers) {
        final formattedDate = DateFormat('dd/MM/yyyy').format(r.created_at);
        final symbol = m.currency?.symbol ?? '';
        final moneda = m.currency?.code ?? '';
        final monto = r.balance;

        final row = [
          formattedDate,
          r.name,
          r.category.name,
          r.type == "income" ? "Ingreso" : "Gasto",
        ];

        // Celdas base
        for (var col = 0; col < row.length; col++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
              .value = TextCellValue(row[col].toString());
        }

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(symbol);

      
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = DoubleCellValue(monto);

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(moneda);

        rowIndex++;

        subtotalPorMoneda[moneda] = (subtotalPorMoneda[moneda] ?? 0) + monto;
        totalPorMoneda[moneda] = (totalPorMoneda[moneda] ?? 0) + monto;
      }

      // Subtotal por moneda
      for (final entry in subtotalPorMoneda.entries) {
        final endRow = rowIndex - 1;
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        // Columna Subtotal
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue('Subtotal ${m.name}:');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .cellStyle = boldStyle; // celda en negrita

        //  Columna símbolo
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(m.currency?.symbol ?? '');

        // Fórmula SUM
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = FormulaCellValue('SUM(F${startRow + 1}:F${endRow + 1})');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .cellStyle = boldStyle;

        //  Columna moneda
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(entry.key);

        rowIndex++;
      }

      rowIndex++;
    }

    // Guardar archivo
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);
    final fileName = 'reporte_$startStr-$endStr.xlsx';

    final dirs = await getExternalStorageDirectories();
    final dir = dirs!.first;
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!, flush: true);

    await OpenFilex.open(file.path);
  }
}
