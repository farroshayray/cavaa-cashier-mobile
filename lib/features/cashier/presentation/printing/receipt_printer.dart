// lib/features/cashier/presentation/printing/receipt_printer.dart
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ReceiptPrinter {
  BluetoothConnection? _conn;

  /// Connect ke printer via MAC Address (contoh: "00:11:22:33:44:55")
  Future<void> connectBt(String macAddress) async {
    _conn = await BluetoothConnection.toAddress(macAddress)
        .timeout(const Duration(seconds: 8));
  }

  Future<void> disconnect() async {
    final c = _conn;
    _conn = null;

    if (c == null) return;

    // Banyak device nge-hang di close(). Paksa cepat, sisanya diabaikan.
    try {
      await c.close().timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // ignore
    }
  }

  Future<void> printOrder({
    required String btMacAddress,
    required Map<String, dynamic> order,
    required num paidAmount,
    required num changeAmount,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final bytes = await _buildReceiptBytes(
      order: order,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paperSize: paperSize,
    );

    await connectBt(btMacAddress);

    final c = _conn;
    if (c == null || !c.isConnected) {
      throw Exception('Bluetooth belum connect');
    }

    try {
      c.output.add(Uint8List.fromList(bytes));

      // optional: tunggu sebentar saja
      try { await c.output.allSent.timeout(const Duration(milliseconds: 300)); } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 150));

      // Penting: selesaikan output stream
      try { c.finish(); } catch (_) {}
    } finally {
      await disconnect();
    }

  }

  Future<List<int>> _buildReceiptBytes({
    required Map<String, dynamic> order,
    required num paidAmount,
    required num changeAmount,
    required PaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperSize, profile);

    final bytes = <int>[];

    final code = (order['booking_order_code'] ?? '-').toString();
    final customer = (order['customer_name'] ?? '-').toString();
    final total = _num(order['total_order_value']);

    bytes.addAll(gen.reset());
    final storeName  = (order['store_name'] ?? 'CAVAA').toString();
    final cashierName = (order['employee_name'] ?? '-').toString();

    bytes.addAll(gen.reset());
    bytes.addAll(gen.text(
      storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(gen.text('Struk Pembayaran', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.hr());

    bytes.addAll(gen.text('Order  : $code'));
    bytes.addAll(gen.text('Nama   : $customer'));
    bytes.addAll(gen.text('Kasir  : $cashierName'));
    bytes.addAll(gen.hr());


    final details = (order['order_details'] as List?) ?? [];
    for (final it in details) {
      final m = (it as Map).cast<String, dynamic>();
      final qty = _num(m['quantity']).toInt();
      final name = (m['product_name'] ?? 'Produk').toString();
      final basePrice = _num(m['base_price']);
      final promoAmount = _num(m['promo_amount']);
      final priceEach = (basePrice - promoAmount);
      final lineTotal = priceEach * qty;

      bytes.addAll(gen.text(name, styles: const PosStyles(bold: true)));
      bytes.addAll(gen.row([
        PosColumn(text: '$qty x ${_rupiah(priceEach)}', width: 8),
        PosColumn(text: _rupiah(lineTotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));

      final opts = (m['order_detail_options'] as List?) ?? [];
      for (final o in opts) {
        final om = (o as Map).cast<String, dynamic>();
        final optName = (om['option'] is Map ? (om['option']['name'] ?? '-') : '-').toString();
        final optPrice = _num(om['price']) * qty;
        bytes.addAll(gen.row([
          PosColumn(text: '  + $optName', width: 8),
          PosColumn(text: _rupiah(optPrice), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(gen.feed(1));
    }

    bytes.addAll(gen.hr());
    bytes.addAll(gen.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: _rupiah(total), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: 'BAYAR', width: 8),
      PosColumn(text: _rupiah(paidAmount), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: 'KEMBALI', width: 8),
      PosColumn(text: _rupiah(changeAmount), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]));

    bytes.addAll(gen.hr());
    bytes.addAll(gen.text('Terima kasih', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(2));
    // bytes.addAll(gen.cut());

    return bytes;
  }
}

// helpers lokal (biar receipt_printer.dart berdiri sendiri)
num _num(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;

String _rupiah(num n) {
  final v = n.toDouble().round();
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
