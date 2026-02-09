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
    isLoggedIn = await repo.hasToken();
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


  Future<void> logout() async {
    await repo.logout();
    user = null;
    isLoggedIn = false;
    notifyListeners();
  }
}
