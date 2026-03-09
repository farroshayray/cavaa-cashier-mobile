import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class OrderListPrinter {
  Future<Uint8List> buildOrderListBytes({
    required Map<String, dynamic> order,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperSize, profile);
    final bytes = <int>[];

    final code = (order['booking_order_code'] ?? '-').toString();
    final customer = (order['customer_name'] ?? '-').toString();
    final table = (order['table'] is Map
            ? (order['table']['table_no'] ?? '-')
            : '-')
        .toString();

    final details = (order['order_details'] as List?) ?? [];

    // Grouping by category
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final it in details) {
      final m = (it as Map).cast<String, dynamic>();
      final category = _categoryNameOf(m);

      grouped.putIfAbsent(category, () => <Map<String, dynamic>>[]);
      grouped[category]!.add(m);
    }

    bytes.addAll(gen.reset());

    // Kalau ingin urut kategori berdasarkan nama
    final sortedKeys = grouped.keys.toList()..sort();

    for (final category in sortedKeys) {
      final items = grouped[category] ?? [];

      // Header per kategori
      bytes.addAll(gen.text(
        code,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      ));

      bytes.addAll(gen.feed(1));

      bytes.addAll(gen.text(
        'Nama : $customer',
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
        ),
      ));

      bytes.addAll(gen.text(
        'Meja : $table',
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
        ),
      ));

      bytes.addAll(gen.hr());

      bytes.addAll(gen.text(
        category.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          width: PosTextSize.size2,
          height: PosTextSize.size1,
        ),
      ));

      bytes.addAll(gen.hr());

      for (final m in items) {
        final qty = _num(m['quantity']).toInt();

        final name = (m['product_name'] ??
                (m['partner_product'] is Map
                    ? (m['partner_product']['name'] ?? 'Produk')
                    : 'Produk'))
            .toString();

        final note = (m['customer_note'] ?? '').toString().trim();
        final opts = (m['order_detail_options'] as List?) ?? [];

        bytes.addAll(gen.text(
          '$qty x $name',
          styles: const PosStyles(
            bold: true,
          ),
        ));

        if (opts.isNotEmpty) {
          for (final o in opts) {
            final om = (o as Map).cast<String, dynamic>();
            final optName =
                (om['option'] is Map ? (om['option']['name'] ?? '-') : '-')
                    .toString();

            final parentName = (om['option'] is Map &&
                    (om['option']['parent'] is Map) &&
                    om['option']['parent']['name'] != null)
                ? om['option']['parent']['name'].toString()
                : '';

            final line = parentName.isNotEmpty
                ? '  - $parentName: $optName'
                : '  - $optName';

            bytes.addAll(gen.text(line));
          }
        }

        if (note.isNotEmpty) {
          bytes.addAll(gen.text('  * Catatan: $note'));
        }

        bytes.addAll(gen.feed(1));
      }

      // garis putus-putus pemisah antar kategori
      bytes.addAll(gen.text(
        '------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      ));

      bytes.addAll(gen.feed(2));
    }

    return Uint8List.fromList(bytes);
  }
}

String _categoryNameOf(Map<String, dynamic> m) {
  if (m['partner_product'] is Map &&
      m['partner_product']['category'] is Map &&
      m['partner_product']['category']['category_name'] != null) {
    return m['partner_product']['category']['category_name'].toString().trim();
  }

  return 'Tanpa Kategori';
}

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}