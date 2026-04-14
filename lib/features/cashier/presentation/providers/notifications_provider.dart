import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncomingOrderNotif {
  final int id;
  final String code;
  final String customer;
  final num total;
  final String status;
  final String createdAt;

  const IncomingOrderNotif({
    required this.id,
    required this.code,
    required this.customer,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory IncomingOrderNotif.fromMap(Map<String, dynamic> m) {
    num parseNum(dynamic v) =>
        (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;

    return IncomingOrderNotif(
      id: (m['id'] is int)
          ? m['id'] as int
          : int.tryParse(
                (m['id'] ?? m['order_id'] ?? m['booking_order_id'] ?? '')
                    .toString(),
              ) ??
              0,
      code: (m['code'] ?? m['booking_order_code'] ?? '').toString(),
      customer: (m['customer'] ?? m['customer_name'] ?? '').toString(),
      total: parseNum(m['total'] ?? m['total_order_value']),
      status: (m['order_status'] ?? m['status'] ?? '').toString(),
      createdAt: (m['created_at'] ?? m['received_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'customer': customer,
      'total': total,
      'order_status': status,
      'created_at': createdAt,
    };
  }

  String get uniqueKey => '${id}_${code}_${status}';
}

class NotificationsProvider extends ChangeNotifier {
  static const String _storageKey = 'cashier_notifications';
  static const String _unreadKey = 'cashier_notifications_unread';

  final List<IncomingOrderNotif> _items = [];
  int _unread = 0;

  List<IncomingOrderNotif> get items => List.unmodifiable(_items);
  int get unread => _unread;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    final loaded = <IncomingOrderNotif>[];

    for (final e in rawList) {
      try {
        final decoded = jsonDecode(e);
        if (decoded is Map<String, dynamic>) {
          loaded.add(IncomingOrderNotif.fromMap(decoded));
        } else if (decoded is Map) {
          loaded.add(
            IncomingOrderNotif.fromMap(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {}
    }

    _items
      ..clear()
      ..addAll(loaded);

    _unread = prefs.getInt(_unreadKey) ?? _items.length;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _items.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_storageKey, rawList);
    await prefs.setInt(_unreadKey, _unread);
  }

  Future<void> push(IncomingOrderNotif n) async {
    final exists = _items.any((e) => e.uniqueKey == n.uniqueKey);
    if (exists) return;

    _items.insert(0, n);

    if (_items.length > 200) {
      _items.removeRange(200, _items.length);
    }

    _unread += 1;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _unread = 0;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _unread = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_unreadKey);

    notifyListeners();
  }

  Future<void> pushFromPusher(Map<String, dynamic> data) async {
    await push(IncomingOrderNotif.fromMap(data));
  }

  Future<void> pushFromFcm(Map<String, dynamic> data) async {
    await push(IncomingOrderNotif.fromMap(data));
  }
}
