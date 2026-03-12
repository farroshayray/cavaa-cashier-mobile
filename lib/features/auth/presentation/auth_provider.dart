import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
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

    if (!hasToken) {
      isLoggedIn = false;
      user = null;
      notifyListeners();
      return;
    }

    // token ada -> anggap sementara login
    isLoggedIn = true;

    // coba isi user dari cache dulu supaya langsung ada saat offline
    final cachedUser = await repo.getCachedUser();
    if (cachedUser != null) {
      user = cachedUser;
    }

    notifyListeners();

    try {
      await fetchMe();
    } catch (e) {
      debugPrint('bootstrap fetchMe failed, keep logged in with cached token: $e');

      // kalau fetchMe gagal, tetap gunakan cached user bila ada
      if (cachedUser != null) {
        user = cachedUser;
        isLoggedIn = true;
      } else {
        // token ada tapi cached user tidak ada
        isLoggedIn = true;
      }

      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, {required bool rememberMe}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await repo.login(username, password, rememberMe: rememberMe);

      final u = await repo.me();
      user = u;
      isLoggedIn = true;
      await repo.saveCachedUser(u);

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
      await repo.saveCachedUser(u);
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