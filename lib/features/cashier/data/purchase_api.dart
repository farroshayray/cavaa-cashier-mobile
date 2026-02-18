import 'package:dio/dio.dart';

class PurchaseApi {
  final Dio dio;
  PurchaseApi(this.dio);

  Future<Map<String, dynamic>> getProducts() async {
    final resp = await dio.get('/api/v1/mobile/cashier/products');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;

    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> checkout({
    required int orderTable,
    required String orderName,
    required String paymentMethod,
    required num totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'order_table': orderTable,
      'order_name': orderName,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'items': items,
    };

    final resp = await dio.post('/api/v1/mobile/cashier/checkout', data: payload);

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;

    return {'success': true, 'raw': data};
  }
}
