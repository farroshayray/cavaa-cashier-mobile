import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '/features/cashier/data/models/printer_device.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/presentation/printing/receipt_amount_helpers.dart';
import '/features/cashier/presentation/printing/receipt_pdf_builder.dart';
import '/features/cashier/presentation/printing/receipt_printer.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

typedef FetchOrderDetail = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> row,
);

class ReceiptActionService {
  ReceiptActionService(this.context);

  final BuildContext context;

  Future<void> printReceipt({
    required Map<String, dynamic> row,
    required FetchOrderDetail fetchOrder,
    bool requirePaid = false,
  }) async {
    if (requirePaid && !canPrintProcessReceipt(row)) {
      _snack('Struk hanya bisa dicetak setelah order dibayar.');
      return;
    }

    try {
      final prepared = await _prepareOrder(row: row, fetchOrder: fetchOrder);
      if (!context.mounted) return;

      final pm = context.read<PrinterManager>();
      final printer = pm.defaultPrinter;
      if (printer == null) throw Exception('Default printer belum dipilih');
      if (printer.type != PrinterType.bluetooth ||
          printer.address == null ||
          printer.address!.trim().isEmpty) {
        throw Exception('Default printer bukan Bluetooth / address kosong');
      }

      final bytes = await ReceiptPrinter().buildReceiptBytes(
        order: prepared.order,
        paidAmount: prepared.paid,
        changeAmount: prepared.change,
      );

      await pm.write(bytes);
      _snack('Struk berhasil diprint');
    } catch (e) {
      _snack('Gagal print: $e');
    }
  }

  Future<void> shareReceiptPdf({
    required Map<String, dynamic> row,
    required FetchOrderDetail fetchOrder,
    bool requirePaid = false,
  }) async {
    if (requirePaid && !canPrintProcessReceipt(row)) {
      _snack('Struk hanya bisa dibagikan setelah order dibayar.');
      return;
    }

    try {
      final prepared = await _prepareOrder(row: row, fetchOrder: fetchOrder);
      if (!context.mounted) return;

      final code =
          (prepared.order['booking_order_code'] ?? 'order').toString();
      final pdfBytes = await ReceiptPdfBuilder().buildReceiptPdf(
        order: prepared.order,
        paidAmount: prepared.paid,
        changeAmount: prepared.change,
      );

      final dir = await getTemporaryDirectory();
      final safeCode = code.replaceAll(RegExp(r'[^\w\-]'), '_');
      final filePath = p.join(dir.path, 'Struk_$safeCode.pdf');
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/pdf')],
        text: 'Struk pembayaran $code',
        subject: 'Struk $code',
      );
    } catch (e) {
      _snack('Gagal bagikan PDF: $e');
    }
  }

  Future<
      ({
        Map<String, dynamic> order,
        num paid,
        num change,
      })> _prepareOrder({
    required Map<String, dynamic> row,
    required FetchOrderDetail fetchOrder,
  }) async {
    final order = await fetchOrder(row);
    final amounts = receiptPaidChangeAmounts(order);
    return (order: order, paid: amounts.paid, change: amounts.change);
  }

  void _snack(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
