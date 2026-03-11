import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage_service.dart';
import '/core/services/push_notification_service.dart';
import 'auth_api.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import '/features/auth/data/models/user_model.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorageService storage;

  AuthRepository({required this.api, required this.storage});

  Future<LoginResponse> login(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    debugPrint('REPO LOGIN START');

    final resp = await api.login(
      LoginRequest(userName: username, password: password),
    );

    debugPrint('REPO LOGIN SUCCESS, SAVE TOKEN');
    await storage.saveToken(resp.token);

    debugPrint('SYNC FCM START');
    await PushNotificationService.instance.syncCurrentTokenToBackend();
    debugPrint('SYNC FCM DONE');

    return resp;
  }

  Future<void> logout() async {
    await storage.clearToken();
    // optional:
    // await api.logout();
  }

  Future<bool> hasToken() async {
    final t = await storage.getToken();
    return t != null && t.isNotEmpty;
  }

  Future<UserModel> me() async {
    return await api.me();
  }
}