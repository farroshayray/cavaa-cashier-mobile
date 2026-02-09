import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';

class PurchaseApi {
  Future<Map<String, dynamic>> getProducts({required String token}) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/products');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Response JSON bukan object');
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

  Future<Map<String, dynamic>> checkout({
    required String token,
    required int orderTable,          // request->order_table
    required String orderName,        // request->order_name
    required String paymentMethod,    // "CASH" / "QRIS" (sesuai controller)
    required num totalAmount,         // request->total_amount
    required List<Map<String, dynamic>> items, // request->items
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/checkout');

    final payload = {
      'order_table': orderTable,
      'order_name': orderName,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'items': items,
    };

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    // backend kadang balikin HTML kalau redirect/error
    dynamic body;
    if (resp.body.isNotEmpty) {
      try {
        body = jsonDecode(resp.body);
      } catch (_) {
        body = resp.body; // simpan raw
      }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      // kalau sukses tapi body kosong / bukan object
      return {'success': true, 'raw': body};
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : (body is String && body.isNotEmpty)
            ? body
            : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }
}
