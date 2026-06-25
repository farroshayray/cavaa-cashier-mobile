import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// Converts CSV bytes from the report export API into a valid `.xlsx` workbook.
Uint8List csvBytesToXlsx(Uint8List csvBytes) {
  final csvString = utf8.decode(csvBytes, allowMalformed: true);
  final rows = csv.decode(csvString);

  if (rows.isEmpty) {
    throw Exception('Data laporan kosong');
  }

  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet();
  if (sheetName == null) {
    throw Exception('Gagal membuat sheet Excel');
  }

  final sheet = excel[sheetName];
  for (final row in rows) {
    sheet.appendRow(
      row.map((cell) => TextCellValue(cell?.toString() ?? '')).toList(),
    );
  }

  final saved = excel.save();
  if (saved == null) {
    throw Exception('Gagal menyimpan file Excel');
  }

  return Uint8List.fromList(saved);
}
