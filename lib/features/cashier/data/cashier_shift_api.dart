import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CashierShiftApi {
  CashierShiftApi(this.dio);

  final Dio dio;

  Future<Map<String, dynamic>?> current() async {
    final res = await dio.get('/api/v1/mobile/cashier/cashier-shifts/current');
    final data = res.data;
    if (data is Map && data['shift'] is Map) {
      return Map<String, dynamic>.from(data['shift'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>> open({
    required num openingCash,
    String? clientUuid,
  }) async {
    final res = await dio.post('/api/v1/mobile/cashier/cashier-shifts/open', data: {
      'opening_cash': openingCash,
      if (clientUuid != null) 'client_uuid': clientUuid,
    });
    return Map<String, dynamic>.from((res.data as Map)['shift'] as Map);
  }

  Future<Map<String, dynamic>> movement({
    required String direction,
    required num amount,
    String? note,
  }) async {
    final res = await dio.post(
      '/api/v1/mobile/cashier/cashier-shifts/movements',
      data: {
        'direction': direction,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return Map<String, dynamic>.from((res.data as Map)['shift'] as Map);
  }

  Future<Map<String, dynamic>> close({required num countedCash}) async {
    final res = await dio.post('/api/v1/mobile/cashier/cashier-shifts/close', data: {
      'counted_cash': countedCash,
    });
    return Map<String, dynamic>.from((res.data as Map)['shift'] as Map);
  }
}

class CashierShiftGate {
  static const _key = 'cashier_shift_book';
  static const _visibilityKey = 'cashier_shift_visibility_mode';
  static Map<String, dynamic>? shift;

  static bool get canTakePayment => shift?['status']?.toString() == 'open';

  static bool get isTransparent =>
      (shift?['visibility_mode']?.toString() ?? 'blind') == 'transparent';

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      shift = Map<String, dynamic>.from(decoded);
    }
  }

  static Future<String> cachedVisibilityMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_visibilityKey);
    return mode == 'transparent' ? 'transparent' : 'blind';
  }

  static Future<void> remember(Map<String, dynamic>? value) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? sanitized = value;
    if (sanitized != null) {
      final mode = sanitized['visibility_mode']?.toString() ?? 'blind';
      await prefs.setString(
        _visibilityKey,
        mode == 'transparent' ? 'transparent' : 'blind',
      );
      sanitized = Map<String, dynamic>.from(sanitized);
      if (mode != 'transparent') {
        final status = sanitized['status']?.toString();
        if (status != 'closed') {
          sanitized['cash_in'] = null;
          sanitized['cash_out'] = null;
          sanitized['cash_net'] = null;
          sanitized['expected_cash'] = null;
          sanitized['variance'] = null;
          sanitized.remove('ledger');
          sanitized.remove('order_cash');
          if (status != 'pending_approval') {
            sanitized['counted_cash'] = null;
          }
        }
      }
    }
    shift = sanitized;
    if (sanitized == null) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(sanitized));
  }

  static Future<Map<String, dynamic>> localOpen(num openingCash) async {
    final mode = await cachedVisibilityMode();
    return {
      'status': 'open',
      'opening_cash': openingCash,
      'client_uuid': const Uuid().v4(),
      'local_only': true,
      'visibility_mode': mode,
      'variance_tolerance': 0,
      'cash_in': mode == 'transparent' ? 0 : null,
      'cash_out': mode == 'transparent' ? 0 : null,
      'cash_net': mode == 'transparent' ? 0 : null,
      'non_cash_total': 0,
      'movements': <Map<String, dynamic>>[],
      if (mode == 'transparent') 'ledger': <Map<String, dynamic>>[],
    };
  }

  static String get blockedMessage {
    final status = shift?['status']?.toString();
    if (status == 'pending_approval') {
      return 'Buku kasir menunggu persetujuan. Pembayaran belum bisa diterima.';
    }
    if (status == 'recount') {
      return 'Hitung ulang uang di laci sebelum menerima pembayaran.';
    }
    if (status == 'counted_offline') {
      return 'Hitungan buku kasir belum terkirim. Pembayaran dikunci.';
    }
    return 'Buka buku kasir sebelum menerima pembayaran.';
  }
}
