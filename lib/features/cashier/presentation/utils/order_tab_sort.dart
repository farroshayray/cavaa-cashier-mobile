/// Shared tab list ordering: oldest first (newest at bottom).
int compareOrdersOldestFirst(Map<String, dynamic> a, Map<String, dynamic> b) {
  final aCreated = DateTime.tryParse(
    (a['sort_time'] ?? a['created_at'] ?? '').toString(),
  );
  final bCreated = DateTime.tryParse(
    (b['sort_time'] ?? b['created_at'] ?? '').toString(),
  );

  if (aCreated == null && bCreated == null) {
    return _orderTabSortTieBreak(a, b);
  }
  if (aCreated == null) return -1;
  if (bCreated == null) return 1;

  final cmp = aCreated.compareTo(bCreated);
  if (cmp != 0) return cmp;
  return _orderTabSortTieBreak(a, b);
}

int _orderTabSortTieBreak(Map<String, dynamic> a, Map<String, dynamic> b) {
  final aUuid = (a['client_uuid'] ?? '').toString();
  final bUuid = (b['client_uuid'] ?? '').toString();
  if (aUuid.isNotEmpty && bUuid.isNotEmpty) {
    return aUuid.compareTo(bUuid);
  }

  final aId = '${a['server_id'] ?? a['id'] ?? ''}';
  final bId = '${b['server_id'] ?? b['id'] ?? ''}';
  return aId.compareTo(bId);
}
