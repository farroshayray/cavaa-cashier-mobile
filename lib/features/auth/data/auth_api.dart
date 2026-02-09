import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';

class AuthApi {
  final DioClient client;

  AuthApi(this.client);

  Future<LoginResponse> login(LoginRequest req) async {
    // Sesuaikan endpoint
    final Response res = await client.dio.post('/api/v1/mobile/cashier/login', data: req.toJson());

    // Sesuaikan struktur response (misal: { data: {...} } )
    final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;

    return LoginResponse.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logout() async {
    await client.dio.post('/api/v1/mobile/cashier/logout');
  }
}
