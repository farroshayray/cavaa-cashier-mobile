import 'dart:convert';

import 'receipt_order_enricher.dart';

/// Hydrates mirror/offline order maps for kitchen list + receipt printing.
Map<String, dynamic> enrichOfflinePrintOrder(Map<String, dynamic> raw) {
  final order = Map<String, dynamic>.from(raw);

  _decodeWifiSnapshotJson(order);

  order['store_name'] ??= order['partner_name']?.toString();

  final snap = order['wifi_snapshot'];
  if (snap is Map) {
    final address = snap['store_address']?.toString();
    if (address != null && address.trim().isNotEmpty) {
      order['store_address'] ??= address;
    }
  }

  return enrichReceiptOrder(order);
}

void _decodeWifiSnapshotJson(Map<String, dynamic> order) {
  if (order['wifi_snapshot'] is Map) return;

  final rawJson = order['wifi_snapshot_json'] ?? order['wifiSnapshotJson'];
  if (rawJson is! String || rawJson.trim().isEmpty) return;

  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is Map) {
      order['wifi_snapshot'] = Map<String, dynamic>.from(decoded);
    }
  } catch (_) {}
}
