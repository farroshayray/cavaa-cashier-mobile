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

  Future<Map<String, dynamic>> printDetail({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/print-detail/$id');

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
    String? lastPaymentId,
    String? cashierProofImagePath,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/payment-order/$id');

    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['paid_amount'] = paidAmount.toString()
      ..fields['change_amount'] = changeAmount.toString();

    if (note != null && note.trim().isNotEmpty) {
      req.fields['note'] = note.trim();
    }

    if (email != null && email.trim().isNotEmpty) {
      req.fields['email'] = email.trim();
    }

    // samakan nama field dengan web
    if (lastPaymentId != null && lastPaymentId.trim().isNotEmpty) {
      req.fields['last_payment_id'] = lastPaymentId.trim();
    }

    if (cashierProofImagePath != null && cashierProofImagePath.trim().isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath(
        'cashier_proof_image',
        cashierProofImagePath,
      ));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

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
      throw Exception('Response JSON bukan object');
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request gagal';
    throw Exception('HTTP ${resp.statusCode}: $msg');
  }

    Future<Map<String, dynamic>> processOrder({
      required String token,
      required int id,
    }) async {
      final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/process-order/$id');

      final resp = await http.post(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      dynamic body;
      if (resp.body.isNotEmpty) {
        try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (body is Map<String, dynamic>) return body;
        return {'status': 'ok'};
      }

      final msg = (body is Map && body['message'] != null) ? body['message'].toString() : 'Request gagal';
      throw Exception('HTTP ${resp.statusCode}: $msg');
    }

    Future<Map<String, dynamic>> cancelProcessOrder({
      required String token,
      required int id,
    }) async {
      final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/cancel-process-order/$id');

      final resp = await http.post(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      dynamic body;
      if (resp.body.isNotEmpty) {
        try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (body is Map<String, dynamic>) return body;
        return {'status': 'ok'};
      }

      final msg = (body is Map && body['message'] != null) ? body['message'].toString() : 'Request gagal';
      throw Exception('HTTP ${resp.statusCode}: $msg');
    }

    Future<Map<String, dynamic>> finishOrder({
      required String token,
      required int id,
      String? note,
    }) async {
      final uri = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/finish-order/$id');

      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );

      dynamic body;
      if (resp.body.isNotEmpty) {
        try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (body is Map<String, dynamic>) return body;
        return {'status': 'ok'};
      }

      final msg = (body is Map && body['message'] != null) ? body['message'].toString() : 'Request gagal';
      throw Exception('HTTP ${resp.statusCode}: $msg');
    }


}
