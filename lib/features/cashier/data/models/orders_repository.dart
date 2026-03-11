import '../orders_api.dart';

class OrdersRepository {
  final OrdersApi api;

  OrdersRepository({required this.api});

  Future<Map<String, dynamic>> fetchOrdersData({
    required String tab,
    String? q,
  }) async {
    return api.getOrdersData(
      tab: tab,
      q: q,
    );
  }

  Future<Map<String, dynamic>> fetchOrderDetail(int id) async {
    return api.orderDetail(id: id);
  }

  Future<Map<String, dynamic>> fetchPrintDetail(int id) async {
    return api.printDetail(id: id);
  }

  Future<Map<String, dynamic>> softDeleteOrder(int id) async {
    return api.softDeleteOrder(id: id);
  }

  Future<Map<String, dynamic>> paymentOrder({
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? note,
    String? email,
    String? lastPaymentId,
    String? cashierProofImagePath,
  }) async {
    return api.paymentOrder(
      id: id,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      note: note,
      email: email,
      lastPaymentId: lastPaymentId,
      cashierProofImagePath: cashierProofImagePath,
    );
  }

  Future<Map<String, dynamic>> processOrder(int id) async {
    return api.processOrder(id: id);
  }

  Future<Map<String, dynamic>> cancelProcessOrder(int id) async {
    return api.cancelProcessOrder(id: id);
  }

  Future<Map<String, dynamic>> finishOrder(int id, {String? note}) async {
    return api.finishOrder(id: id, note: note);
  }
}