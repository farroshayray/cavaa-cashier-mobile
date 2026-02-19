import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../data/models/login_response.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repo;

  AuthProvider(this.repo);

  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;

   UserModel? user;

  Future<void> bootstrap() async {
    final hasToken = await repo.hasToken();

    if (hasToken) {
      try {
        await fetchMe(); // 🔥 WAJIB
        isLoggedIn = true;
      } catch (e) {
        isLoggedIn = false;
      }
    } else {
      isLoggedIn = false;
    }

    notifyListeners();
  }

  Future<bool> login(String username, String password, {required bool rememberMe}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final resp = await repo.login(username, password, rememberMe: rememberMe);
      user = resp.user;

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Login gagal';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMe() async {
    try {
      final u = await repo.me(); // kamu harus punya endpoint /me
      user = u;
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('fetchMe error: $e');
    }
  }

  Future<void> logout() async {
    await repo.logout();
    user = null;
    isLoggedIn = false;
    notifyListeners();
  }
}
