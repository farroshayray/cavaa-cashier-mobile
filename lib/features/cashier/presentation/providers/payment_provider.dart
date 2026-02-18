import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final OrdersRepository repo;
  PaymentProvider(this.repo);

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
        tab: 'pembayaran',
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

  Future<void> deleteOrder(int id) async {
    // opsional: set loading khusus delete, tapi minimal gini dulu
    try {
      await repo.softDeleteOrder(id); // kita buat di repository
      // setelah delete sukses, refresh list
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> payOrder({
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? note,
    String? email,
  }) async {
    return repo.paymentOrder(
      id: id,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      note: note,
      email: email,
    );
  }
}
