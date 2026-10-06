import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/features/auth/data/models/user_model.dart';
import '/features/auth/data/models/owner_model.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _ownerTokenKey = 'owner_token';
  static const _cashierTokenKey = 'cashier_token';
  static const _authRoleKey = 'auth_role';
  static const _viaOwnerKey = 'via_owner';
  static const _cachedUserKey = 'cached_user';
  static const _cachedOwnerKey = 'cached_owner';

  /// Active bearer token used by Dio (owner or cashier depending on role).
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveOwnerToken(String token) async {
    await _storage.write(key: _ownerTokenKey, value: token);
  }

  Future<String?> getOwnerToken() async {
    return _storage.read(key: _ownerTokenKey);
  }

  Future<void> deleteOwnerToken() async {
    await _storage.delete(key: _ownerTokenKey);
  }

  Future<void> saveCashierToken(String token) async {
    await _storage.write(key: _cashierTokenKey, value: token);
  }

  Future<String?> getCashierToken() async {
    return _storage.read(key: _cashierTokenKey);
  }

  Future<void> deleteCashierToken() async {
    await _storage.delete(key: _cashierTokenKey);
  }

  Future<void> saveAuthRole(String role) async {
    await _storage.write(key: _authRoleKey, value: role);
  }

  Future<String?> getAuthRole() async {
    return _storage.read(key: _authRoleKey);
  }

  Future<void> deleteAuthRole() async {
    await _storage.delete(key: _authRoleKey);
  }

  Future<void> saveViaOwner(bool value) async {
    await _storage.write(key: _viaOwnerKey, value: value ? '1' : '0');
  }

  Future<bool> getViaOwner() async {
    final raw = await _storage.read(key: _viaOwnerKey);
    return raw == '1' || raw == 'true';
  }

  Future<void> deleteViaOwner() async {
    await _storage.delete(key: _viaOwnerKey);
  }

  Future<void> saveCachedUser(UserModel user) async {
    await _storage.write(
      key: _cachedUserKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getCachedUser() async {
    final raw = await _storage.read(key: _cachedUserKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCachedUser() async {
    await _storage.delete(key: _cachedUserKey);
  }

  Future<void> saveCachedOwner(OwnerModel owner) async {
    await _storage.write(
      key: _cachedOwnerKey,
      value: jsonEncode(owner.toJson()),
    );
  }

  Future<OwnerModel?> getCachedOwner() async {
    final raw = await _storage.read(key: _cachedOwnerKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OwnerModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCachedOwner() async {
    await _storage.delete(key: _cachedOwnerKey);
  }

  Future<void> clearAllAuth() async {
    await deleteToken();
    await deleteOwnerToken();
    await deleteCashierToken();
    await deleteAuthRole();
    await deleteViaOwner();
    await deleteCachedUser();
    await deleteCachedOwner();
  }
}
