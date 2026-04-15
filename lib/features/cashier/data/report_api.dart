import 'dart:typed_data';

import 'package:dio/dio.dart';

class ReportApi {
  final Dio dio;
  ReportApi(this.dio);

  Future<Map<String, dynamic>> getSummary({
    required String from,
    required String to,
    required String cashierScope,
  }) async {
    final resp = await dio.get(
      '/api/v1/mobile/cashier/reports/summary',
      queryParameters: {
        'from': from,
        'to': to,
        'cashier_scope': cashierScope,
      },
    );

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Response JSON bukan object');
  }

  Future<Uint8List> exportSummary({
    required String from,
    required String to,
    required String cashierScope,
  }) async {
    final resp = await dio.get(
      '/api/v1/mobile/cashier/reports/export',
      queryParameters: {
        'from': from,
        'to': to,
        'cashier_scope': cashierScope,
      },
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    final data = resp.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw Exception('Response export bukan bytes');
  }
}
