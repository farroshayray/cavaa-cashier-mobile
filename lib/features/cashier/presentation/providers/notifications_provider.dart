import 'package:flutter/foundation.dart';

class IncomingOrderNotif {
  final int id;
  final String code;
  final String customer;
  final num total;
  final String status;
  final String createdAt;

  IncomingOrderNotif({
    required this.id,
    required this.code,
    required this.customer,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory IncomingOrderNotif.fromMap(Map<String, dynamic> m) {
    num parseNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;

    return IncomingOrderNotif(
      id: (m['id'] is int) ? m['id'] as int : int.tryParse(m['id']?.toString() ?? '') ?? 0,
      code: (m['code'] ?? '').toString(),
      customer: (m['customer'] ?? '').toString(),
      total: parseNum(m['total']),
      status: (m['order_status'] ?? '').toString(),
      createdAt: (m['created_at'] ?? '').toString(),
    );
  }
}

class NotificationsProvider extends ChangeNotifier {
  final List<IncomingOrderNotif> _items = [];
  int _unread = 0;

  List<IncomingOrderNotif> get items => List.unmodifiable(_items);
  int get unread => _unread;

  void push(IncomingOrderNotif n) {
    // prepend
    _items.insert(0, n);
    _unread += 1;
    notifyListeners();
  }

  void markAllRead() {
    _unread = 0;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _unread = 0;
    notifyListeners();
  }

  void pushFromPusher(Map<String, dynamic> data) {
    // sesuaikan dengan model notif kamu
    push(
      IncomingOrderNotif.fromMap(data),
    );
  }
}
