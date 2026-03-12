import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../data/models/login_response.dart';
import '../data/models/user_model.dart';
import 'package:dio/dio.dart';

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

      await repo.login(username, password, rememberMe: rememberMe);

      // Ambil user lengkap dari endpoint /me
      final u = await repo.me();
      user = u;
      isLoggedIn = true;

      return true;
    } on DioException catch (e) {
      debugPrint('LOGIN DIO ERROR: $e');
      debugPrint('LOGIN DIO RESPONSE: ${e.response?.data}');

      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else {
        errorMessage = 'Login gagal';
      }
      return false;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      errorMessage = 'Login gagal';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMe() async {
    try {
      final u = await repo.me();
      user = u;
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('fetchMe error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await repo.logout();
    user = null;
    isLoggedIn = false;
    notifyListeners();
  }
}
