// lib/features/cashier/presentation/printing/receipt_printer.dart
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'receipt_format_helpers.dart';
import 'receipt_order_enricher.dart';
import 'receipt_totals.dart';

class ReceiptPrinter {
  Future<Uint8List> buildReceiptBytes({
    required Map<String, dynamic> order,
    ReceiptTotals? totals,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final bytes = await _buildReceiptBytes(
      order: order,
      totals: totals ?? buildReceiptTotals(order),
      paperSize: paperSize,
    );
    return Uint8List.fromList(bytes);
  }

  Future<List<int>> _buildReceiptBytes({
    required Map<String, dynamic> order,
    required ReceiptTotals totals,
    required PaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperSize, profile);

    final bytes = <int>[];

    final code = (order['booking_order_code'] ?? '-').toString();
    final customer = (order['customer_name'] ?? '-').toString();
    final subtotal = totals.subtotal;
    final isPpnActive = totals.isPpnActive;
    final ppnPercent = totals.ppnPercent;
    final ppnAmount = totals.ppnAmount;
    final roundingAmount = totals.roundingAmount;
    final grandTotal = totals.grandTotal;
    final paidAmount = totals.paid;
    final changeAmount = totals.change;

    bytes.addAll(gen.reset());
    final storeName = (order['store_name'] ?? 'CAVAA').toString().trim();
    final cashierName = (order['employee_name'] ?? '-').toString();
    final storeAddress = (order['store_address'] ?? '').toString().trim();

    final wifiShown = receiptWifiShown(order);
    final wifiUser = (order['store_wifi_user'] ?? '').toString().trim();
    final wifiPass = (order['store_wifi_password'] ?? '').toString().trim();

    final maxChars = (paperSize == PaperSize.mm58) ? 32 : 48;

    final len = storeName.length;

    var w = PosTextSize.size2;
    var h = PosTextSize.size2;
    var font = PosFontType.fontA;

    if (len > 16) {
      w = PosTextSize.size1;
      h = PosTextSize.size1;
      font = PosFontType.fontA;
    }

    if (len > 24) {
      w = PosTextSize.size1;
      h = PosTextSize.size1;
      font = PosFontType.fontA;
    }

    bytes.addAll(gen.reset());

    bytes.addAll(gen.text(
      storeName,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        width: w,
        height: h,
        fontType: font,
      ),
      maxCharsPerLine: maxChars,
    ));
    bytes.addAll(gen.hr(ch: '=', linesAfter: 1));

    if (storeAddress.isNotEmpty) {
      bytes.addAll(gen.text(storeAddress,
          styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(gen.text('Struk Pembayaran',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.hr());

    bytes.addAll(gen.text('Order  : $code'));

    final paidAtStr = receiptFormatTime(receiptPaidAtRaw(order));

    if (paidAtStr.isNotEmpty) {
      bytes.addAll(gen.text('Waktu  : $paidAtStr'));
    }

    bytes.addAll(gen.text('Nama   : $customer'));
    bytes.addAll(gen.text('Kasir  : $cashierName'));
    bytes.addAll(gen.hr());

    final details = (order['order_details'] as List?) ?? [];
    for (final it in details) {
      final m = (it as Map).cast<String, dynamic>();
      final qty = receiptNum(m['quantity']).toInt();
      final name = (m['product_name'] ?? 'Produk').toString();
      final basePrice = receiptNum(m['base_price']);
      final promoAmount = receiptNum(m['promo_amount']);
      final priceEach = (basePrice - promoAmount);
      final lineTotal = priceEach * qty;

      bytes.addAll(gen.text(name, styles: const PosStyles(bold: true)));
      bytes.addAll(gen.row([
        PosColumn(text: '$qty x ${receiptRupiah(priceEach)}', width: 8),
        PosColumn(
            text: receiptRupiah(lineTotal),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));

      final opts = (m['order_detail_options'] as List?) ?? [];
      for (final o in opts) {
        final om = (o as Map).cast<String, dynamic>();
        final optName = (om['option'] is Map
                ? (om['option']['name'] ?? '-')
                : '-')
            .toString();
        final optPrice = receiptNum(om['price']) * qty;
        bytes.addAll(gen.row([
          PosColumn(text: '  + $optName', width: 8),
          PosColumn(
              text: receiptRupiah(optPrice),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(gen.feed(1));
    }

    bytes.addAll(gen.hr());

    bytes.addAll(gen.row([
      PosColumn(text: 'TOTAL', width: 8),
      PosColumn(
        text: receiptRupiah(subtotal.ceil()),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    if (isPpnActive) {
      bytes.addAll(gen.row([
        PosColumn(
            text: 'PPN (${receiptFormatPercent(ppnPercent)}%)', width: 8),
        PosColumn(
          text: receiptRupiah(ppnAmount.ceil()),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    if (roundingAmount > 0) {
      bytes.addAll(gen.row([
        PosColumn(text: 'PEMBULATAN', width: 8),
        PosColumn(
          text: receiptRupiah(roundingAmount),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(gen.row([
      PosColumn(
          text: 'GRAND TOTAL',
          width: 8,
          styles: const PosStyles(bold: true)),
      PosColumn(
        text: receiptRupiah(grandTotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));

    bytes.addAll(gen.row([
      PosColumn(text: 'BAYAR', width: 8),
      PosColumn(
        text: receiptRupiah(paidAmount),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    bytes.addAll(gen.row([
      PosColumn(text: 'KEMBALI', width: 8),
      PosColumn(
        text: receiptRupiah(changeAmount),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    if (wifiShown && (wifiUser.isNotEmpty || wifiPass.isNotEmpty)) {
      bytes.addAll(gen.text('WiFi', styles: const PosStyles(bold: true)));
      if (wifiUser.isNotEmpty) bytes.addAll(gen.text('User : $wifiUser'));
      if (wifiPass.isNotEmpty) bytes.addAll(gen.text('Pass : $wifiPass'));
      bytes.addAll(gen.hr());
    }

    bytes.addAll(gen.hr());
    bytes.addAll(gen.text('Terima kasih',
        styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(gen.feed(5));
    bytes.addAll(gen.text('-----------------------------',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(3));

    return bytes;
  }
}
