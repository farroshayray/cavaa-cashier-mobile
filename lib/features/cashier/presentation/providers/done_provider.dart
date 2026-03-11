import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';

class DoneProvider extends ChangeNotifier {
  final OrdersRepository repo;
  DoneProvider(this.repo);

  bool isLoading = false;
  String? error;

  String query = '';
  List<Map<String, dynamic>> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await repo.fetchOrdersData(
        tab: 'selesai',
        q: query.isEmpty ? null : query,
      );

      final raw = res['items'];
      if (raw is List) {
        items = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
}