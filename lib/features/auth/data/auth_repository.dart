import '../../../core/storage/secure_storage_service.dart';
import '/core/services/push_notification_service.dart';
import 'auth_api.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import '/features/auth/data/models/user_model.dart';
import 'models/me_response.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorageService storage;

  AuthRepository({required this.api, required this.storage});

  Future<LoginResponse> login(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    // debugPrint('REPO LOGIN START');

    final resp = await api.login(
      LoginRequest(userName: username, password: password),
    );

    // debugPrint('REPO LOGIN SUCCESS, SAVE TOKEN');
    await storage.saveToken(resp.token);

    // debugPrint('SYNC FCM START');
    await PushNotificationService.instance.syncCurrentTokenToBackend();
    // debugPrint('SYNC FCM DONE');

    return resp;
  }

  Future<void> logout() async {
    await storage.deleteToken();
    await storage.deleteCachedUser();
  }

  Future<bool> hasToken() async {
    final token = await storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveCachedUser(UserModel user) async {
    await storage.saveCachedUser(user);
  }

  Future<UserModel?> getCachedUser() async {
    return storage.getCachedUser();
  }

  Future<MeResponse> me() async {
    return await api.me();
  }
}