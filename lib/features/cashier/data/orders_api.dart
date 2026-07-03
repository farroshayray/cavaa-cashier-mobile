import 'package:dio/dio.dart';

import '/core/config/app_config.dart';
import 'models/checkout_exceptions.dart';

class OrdersApi {
  final Dio dio;
  OrdersApi(this.dio);

  Future<Map<String, dynamic>> getOrdersData({
    required String tab,
    String? q,
    String? payment,
    String? status,
    String? from,
    String? to,
  }) async {
    final resp = await dio.get(
      '/api/v1/mobile/cashier/get-orders-data/$tab',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (payment != null && payment.isNotEmpty) 'payment': payment,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> orderDetail({required int id}) async {
    final resp = await dio.get('/api/v1/mobile/cashier/order-detail/$id');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> printDetail({required int id}) async {
    final resp = await dio.get(
      '/api/v1/mobile/cashier/print-detail/$id',
      options: Options(receiveTimeout: AppConfig.printDetailTimeout),
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> softDeleteOrder({required int id}) async {
    final resp = await dio.post('/api/v1/mobile/cashier/delete-order/$id');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {"message": "Order deleted"};
  }

  Future<Map<String, dynamic>> updateOrder({
    required int id,
    int? orderTable,
    String? orderName,
    required List<Map<String, dynamic>> items,
    bool preserveOrderStatus = false,
  }) async {
    final payload = <String, dynamic>{
      'items': items,
      if (orderTable != null) 'order_table': orderTable,
      if (orderName != null && orderName.trim().isNotEmpty)
        'order_name': orderName.trim(),
      if (preserveOrderStatus) ...{
        'menu_only_update': true,
        'preserve_order_status': true,
      },
    };

    late final Response resp;
    try {
      resp = await dio.post(
        '/api/v1/mobile/cashier/update-order/$id',
        data: payload,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['code'] == 'STOCK_INSUFFICIENT') {
          throw StockInsufficientException.fromResponse(map);
        }
      }
      rethrow;
    }

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> paymentOrder({
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? paymentMethod,
    String? note,
    String? email,
    String? lastPaymentId,
    String? cashierProofImagePath,
  }) async {
    final formData = FormData.fromMap({
      'paid_amount': paidAmount.toString(),
      'change_amount': changeAmount.toString(),
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty)
        'payment_method': paymentMethod.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (lastPaymentId != null && lastPaymentId.trim().isNotEmpty)
        'last_payment_id': lastPaymentId.trim(),
      if (cashierProofImagePath != null &&
          cashierProofImagePath.trim().isNotEmpty)
        'cashier_proof_image': await MultipartFile.fromFile(
          cashierProofImagePath,
        ),
    });

    final resp = await dio.post(
      '/api/v1/mobile/cashier/payment-order/$id',
      data: formData,
      options: Options(
        sendTimeout: AppConfig.paymentMultipartTimeout,
        receiveTimeout: AppConfig.paymentMultipartTimeout,
      ),
    );

    print('response payment-order: $resp');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> processOrder({
    required int id,
    bool sendToKitchenWaiting = false,
  }) async {
    final resp = await dio.post(
      '/api/v1/mobile/cashier/process-order/$id',
      data: {if (sendToKitchenWaiting) 'send_to_kitchen_waiting': true},
    );
    print('response process-order: $resp');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'status': 'ok'};
  }

  Future<Map<String, dynamic>> serveOrderItems({
    required int id,
    required List<int> detailIds,
  }) async {
    final resp = await dio.post(
      '/api/v1/mobile/cashier/process-order/$id',
      data: {'detail_ids': detailIds},
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'status': 'ok'};
  }

  Future<Map<String, dynamic>> markServedByKitchen({
    required int id,
    required List<int> detailIds,
  }) async {
    final resp = await dio.post(
      '/api/v1/mobile/cashier/mark-served-by-kitchen/$id',
      data: {'detail_ids': detailIds},
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Map<String, dynamic>> cancelProcessOrder({required int id}) async {
    final resp = await dio.post(
      '/api/v1/mobile/cashier/cancel-process-order/$id',
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'status': 'ok'};
  }

  Future<Map<String, dynamic>> finishOrder({
    required int id,
    String? note,
  }) async {
    final resp = await dio.post(
      '/api/v1/mobile/cashier/finish-order/$id',
      data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );

    print('response finish-order: $resp');

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'status': 'ok'};
  }
}
