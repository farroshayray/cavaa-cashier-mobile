import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '/core/network/api_debug_log.dart';

class SyncApi {
  SyncApi(this.dio);

  final Dio dio;

  Future<Map<String, dynamic>> sync({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    ApiDebugLog.sync('POST /sync', 'idempotencyKey=$idempotencyKey');

    final resp = await dio.post(
      '/api/v1/mobile/cashier/sync',
      data: payload,
      options: Options(
        headers: {
          'X-Idempotency-Key': idempotencyKey,
        },
      ),
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Sync response bukan object');
  }

  static String buildIdempotencyKey({
    required String clientUuid,
    required String syncIntent,
    required String clientTimestamp,
  }) {
    final raw = '$clientUuid|${syncIntent.toUpperCase()}|$clientTimestamp';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static String buildBatchIdempotencyKey(List<String> parts) {
    if (parts.isEmpty) {
      return buildIdempotencyKey(
        clientUuid: 'batch',
        syncIntent: 'PULL',
        clientTimestamp: DateTime.now().toIso8601String(),
      );
    }
    final raw = parts.join('||');
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
