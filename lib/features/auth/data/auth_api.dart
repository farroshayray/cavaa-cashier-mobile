import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import '/features/auth/data/models/user_model.dart';

class AuthApi {
  final DioClient client;

  AuthApi(this.client);

  Future<UserModel> me() async {
    final Response res =
        await client.dio.get('/api/v1/mobile/cashier/me');

    // print('ME RAW RESPONSE: ${res.data}');

    final data = res.data;
    final userJson =
        (data is Map<String, dynamic>) ? data['user'] : null;

    if (userJson is! Map) {
      throw Exception('Invalid /me response: missing user');
    }

    // print('ME USER JSON: $userJson');

    return UserModel.fromJson(
      Map<String, dynamic>.from(userJson),
    );
  }


  Future<LoginResponse> login(LoginRequest req) async {
    try {
      // debugPrint('LOGIN REQUEST START');
      // debugPrint('LOGIN REQUEST BODY: ${req.toJson()}');

      final Response res = await client.dio.post(
        '/api/v1/mobile/cashier/login',
        data: req.toJson(),
      );

      // debugPrint('LOGIN RESPONSE STATUS: ${res.statusCode}');
      // debugPrint('LOGIN RESPONSE DATA: ${res.data}');

      final data = (res.data is Map && res.data['data'] != null)
          ? res.data['data']
          : res.data;

      return LoginResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      debugPrint('LOGIN API DIO ERROR: $e');
      debugPrint('LOGIN API DIO STATUS: ${e.response?.statusCode}');
      debugPrint('LOGIN API DIO DATA: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('LOGIN API ERROR: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await client.dio.post('/api/v1/mobile/cashier/logout');
  }
}
