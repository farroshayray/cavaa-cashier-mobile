import 'dart:convert';

import 'receipt_format_helpers.dart';

/// Normalizes order payload for thermal/PDF receipt rendering.
Map<String, dynamic> enrichReceiptOrder(Map<String, dynamic> raw) {
  final order = Map<String, dynamic>.from(raw);

  final partner = order['partner'];
  if (partner is Map) {
    final p = Map<String, dynamic>.from(partner);
    order['store_name'] ??= p['name'];
    order['store_address'] ??= _partnerAddress(p);
    order['store_is_wifi_shown'] ??= p['is_wifi_shown'];
    order['store_wifi_user'] ??= p['user_wifi'];
    order['store_wifi_password'] ??= p['pass_wifi'];
  }

  final wifiSnapshot = order['wifi_snapshot'];
  if (wifiSnapshot is Map) {
    final snap = Map<String, dynamic>.from(wifiSnapshot);
    if (order['store_is_wifi_shown'] == null) {
      order['store_is_wifi_shown'] = snap['wifi_shown'];
    }
    final user = (order['store_wifi_user'] ?? '').toString().trim();
    if (user.isEmpty) {
      order['store_wifi_user'] = snap['wifi_ssid'] ?? snap['wifi_user'];
    }
    final pass = (order['store_wifi_password'] ?? '').toString().trim();
    if (pass.isEmpty) {
      order['store_wifi_password'] = snap['wifi_password'];
    }
    final address = snap['store_address']?.toString();
    if (address != null &&
        address.trim().isNotEmpty &&
        (order['store_address'] ?? '').toString().trim().isEmpty) {
      order['store_address'] = address;
    }
  }

  _decodeWifiJsonField(order);

  return order;
}

void _decodeWifiJsonField(Map<String, dynamic> order) {
  if (order['wifi_snapshot'] is Map) return;
  final raw = order['wifi_snapshot_json'] ?? order['wifiSnapshotJson'];
  if (raw is! String || raw.trim().isEmpty) return;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      order['wifi_snapshot'] = Map<String, dynamic>.from(decoded);
      final snap = order['wifi_snapshot'] as Map<String, dynamic>;
      order['store_is_wifi_shown'] ??= snap['wifi_shown'];
      order['store_wifi_user'] ??= snap['wifi_ssid'] ?? snap['wifi_user'];
      order['store_wifi_password'] ??= snap['wifi_password'];
      order['store_address'] ??= snap['store_address'];
    }
  } catch (_) {}
}

String _partnerAddress(Map<String, dynamic> partner) {
  final parts = <String>[
    partner['address']?.toString() ?? '',
    partner['urban_village']?.toString() ?? '',
    partner['subdistrict']?.toString() ?? '',
    partner['city']?.toString() ?? '',
  ].where((e) => e.trim().isNotEmpty).toList();

  return parts.join(', ');
}

bool receiptWifiShown(Map<String, dynamic> order) {
  return receiptNum(order['store_is_wifi_shown']).toInt() == 1 ||
      receiptToBool(order['store_is_wifi_shown']);
}

String receiptPaidAtRaw(Map<String, dynamic> order) {
  final payment = order['payment'];
  if (payment is Map && payment['updated_at'] != null) {
    return payment['updated_at'].toString();
  }
  final latest = order['latest_payment'];
  if (latest is Map && latest['updated_at'] != null) {
    return latest['updated_at'].toString();
  }
  return '';
}
