import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import 'models/me_response.dart';
import 'models/owner_model.dart';

class AuthApi {
  final DioClient client;

  AuthApi(this.client);

  Future<MeResponse> me() async {
    final Response res = await client.dio.get('/api/v1/mobile/cashier/me');

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid /me response');
    }

    return MeResponse.fromJson(data);
  }

  Future<LoginResponse> login(LoginRequest req) async {
    try {
      final Response res = await client.dio.post(
        '/api/v1/mobile/cashier/login',
        data: req.toJson(),
      );

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

  Future<Map<String, dynamic>> ownerLogin({
    required String email,
    required String password,
  }) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/auth/login',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> ownerGoogle({required String idToken}) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/auth/google',
      data: {'id_token': idToken},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> ownerSetPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/auth/set-password',
      data: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<OwnerModel> ownerMe() async {
    final Response res = await client.dio.get('/api/v1/mobile/owner/me');
    final data = res.data;
    if (data is! Map || data['user'] is! Map) {
      throw Exception('Invalid owner /me response');
    }
    return OwnerModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<OwnerModel> ownerSelectStore(int storeId) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/stores/select',
      data: {'store_id': storeId},
    );
    final data = res.data;
    if (data is! Map || data['user'] is! Map) {
      throw Exception('Invalid select store response');
    }
    return OwnerModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<void> ownerLogout() async {
    await client.dio.post('/api/v1/mobile/owner/logout');
  }

  Future<Map<String, dynamic>> ownerCashierSession({int? storeId}) async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/cashier-session',
      data: {if (storeId != null) 'store_id': storeId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<OwnerModel> ownerReturnSession() async {
    final Response res = await client.dio.post(
      '/api/v1/mobile/owner/return-session',
    );
    final data = res.data;
    if (data is! Map || data['user'] is! Map) {
      throw Exception('Invalid return-session response');
    }
    return OwnerModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }
}
