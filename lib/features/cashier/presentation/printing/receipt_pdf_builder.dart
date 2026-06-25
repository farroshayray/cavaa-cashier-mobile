import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '/core/config/env.dart';
import 'receipt_format_helpers.dart';

/// Mirror layout/data dari `resources/views/pages/employee/cashier/pdf/receipt.blade.php`
/// yang dipakai web customer saat download struk.
class ReceiptPdfBuilder {
  static const _pageWidth = 227.0; // 80mm thermal, sama seperti web
  static const _marginH = 10.0;
  static const _marginV = 10.0;
  static const _lineHeight = 13.0;

  static final _mono = pw.TextStyle(font: pw.Font.courier(), fontSize: 10);
  static final _monoBold =
      pw.TextStyle(font: pw.Font.courier(), fontSize: 10, fontWeight: pw.FontWeight.bold);
  static final _subtitle =
      pw.TextStyle(font: pw.Font.courier(), fontSize: 8, color: PdfColors.black);
  static final _thankYou =
      pw.TextStyle(font: pw.Font.courier(), fontSize: 8.5, color: PdfColors.black);
  static final _thankYouItalic = pw.TextStyle(
    font: pw.Font.courier(),
    fontSize: 8.5,
    fontStyle: pw.FontStyle.italic,
    color: PdfColors.black,
  );

