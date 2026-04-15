import 'package:shared_preferences/shared_preferences.dart';

class RememberedLoginStorage {
  static const _keyRememberMe = 'remember_me';
  static const _keyUsername = 'remembered_username';
  static const _keyPassword = 'remembered_password';

  Future<void> save({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe) {
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyPassword, password);
    } else {
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword);
    }
  }

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberMe = prefs.getBool(_keyRememberMe) ?? true;
    final username = prefs.getString(_keyUsername) ?? '';
    final password = prefs.getString(_keyPassword) ?? '';

    return {
      'rememberMe': rememberMe,
      'username': username,
      'password': password,
    };
  }

  Future<void> clearRememberedCredentialOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyRememberMe, false);
  }
}