import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';

class ProcessProvider extends ChangeNotifier {
  final OrdersRepository repo;
  ProcessProvider(this.repo);

  bool isLoading = false;
  String? error;

  String query = '';
  List<Map<String, dynamic>> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await repo.storage.getToken();
      if (token == null || token.isEmpty) throw Exception('Token tidak ditemukan');

      final res = await repo.api.getOrdersData(
        token: token,
        tab: 'proses',
        q: query.isEmpty ? null : query,
      );

      final raw = res['items'];
      if (raw is List) {
        items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        items = [];
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    return repo.fetchOrderDetail(id);
  }

  Future<Map<String, dynamic>> getPrintDetail(int id) async {
    return repo.fetchPrintDetail(id);
  }


  final Set<int> actionLoadingIds = <int>{};

  bool isActionLoading(int id) => actionLoadingIds.contains(id);

  void _setActionLoading(int id, bool v) {
    if (v) actionLoadingIds.add(id);
    else actionLoadingIds.remove(id);
    notifyListeners();
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  int _indexById(int id) {
    return items.indexWhere((e) => _toId(e['id']) == id);
  }

  void _setStatusLocal(int id, String status) {
    final idx = _indexById(id);
    if (idx < 0) return;
    items[idx] = {...items[idx], 'order_status': status};
    notifyListeners();
  }
  Future<Map<String, dynamic>> actionProcess(int id) async {
    _setActionLoading(id, true);
    try {
      final res = await repo.processOrder(id);

      // backend kamu ada kemungkinan return: status=warning + already_processed=true
      final status = (res['status'] ?? '').toString();
      if (status == 'warning' || res['already_processed'] == true) {
        // kalau sudah diproses tim lain, refresh list biar sinkron
        await load();
        return res;
      }

      // sukses: ubah lokal jadi PROCESSED
      _setStatusLocal(id, 'PROCESSED');
      return res;
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<Map<String, dynamic>> actionCancelProcess(int id) async {
    _setActionLoading(id, true);
    try {
      final res = await repo.cancelProcessOrder(id);

      // ❗ HANYA update status lokal
      _setStatusLocal(id, 'PAID');

      return res;
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<Map<String, dynamic>> actionFinish(int id, {String? note}) async {
    _setActionLoading(id, true);
    try {
      final res = await repo.finishOrder(id, note: note);

      // sukses: bisa remove dari list proses, atau set SERVED lalu refresh
      // items.removeWhere((e) => _toId(e['id']) == id);
      // notifyListeners();
      _setStatusLocal(id, 'SERVED');
      return res;
    } finally {
      _setActionLoading(id, false);
    }
  }


}
