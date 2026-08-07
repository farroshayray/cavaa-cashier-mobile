import '../../../core/storage/secure_storage_service.dart';
import '/core/services/push_notification_service.dart';
import 'auth_api.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import '/features/auth/data/models/user_model.dart';
import 'models/me_response.dart';
import 'models/owner_model.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStorageService storage;

  AuthRepository({required this.api, required this.storage});

  Future<LoginResponse> login(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    final resp = await api.login(
      LoginRequest(userName: username, password: password),
    );

    await storage.saveCashierToken(resp.token);
    await storage.saveToken(resp.token);
    await storage.saveAuthRole('cashier');
    await storage.saveViaOwner(false);
    await storage.deleteOwnerToken();
    await storage.deleteCachedOwner();

    await PushNotificationService.instance.syncCurrentTokenToBackend();

    return resp;
  }

  Future<OwnerModel> ownerLogin({
    required String email,
    required String password,
  }) async {
    final data = await api.ownerLogin(email: email, password: password);
    return _persistOwnerSession(data);
  }

  Future<OwnerModel> ownerGoogle({required String idToken}) async {
    final data = await api.ownerGoogle(idToken: idToken);
    return _persistOwnerSession(data);
  }

  Future<OwnerModel> ownerSetPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await api.ownerSetPassword(
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    final userMap = data['user'];
    if (userMap is! Map) {
      throw Exception('Invalid set-password response');
    }
    final owner = OwnerModel.fromJson(Map<String, dynamic>.from(userMap));
    await storage.saveCachedOwner(owner);
    return owner;
  }

  Future<OwnerModel> _persistOwnerSession(Map<String, dynamic> data) async {
    final token = data['token']?.toString() ?? '';
    final userMap = data['user'];
    if (token.isEmpty || userMap is! Map) {
      throw Exception('Invalid owner auth response');
    }

    final owner = OwnerModel.fromJson(Map<String, dynamic>.from(userMap));

    await storage.saveOwnerToken(token);
    await storage.saveToken(token);
    await storage.saveAuthRole('owner');
    await storage.saveViaOwner(false);
    await storage.deleteCashierToken();
    await storage.deleteCachedUser();
    await storage.saveCachedOwner(owner);

    return owner;
  }

  Future<LoginResponse> startOwnerCashierSession({int? storeId}) async {
    final ownerToken = await storage.getOwnerToken();
    if (ownerToken == null || ownerToken.isEmpty) {
      throw Exception('Owner session missing');
    }

    // Ensure Dio uses owner token for this call
    await storage.saveToken(ownerToken);
    await storage.saveAuthRole('owner');

    final data = await api.ownerCashierSession(storeId: storeId);
    final token = data['token']?.toString() ?? '';
    final userMap = data['user'];
    if (token.isEmpty || userMap is! Map) {
      throw Exception('Invalid cashier-session response');
    }

    final login = LoginResponse.fromJson({
      'token': token,
      'user': Map<String, dynamic>.from(userMap),
    });

    await storage.saveCashierToken(token);
    await storage.saveToken(token);
    await storage.saveAuthRole('cashier');
    await storage.saveViaOwner(true);
    await storage.saveCachedUser(login.user);

    try {
      await PushNotificationService.instance.syncCurrentTokenToBackend();
    } catch (_) {
      // FCM sync must never break cashier bootstrap.
    }

    // Ensure cashier token survives any interceptor side-effects during FCM sync.
    await storage.saveCashierToken(token);
    await storage.saveToken(token);
    await storage.saveAuthRole('cashier');
    await storage.saveViaOwner(true);

    return login;
  }

  Future<OwnerModel> returnToOwner() async {
    final ownerToken = await storage.getOwnerToken();
    if (ownerToken == null || ownerToken.isEmpty) {
      throw Exception('Owner session missing');
    }

    await storage.saveToken(ownerToken);
    await storage.saveAuthRole('owner');
    await storage.saveViaOwner(false);
    await storage.deleteCashierToken();
    await storage.deleteCachedUser();

    final owner = await api.ownerMe();
    await storage.saveCachedOwner(owner);
    return owner;
  }

  Future<void> logout() async {
    final role = await storage.getAuthRole();
    try {
      if (role == 'owner') {
        await api.ownerLogout();
      } else if (role == 'cashier') {
        await api.logout();
      }
    } catch (_) {
      // ignore network errors on logout
    }
    await storage.clearAllAuth();
  }

  Future<bool> hasToken() async {
    final token = await storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAuthRole() => storage.getAuthRole();

  Future<bool> getViaOwner() => storage.getViaOwner();

  Future<void> saveCachedUser(UserModel user) async {
    await storage.saveCachedUser(user);
  }

  Future<UserModel?> getCachedUser() async {
    return storage.getCachedUser();
  }

  Future<void> saveCachedOwner(OwnerModel owner) async {
    await storage.saveCachedOwner(owner);
  }

  Future<OwnerModel?> getCachedOwner() async {
    return storage.getCachedOwner();
  }

  Future<MeResponse> me() async {
    return await api.me();
  }

  Future<OwnerModel> ownerMe() async {
    final owner = await api.ownerMe();
    await storage.saveCachedOwner(owner);
    return owner;
  }

  Future<OwnerModel> selectStore(int storeId) async {
    final owner = await api.ownerSelectStore(storeId);
    await storage.saveCachedOwner(owner);
    return owner;
  }
}
