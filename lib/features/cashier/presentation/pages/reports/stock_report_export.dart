import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '/features/cashier/presentation/utils/report_xlsx_converter.dart';

Future<void> exportStockReportCsv({
  required BuildContext context,
  required Future<Uint8List> Function() fetchCsv,
  required String fileName,
}) async {
  try {
    final csvBytes = await fetchCsv();
    final bytes = csvBytesToXlsx(csvBytes);
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/report_exports');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final file = File('${folder.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File export disimpan: $fileName')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export gagal: $e')),
    );
  }
}

String formatStockQty(num? value) {
  if (value == null) return '-';
  final n = value.toDouble();
  if (n == n.roundToDouble()) {
    return _groupThousands(n.round().toString());
  }
  final fixed = n.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  final parts = fixed.split('.');
  final whole = _groupThousands(parts[0]);
  return parts.length > 1 ? '$whole,${parts[1]}' : whole;
}

String formatStockMoney(num? value) {
  if (value == null) return 'Rp 0';
  final n = value.round();
  final neg = n < 0;
  final abs = n.abs().toString();
  return '${neg ? '-' : ''}Rp ${_groupThousands(abs)}';
}

String _groupThousands(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buf.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
