import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'receipt_format_helpers.dart';
import 'receipt_order_enricher.dart';
import 'receipt_totals.dart';

/// PDF receipt aligned with thermal output in [ReceiptPrinter].
class ReceiptPdfBuilder {
  static const _pageWidth = 227.0;
  static const _marginH = 10.0;
  static const _marginV = 10.0;
  static const _lineHeight = 13.0;

  static final _mono = pw.TextStyle(font: pw.Font.courier(), fontSize: 10);
  static final _monoBold =
      pw.TextStyle(font: pw.Font.courier(), fontSize: 10, fontWeight: pw.FontWeight.bold);

  Future<Uint8List> buildReceiptPdf({
    required Map<String, dynamic> order,
    ReceiptTotals? totals,
  }) async {
    final resolvedTotals = totals ?? buildReceiptTotals(order);
    final widgets = _buildContent(order: order, totals: resolvedTotals);
    final pageHeight = _estimatePageHeight(
      order: order,
      totals: resolvedTotals,
      widgetCount: widgets.length,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _pageWidth,
          pageHeight,
          marginLeft: _marginH,
          marginRight: _marginH,
          marginTop: _marginV,
          marginBottom: _marginV + 12,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: widgets,
        ),
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _buildContent({
    required Map<String, dynamic> order,
    required ReceiptTotals totals,
  }) {
    final code = (order['booking_order_code'] ?? '-').toString();
    final customer = (order['customer_name'] ?? '-').toString();
    final storeName = (order['store_name'] ?? 'CAVAA').toString().trim();
    final storeAddress = (order['store_address'] ?? '').toString().trim();
    final cashierName = (order['employee_name'] ?? '-').toString();
    final paidAtStr = receiptFormatTime(receiptPaidAtRaw(order));

    final wifiShown = receiptWifiShown(order);
    final wifiUser = (order['store_wifi_user'] ?? '').toString().trim();
    final wifiPass = (order['store_wifi_password'] ?? '').toString().trim();

    return [
      pw.Center(
        child: pw.Text(storeName, style: _monoBold, textAlign: pw.TextAlign.center),
      ),
      pw.SizedBox(height: 4),
      pw.Center(child: pw.Text('=' * 28, style: _mono)),
      if (storeAddress.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(storeAddress, style: _mono, textAlign: pw.TextAlign.center),
        ),
      ],
      pw.SizedBox(height: 2),
      pw.Center(
        child: pw.Text('Struk Pembayaran', style: _mono, textAlign: pw.TextAlign.center),
      ),
      _hr(),
      _line('Order  : $code'),
      if (paidAtStr.isNotEmpty) _line('Waktu  : $paidAtStr'),
      _line('Nama   : $customer'),
      _line('Kasir  : $cashierName'),
      _hr(),
      ..._buildLineItems(order),
      _hr(),
      _amountRow('TOTAL', receiptRupiah(totals.subtotal.ceil())),
      if (totals.isPpnActive)
        _amountRow(
          'PPN (${receiptFormatPercent(totals.ppnPercent)}%)',
          receiptRupiah(totals.ppnAmount.ceil()),
        ),
      if (totals.roundingAmount > 0)
        _amountRow('PEMBULATAN', receiptRupiah(totals.roundingAmount)),
      _amountRow('GRAND TOTAL', receiptRupiah(totals.grandTotal), bold: true),
      _amountRow('BAYAR', receiptRupiah(totals.paid)),
      _amountRow('KEMBALI', receiptRupiah(totals.change)),
      if (wifiShown && (wifiUser.isNotEmpty || wifiPass.isNotEmpty)) ...[
        _hr(),
        pw.Text('WiFi', style: _monoBold),
        if (wifiUser.isNotEmpty) _line('User : $wifiUser'),
        if (wifiPass.isNotEmpty) _line('Pass : $wifiPass'),
        _hr(),
      ],
      _hr(),
      pw.Center(
        child: pw.Text('Terima kasih', style: _mono, textAlign: pw.TextAlign.center),
      ),
      pw.SizedBox(height: 8),
      pw.Center(
        child: pw.Text('-' * 29, style: _mono, textAlign: pw.TextAlign.center),
      ),
    ];
  }

  List<pw.Widget> _buildLineItems(Map<String, dynamic> order) {
    final widgets = <pw.Widget>[];
    final details = (order['order_details'] as List?) ?? [];

    for (final it in details) {
      final m = Map<String, dynamic>.from(it as Map);
      final qty = receiptNum(m['quantity']).toInt();
      final name = (m['product_name'] ?? 'Produk').toString();
      final basePrice = receiptNum(m['base_price']);
      final promoAmount = receiptNum(m['promo_amount']);
      final priceEach = basePrice - promoAmount;
      final lineTotal = priceEach * qty;

      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.Text(name, style: _monoBold));
      widgets.add(
        _amountRow('$qty x ${receiptRupiah(priceEach)}', receiptRupiah(lineTotal)),
      );

      final opts = (m['order_detail_options'] as List?) ?? [];
      for (final o in opts) {
        final om = Map<String, dynamic>.from(o as Map);
        final optName = receiptOptionName(om);
        final optPrice = receiptNum(om['price']) * qty;
        widgets.add(
          _amountRow('  + $optName', receiptRupiah(optPrice)),
        );
      }
    }

    return widgets;
  }

  pw.Widget _line(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Text(text, style: _mono),
    );
  }

  pw.Widget _hr() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text('-' * 34, style: _mono),
    );
  }

  pw.Widget _amountRow(String label, String value, {bool bold = false}) {
    final style = bold ? _monoBold : _mono;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ],
      ),
    );
  }

  double _estimatePageHeight({
    required Map<String, dynamic> order,
    required ReceiptTotals totals,
    required int widgetCount,
  }) {
    var lines = 16.0;
    if ((order['store_address'] ?? '').toString().trim().isNotEmpty) lines += 1;
    if (receiptFormatTime(receiptPaidAtRaw(order)).isNotEmpty) lines += 1;
    if (totals.isPpnActive) lines += 1;
    if (totals.roundingAmount > 0) lines += 1;

    final wifiShown = receiptWifiShown(order);
    final wifiUser = (order['store_wifi_user'] ?? '').toString().trim();
    final wifiPass = (order['store_wifi_password'] ?? '').toString().trim();
    if (wifiShown && (wifiUser.isNotEmpty || wifiPass.isNotEmpty)) {
      lines += 4;
    }

    final details = (order['order_details'] as List?) ?? [];
    for (final it in details) {
      lines += 2.2;
      final m = (it as Map).cast<String, dynamic>();
      final opts = (m['order_detail_options'] as List?) ?? [];
      lines += opts.length * 1.1;
    }

    lines += widgetCount * 0.15;

    const minHeight = 320.0;
    const maxHeight = 2000.0;
    final estimated = (_marginV * 2) + (lines * _lineHeight);
    return (estimated * 1.2).clamp(minHeight, maxHeight);
  }
}
