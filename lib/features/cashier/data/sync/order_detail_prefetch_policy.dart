/// Rules for when background order-detail prefetch is worth an HTTP call.
class OrderDetailPrefetchPolicy {
  OrderDetailPrefetchPolicy._();

  static const int maxPerLoad = 5;

  static bool shouldPrefetch(Map<String, dynamic> mirrorRow) {
    final serverId = _toInt(mirrorRow['id']);
    if (serverId == null || serverId <= 0) return false;

    if (_toBool(mirrorRow['sync_dirty'])) return true;

    final details = mirrorRow['order_details'];
    if (details is! List || details.isEmpty) return true;

    return false;
  }

  static List<Map<String, dynamic>> selectForPrefetch(
    List<Map<String, dynamic>> mirrorRows, {
    int maxCount = maxPerLoad,
  }) {
    final selected = <Map<String, dynamic>>[];
    for (final row in mirrorRows) {
      if (selected.length >= maxCount) break;
      if (shouldPrefetch(row)) {
        selected.add(row);
      }
    }
    return selected;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
