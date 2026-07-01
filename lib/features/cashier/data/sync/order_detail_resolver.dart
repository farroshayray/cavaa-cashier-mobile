/// Resolves order detail maps for edit/detail UI without requiring network.
class OrderDetailResolver {
  OrderDetailResolver._();

  static bool hasEmbeddedDetails(Map<String, dynamic> row) {
    final details = row['order_details'];
    return details is List && details.isNotEmpty;
  }

  static Map<String, dynamic> detailFromListRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final serverId = _toInt(row['server_id'] ?? row['id']);
    if (serverId != null && serverId > 0) {
      map['id'] = serverId;
      map['server_id'] = serverId;
    }
    final clientUuid =
        (row['local_client_uuid'] ?? row['local_id'] ?? '').toString().trim();
    if (clientUuid.isNotEmpty) {
      map['local_client_uuid'] = clientUuid;
      map['local_id'] = clientUuid;
    }
    return map;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
