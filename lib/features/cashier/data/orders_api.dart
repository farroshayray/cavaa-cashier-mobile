import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';

class OrdersApi {
  Future<Map<String, dynamic>> getOrdersData({
    required String token,
    required String tab,
    String? q,
    String? payment,
    String? status,
    String? from,
    String? to,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/get-orders-data/$tab')
        .replace(queryParameters: {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (payment != null && payment.isNotEmpty) 'payment': payment,
      if (status != null && status.isNotEmpty) 'status': status,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    dynamic body;
    if (resp.body.isNotEmpty) {
      try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Response JSON bukan object');
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

  // ✅ NEW: order detail
  Future<Map<String, dynamic>> orderDetail({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/order-detail/$id');

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    dynamic body;
    if (resp.body.isNotEmpty) {
      try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Response JSON bukan object');
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

  Future<Map<String, dynamic>> softDeleteOrder({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/delete-order/$id');

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    dynamic body;
    if (resp.body.isNotEmpty) {
      try {
        body = jsonDecode(resp.body);
      } catch (_) {
        body = resp.body;
      }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      return {"message": "Order deleted"};
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

  Future<Map<String, dynamic>> paymentOrder({
    required String token,
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? note,
    String? email,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/payment-order/$id');

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'paid_amount': paidAmount,
        'change_amount': changeAmount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      }),
    );

    dynamic body;
    if (resp.body.isNotEmpty) {
      try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Response JSON bukan object');
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

}
