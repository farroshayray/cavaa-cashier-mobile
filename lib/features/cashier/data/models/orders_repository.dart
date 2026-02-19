import '../../../../core/storage/secure_storage_service.dart';
import '../orders_api.dart';

class OrdersRepository {
  final OrdersApi api;
  final SecureStorageService storage;

  OrdersRepository({required this.api, required this.storage});

  Future<Map<String, dynamic>> fetchOrdersData({
    required String tab,
    String? q,
  }) async {
    final token = await storage.getToken(); // sesuaikan method kamu
    if (token == null || token.isEmpty) throw Exception('Token kosong');

    return api.getOrdersData(
      token: token,
      tab: tab,
      q: q,
    );
  }

  // ✅ NEW
  Future<Map<String, dynamic>> fetchOrderDetail(int id) async {
    final token = await storage.getToken(); // sesuaikan method kamu
    if (token == null || token.isEmpty) throw Exception('Token kosong');

    return api.orderDetail(token: token, id: id);
  }

  Future<Map<String, dynamic>> fetchPrintDetail(int id) async {
    final token = await storage.getToken(); // sesuaikan method kamu
    if (token == null || token.isEmpty) throw Exception('Token kosong');

    return api.printDetail(token: token, id: id);
  }

  Future<Map<String, dynamic>> softDeleteOrder(int id) async {
    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong');
    }

    return await api.softDeleteOrder(
      token: token,
      id: id,
    );
  }

  Future<Map<String, dynamic>> paymentOrder({
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? note,
    String? email,
  }) async {
    final token = await storage.getToken(); // sesuaikan nama method kamu
    if (token == null || token.trim().isEmpty) {
      throw Exception('Token kosong, silakan login ulang');
    }

    return api.paymentOrder(
      token: token,
      id: id,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      note: note,
      email: email,
    );
  }

    Future<Map<String, dynamic>> processOrder(int id) async {
      final token = await storage.getToken();
      if (token == null || token.trim().isEmpty) throw Exception('Token kosong');
      return api.processOrder(token: token, id: id);
    }

    Future<Map<String, dynamic>> cancelProcessOrder(int id) async {
      final token = await storage.getToken();
      if (token == null || token.trim().isEmpty) throw Exception('Token kosong');
      return api.cancelProcessOrder(token: token, id: id);
    }

    Future<Map<String, dynamic>> finishOrder(int id, {String? note}) async {
      final token = await storage.getToken();
      if (token == null || token.trim().isEmpty) throw Exception('Token kosong');
      return api.finishOrder(token: token, id: id, note: note);
    }

}

