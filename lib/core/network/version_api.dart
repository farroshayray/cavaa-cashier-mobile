import 'package:dio/dio.dart';
import 'dio_client.dart';

class VersionApi {
  final DioClient client;

  VersionApi(this.client);

  Future<Map<String, dynamic>> checkVersion({
    required String platform,
    required int versionCode,
    String? versionName,
  }) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/cashier/version-check',
      data: {
        'platform': platform,
        'version_code': versionCode,
        'version_name': versionName,
      },
    );

    return res.data['data'];
  }
}