  Future<Uint8List> buildReceiptPdf({
    required Map<String, dynamic> order,
    required num paidAmount,
    required num changeAmount,
  }) async {
    final payment = order['payment'] is Map
        ? Map<String, dynamic>.from(order['payment'] as Map)
        : null;
    final latestPayment = order['latest_payment'] is Map
        ? Map<String, dynamic>.from(order['latest_payment'] as Map)
        : null;

    final total = receiptNum(order['total_order_value']).toInt();
    final isPpnActive = receiptToBool(order['is_ppn_active']);
    final ppnPercent = receiptNum(order['ppn']);
    var grandTotalBeforeRounding = total;
    if (isPpnActive) {
      grandTotalBeforeRounding =
          (total + (total * ppnPercent / 100)).ceil();
    }

    final roundingAmount = receiptNum(
      order['cash_rounding_amount'] ??
          payment?['rounding_amount'] ??
          latestPayment?['rounding_amount'],
    ).toInt();
    final grandTotal = grandTotalBeforeRounding + roundingAmount;

    final storeName = (order['store_name'] ?? 'CAVAA').toString().trim();
    final storeAddress = (order['store_address'] ?? '').toString().trim();
    final customer = (order['customer_name'] ?? '—').toString();
    final code = (order['booking_order_code'] ?? '-').toString();
    final cashierName = (order['employee_name'] ?? '').toString().trim();
    final createdAt = receiptFormatTime(order['created_at']);
    final tableNo = _tableNo(order);
    final paymentMethod =
        receiptPaymentMethodLabel(order['payment_method']);

    final wifiShown = receiptToBool(order['store_is_wifi_shown']);
    final wifiUser = (order['store_wifi_user'] ?? '').toString().trim();
    final wifiPass = (order['store_wifi_password'] ?? '').toString().trim();

    final logo = await _loadPartnerLogo(order);
    final pageHeight = _estimatePageHeight(
      order: order,
      hasLogo: logo != null,
      hasAddress: storeAddress.isNotEmpty,
      hasTable: tableNo != null,
      hasCashier: cashierName.isNotEmpty,
      isPpnActive: isPpnActive,
      roundingAmount: roundingAmount,
      wifiShown: wifiShown,
      wifiUser: wifiUser,
      wifiPass: wifiPass,
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
          children: [
            if (logo != null) ...[
              pw.Center(
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(logo, width: 50, height: 50, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 6),
            ],
            pw.Center(
              child: pw.Text(storeName, style: _monoBold, textAlign: pw.TextAlign.center),
            ),
            if (storeAddress.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(storeAddress, style: _subtitle, textAlign: pw.TextAlign.center),
              ),
            ],
            _dashedSep(),
            _metaRow('Kode', code),
            _metaRow('Nama', customer),
            if (tableNo != null) _metaRow('Meja', tableNo),
            if (createdAt.isNotEmpty) _metaRow('Waktu', createdAt),
            if (cashierName.isNotEmpty) _metaRow('Kasir', cashierName),
            _dashedSep(),
            _itemsHeader(),
            ..._buildLineItems(order),
            _dashedSep(),
            _totalsBlock(
              total: total,
              isPpnActive: isPpnActive,
              ppnPercent: ppnPercent,
              roundingAmount: roundingAmount,
              grandTotal: grandTotal,
            ),
            _metaRow('Metode Pembayaran', paymentMethod),
            _metaRow('Jumlah Dibayarkan', receiptFormatMoney(paidAmount)),
            _metaRow('Kembalian', receiptFormatMoney(changeAmount)),
            if (wifiShown && (wifiUser.isNotEmpty || wifiPass.isNotEmpty)) ...[
              _dashedSep(),
              _wifiBox(wifiUser: wifiUser, wifiPass: wifiPass),
            ],
            _dashedSep(),
            pw.Center(
              child: pw.Text(
                'Terima kasih atas kunjungan Anda!',
                style: _thankYou,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Sampai jumpa kembali',
                style: _thankYouItalic,
                textAlign: pw.TextAlign.center,
              ),
            ),
            _dashedSep(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  String? _tableNo(Map<String, dynamic> order) {
    final table = order['table'];
    if (table is Map) {
      final no = table['table_no']?.toString().trim();
      if (no != null && no.isNotEmpty) return no;
    }
    final snap = order['table_no_snapshot']?.toString().trim();
    if (snap != null && snap.isNotEmpty && snap != '-') return snap;
    return null;
  }

  Future<pw.MemoryImage?> _loadPartnerLogo(Map<String, dynamic> order) async {
    final partner = order['partner'];
    if (partner is! Map) return null;

    final logo = partner['logo']?.toString().trim();
    if (logo == null || logo.isEmpty) return null;

    final url = logo.startsWith('http') ? logo : '${Env.baseUrl}/storage/$logo';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}

    return null;
  }

  double _estimatePageHeight({
    required Map<String, dynamic> order,
    required bool hasLogo,
    required bool hasAddress,
    required bool hasTable,
    required bool hasCashier,
    required bool isPpnActive,
    required int roundingAmount,
    required bool wifiShown,
    required String wifiUser,
    required String wifiPass,
  }) {
    var lines = 18.0;
    if (hasLogo) lines += 4;
    if (hasAddress) lines += 1;
    if (hasTable) lines += 1;
    if (hasCashier) lines += 1;
    if (isPpnActive) lines += 2;
    if (roundingAmount > 0) lines += 1;
    if (wifiShown && (wifiUser.isNotEmpty || wifiPass.isNotEmpty)) {
      lines += 4;
      if (wifiUser.isNotEmpty) lines += 1;
      if (wifiPass.isNotEmpty) lines += 1;
    }

    final details = (order['order_details'] as List?) ?? [];
    for (final it in details) {
      lines += 1.8;
      final m = (it as Map).cast<String, dynamic>();
      final opts = (m['order_detail_options'] as List?) ?? [];
      lines += opts.length * 0.9;
    }

    const minHeight = 280.0;
    const maxHeight = 1600.0;
    return ((_marginV * 2) + (lines * _lineHeight)).clamp(minHeight, maxHeight);
  }

  pw.Widget _dashedSep() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        '-' * 34,
        style: _subtitle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: _pageWidth * 0.34,
            child: pw.Text(label, style: _mono),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _mono,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsHeader() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Text('Item', style: _monoBold)),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: _subtotalColWidth,
            child: pw.Text('Subtotal', style: _monoBold, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  static const _subtotalColWidth = 76.0;

  List<pw.Widget> _buildLineItems(Map<String, dynamic> order) {
    final widgets = <pw.Widget>[];
    final details = (order['order_details'] as List?) ?? [];

    for (final it in details) {
      final m = Map<String, dynamic>.from(it as Map);
      final qty = receiptNum(m['quantity']).toInt();
      final name = receiptProductName(m);
      final withPromo =
          (receiptNum(m['base_price']) - receiptNum(m['promo_amount'])).toInt();
      final optSum = receiptNum(m['options_price']).toInt();
      final line = qty * (withPromo + optSum);

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$qty x $name ${receiptFormatMoney(withPromo)}',
                      style: _mono,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: _subtotalColWidth,
                child: pw.Text(
                  receiptFormatMoney(line),
                  style: _mono,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );

      final opts = (m['order_detail_options'] as List?) ?? [];
      for (final o in opts) {
        final om = Map<String, dynamic>.from(o as Map);
        final optName = receiptOptionName(om);
        final optPrice = receiptNum(om['price']).toInt();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 2, bottom: 2),
            child: pw.Text(
              '- $optName ${receiptFormatMoney(optPrice)}',
              style: _mono,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  pw.Widget _totalsBlock({
    required int total,
    required bool isPpnActive,
    required num ppnPercent,
    required int roundingAmount,
    required int grandTotal,
  }) {
    final rows = <pw.Widget>[];

    if (isPpnActive) {
      rows
        ..add(_totalRow('TOTAL', receiptFormatMoney(total)))
        ..add(_totalRow('PPN', '${receiptFormatPercent(ppnPercent)}%'));
    }
    if (roundingAmount > 0) {
      rows.add(_totalRow('PEMBULATAN CASH', receiptFormatMoney(roundingAmount)));
    }
    rows.add(_totalRow('GRAND TOTAL', receiptFormatMoney(grandTotal), bold: true));

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.8),
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(children: rows),
    );
  }

  pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = bold ? _monoBold : _mono;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ],
      ),
    );
  }

  pw.Widget _wifiBox({
    required String wifiUser,
    required String wifiPass,
  }) {
    return pw.Column(
      children: [
        pw.Center(child: pw.Text('WIFI', style: _monoBold)),
        pw.SizedBox(height: 6),
        if (wifiUser.isNotEmpty)
          pw.Center(
            child: pw.Text('Username: $wifiUser', style: _subtitle),
          ),
        if (wifiPass.isNotEmpty)
          pw.Center(
            child: pw.Text('Password: $wifiPass', style: _subtitle),
          ),
      ],
    );
  }
}
