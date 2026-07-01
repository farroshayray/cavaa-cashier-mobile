num receiptNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;

String receiptRupiah(num n) {
  final s = n.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}

String receiptFormatTime(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty) return '';

  final dt = DateTime.tryParse(s);
  if (dt == null) return s;

  final local = dt.toLocal();
  String two(int x) => x.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

bool receiptToBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
}

String receiptFormatPercent(num n) {
  return n % 1 == 0 ? n.toInt().toString() : n.toString();
}

String receiptFormatMoney(num n) => 'Rp ${receiptRupiah(n)}';

String receiptPaymentMethodLabel(dynamic method) {
  final raw = (method ?? '').toString().trim();
  if (raw.isEmpty) return '-';

  switch (raw.toLowerCase()) {
    case 'manual_tf':
      return 'Transfer';
    case 'manual_ewallet':
      return 'E-wallet';
    case 'manual_qris':
      return 'QR Statis';
    default:
      return raw;
  }
}

String receiptProductName(Map<String, dynamic> item) {
  if (item['product_name'] != null &&
      item['product_name'].toString().trim().isNotEmpty) {
    return item['product_name'].toString();
  }

  final partnerProduct = item['partner_product'];
  if (partnerProduct is Map && partnerProduct['name'] != null) {
    return partnerProduct['name'].toString();
  }

  return 'Produk';
}

String receiptOptionName(Map<String, dynamic> option) {
  final nested = option['option'];
  if (nested is Map && nested['name'] != null) {
    return nested['name'].toString();
  }

  final fallback = option['partner_product_option_name'] ?? option['name'];
  if (fallback != null && fallback.toString().trim().isNotEmpty) {
    return fallback.toString();
  }

  return '-';
}

String receiptOptionParentName(Map<String, dynamic> option) {
  final nested = option['option'];
  if (nested is Map) {
    final parent = nested['parent'];
    if (parent is Map && parent['name'] != null) {
      return parent['name'].toString();
    }
  }

  final fallback = option['parent_name'];
  if (fallback != null && fallback.toString().trim().isNotEmpty) {
    return fallback.toString();
  }

  return '';
}
