import '../../../core/storage/secure_storage_service.dart';
import 'auth_api.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorageService storage;

  AuthRepository({required this.api, required this.storage});

  Future<LoginResponse> login(String username, String password, {required bool rememberMe}) async {
    final resp = await api.login(LoginRequest(userName: username, password: password));

    if (rememberMe) {
      await storage.saveToken(resp.token);
    } else {
      await storage.clearToken(); // pastikan tidak ada token lama
    }

    return resp;
}

  Future<void> logout() async {
    await storage.clearToken();
    // optional: panggil api.logout() kalau backend butuh
    // await api.logout();
  }

  Future<bool> hasToken() async {
    final t = await storage.getToken();
    return t != null && t.isNotEmpty;
  }
}
