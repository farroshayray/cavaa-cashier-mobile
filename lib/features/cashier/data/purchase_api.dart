import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'models/checkout_exceptions.dart';

class PurchaseApi {
  final Dio dio;
  PurchaseApi(this.dio);

  Future<Map<String, dynamic>> getProducts() async {
    final resp = await dio.get('/api/v1/mobile/cashier/products');

    final data = resp.data;
    final list = (data['manualPaymentMethods'] as List? ?? []);
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

    print('payload checkout: $payload');

    late final Response resp;
    try {
      resp = await dio.post('/api/v1/mobile/cashier/checkout', data: payload);
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
    if (data is Map<String, dynamic>) {
      _ensureCheckoutSucceeded(data, paymentMethod: paymentMethod);
      return data;
    }

    throw Exception(
      'Response checkout tidak valid: ${data?.toString() ?? 'kosong'}',
    );
  }

  static void _ensureCheckoutSucceeded(
    Map<String, dynamic> data, {
    String? paymentMethod,
  }) {
    final success = data['success'];
    final status = data['status']?.toString().toLowerCase();
    final hasOrderId = _readPositiveInt(
          data['id'] ?? data['order_id'] ?? data['booking_order_id'],
        ) !=
        null ||
        (data['data'] is Map &&
            _readPositiveInt(
                  (data['data'] as Map)['id'] ??
                      (data['data'] as Map)['order_id'] ??
                      (data['data'] as Map)['booking_order_id'],
                ) !=
                null);

    if (success == false || status == 'error') {
      throw Exception(
        data['message']?.toString() ?? 'Checkout gagal tanpa pesan dari server',
      );
    }

    final redirect = data['redirect'];
    final isQrisCheckout = paymentMethod?.toUpperCase() == 'QRIS';
    if (!hasOrderId &&
        redirect is String &&
        redirect.trim().isNotEmpty &&
        isQrisCheckout) {
      return;
    }

    if (!hasOrderId &&
        redirect is String &&
        redirect.trim().isNotEmpty) {
      throw Exception(
        'Checkout memerlukan redirect QRIS. Sinkronkan ulang dengan metode pembayaran yang sama saat pembelian.',
      );
    }

    if (!hasOrderId) {
      throw Exception(
        data['message']?.toString() ??
            'Checkout tidak mengembalikan ID order dari server',
      );
    }
  }

  static int? _readPositiveInt(dynamic raw) {
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) return raw.toInt() > 0 ? raw.toInt() : null;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      return parsed != null && parsed > 0 ? parsed : null;
    }
    return null;
  }
}
