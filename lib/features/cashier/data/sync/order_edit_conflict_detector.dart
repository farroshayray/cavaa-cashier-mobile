import '/features/cashier/presentation/utils/order_edit_utils.dart';

class OrderEditConflictResult {
  const OrderEditConflictResult({
    required this.hasDivergence,
    this.editableDiffs = const [],
    this.lockedConflicts = const [],
  });

  final bool hasDivergence;
  final List<String> editableDiffs;
  final List<String> lockedConflicts;
}

/// Compares local mirror line items with a server snapshot for manual conflict UI.
class OrderEditConflictDetector {
  OrderEditConflictDetector._();

  static OrderEditConflictResult compare({
    required List<Map<String, dynamic>> localDetails,
    required List<Map<String, dynamic>> serverDetails,
  }) {
    final editableDiffs = <String>[];
    final lockedConflicts = <String>[];

    final serverById = <int, Map<String, dynamic>>{};
    for (final raw in serverDetails) {
      final id = _detailId(raw);
      if (id != null) serverById[id] = raw;
    }

    final localIds = <int>{};
    for (final local in localDetails) {
      final id = _detailId(local);
      if (id == null) {
        editableDiffs.add('Baris baru lokal: ${_label(local)}');
        continue;
      }
      localIds.add(id);

      final server = serverById[id];
      if (server == null) {
        if (isOrderDetailLocked(local)) {
          lockedConflicts.add('Baris lokal terkunci tidak ada di server: ${_label(local)}');
        } else {
          editableDiffs.add('Baris dihapus lokal: ${_label(local)}');
        }
        continue;
      }

      final localQty = _qty(local);
      final serverQty = _qty(server);
      if (localQty != serverQty) {
        final label = _label(local);
        if (isOrderDetailLocked(local) || isOrderDetailLocked(server)) {
          lockedConflicts.add('$label qty lokal=$localQty server=$serverQty');
        } else {
          editableDiffs.add('$label qty lokal=$localQty server=$serverQty');
        }
      }

      final localNote = (local['customer_note'] ?? '').toString();
      final serverNote = (server['customer_note'] ?? '').toString();
      if (localNote != serverNote && !isOrderDetailLocked(local)) {
        editableDiffs.add('${_label(local)} catatan berbeda');
      }
    }

    for (final server in serverDetails) {
      final id = _detailId(server);
      if (id == null || localIds.contains(id)) continue;
      if (isOrderDetailLocked(server)) {
        lockedConflicts.add('Baris server baru/terkunci: ${_label(server)}');
      } else {
        editableDiffs.add('Baris baru di server: ${_label(server)}');
      }
    }

    return OrderEditConflictResult(
      hasDivergence: editableDiffs.isNotEmpty || lockedConflicts.isNotEmpty,
      editableDiffs: editableDiffs,
      lockedConflicts: lockedConflicts,
    );
  }

  static int? _detailId(Map<String, dynamic> row) {
    return _toInt(row['id'] ?? row['server_id'] ?? row['server_order_detail_id']);
  }

  static int _qty(Map<String, dynamic> row) {
    return _toInt(row['quantity'] ?? row['qty']) ?? 0;
  }

  static String _label(Map<String, dynamic> row) {
    return (row['product_name'] ?? row['product_name_snapshot'] ?? 'Item').toString();
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
