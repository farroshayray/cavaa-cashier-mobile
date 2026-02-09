import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _kToken = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _kToken, value: token);

  Future<String?> getToken() => _storage.read(key: _kToken);

  Future<void> clearToken() => _storage.delete(key: _kToken);
}
