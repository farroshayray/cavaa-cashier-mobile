import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/owner_model.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repo;

  AuthProvider(this.repo);

  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;
  UserModel? user;
  OwnerModel? owner;
  String? authRole; // owner | cashier
  bool viaOwner = false;
  Map<String, dynamic>? appUpdate;
  Map<String, List<WorkScheduleRange>>? blockedWorkSchedule;
  String? blockedWorkScheduleSummary;

  bool get isOwner => authRole == 'owner';
  bool get isCashier => authRole == 'cashier';

  Future<void> bootstrap() async {
    final hasToken = await repo.hasToken();
    authRole = await repo.getAuthRole();
    viaOwner = await repo.getViaOwner();

    if (!hasToken) {
      isLoggedIn = false;
      user = null;
      owner = null;
      appUpdate = null;
      notifyListeners();
      return;
    }

    isLoggedIn = true;

    if (authRole == 'owner') {
      final cachedOwner = await repo.getCachedOwner();
      if (cachedOwner != null) {
        owner = cachedOwner;
      }
      notifyListeners();

      try {
        await fetchOwnerMe();
      } on DioException catch (e) {
        await _handleBootstrapAuthError(e, isOwnerFlow: true);
      } catch (e) {
        debugPrint('bootstrap owner fetchMe failed: $e');
        notifyListeners();
      }
      return;
    }

    final cachedUser = await repo.getCachedUser();
    if (cachedUser != null) {
      user = cachedUser;
    }

    notifyListeners();

    try {
      await fetchMe();
    } on DioException catch (e) {
      await _handleBootstrapAuthError(e, isOwnerFlow: false);
    } catch (e) {
      debugPrint(
        'bootstrap fetchMe failed, keep logged in with cached token: $e',
      );
      notifyListeners();
    }
  }

  Future<void> _handleBootstrapAuthError(
    DioException e, {
    required bool isOwnerFlow,
  }) async {
    debugPrint('bootstrap fetchMe dio failed: $e');

    final data = e.response?.data;
    final shouldLogoutWithMessage =
        e.response?.statusCode == 403 &&
        data is Map &&
        data['message'] != null;

    if (e.response?.statusCode == 401 || shouldLogoutWithMessage) {
      errorMessage = shouldLogoutWithMessage
          ? _messageFromErrorData(data)
          : null;
      await repo.logout();
      isLoggedIn = false;
      user = null;
      owner = null;
      authRole = null;
      viaOwner = false;
      appUpdate = null;
      notifyListeners();
      return;
    }

    if (isOwnerFlow) {
      owner ??= await repo.getCachedOwner();
    } else {
      user ??= await repo.getCachedUser();
    }
    isLoggedIn = true;
    notifyListeners();
  }

  Future<bool> login(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      blockedWorkSchedule = null;
      blockedWorkScheduleSummary = null;
      notifyListeners();

      await repo.login(username, password, rememberMe: rememberMe);

      final me = await repo.me();
      user = me.user;
      owner = null;
      appUpdate = me.appUpdate;
      authRole = 'cashier';
      viaOwner = false;
      isLoggedIn = true;

      await repo.saveCachedUser(me.user);

      return true;
    } on DioException catch (e) {
      debugPrint('LOGIN DIO ERROR: $e');
      debugPrint('LOGIN DIO RESPONSE: ${e.response?.data}');

      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        errorMessage = _messageFromErrorData(data);
        if (data['code']?.toString() == 'outside_work_schedule') {
          blockedWorkSchedule = UserModel.parseWorkSchedule(
            data['work_schedule'],
          );
          blockedWorkScheduleSummary = data['work_schedule_summary']
              ?.toString()
              .trim();
        }
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

  Future<bool> ownerLogin(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      owner = await repo.ownerLogin(email: email, password: password);
      user = null;
      authRole = 'owner';
      viaOwner = false;
      isLoggedIn = true;
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = data is Map && data['message'] != null
          ? _messageFromErrorData(data)
          : 'Login owner gagal';
      return false;
    } catch (e) {
      errorMessage = 'Login owner gagal';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> ownerGoogle(String idToken) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      owner = await repo.ownerGoogle(idToken: idToken);
      user = null;
      authRole = 'owner';
      viaOwner = false;
      isLoggedIn = true;
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = data is Map && data['message'] != null
          ? _messageFromErrorData(data)
          : 'Daftar/login Google gagal';
      return false;
    } catch (e) {
      errorMessage = 'Daftar/login Google gagal';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setOwnerPassword(String password, String confirmation) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      owner = await repo.ownerSetPassword(
        password: password,
        passwordConfirmation: confirmation,
      );
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        errorMessage = _messageFromErrorData(data);
      } else if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        errorMessage = errors.values
            .expand((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .join('\n');
      } else {
        errorMessage = 'Gagal menyimpan password';
      }
      return false;
    } catch (e) {
      errorMessage = 'Gagal menyimpan password';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enterCashierAsOwner({int? storeId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final login = await repo.startOwnerCashierSession(storeId: storeId);
      user = login.user;
      authRole = 'cashier';
      viaOwner = true;
      isLoggedIn = true;
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = data is Map && data['message'] != null
          ? _messageFromErrorData(data)
          : 'Gagal masuk mode kasir';
      return false;
    } catch (e) {
      errorMessage = 'Gagal masuk mode kasir';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> returnToOwner() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      owner = await repo.returnToOwner();
      user = null;
      authRole = 'owner';
      viaOwner = false;
      isLoggedIn = true;
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = data is Map && data['message'] != null
          ? _messageFromErrorData(data)
          : 'Gagal kembali ke menu owner';
      return false;
    } catch (e) {
      errorMessage = 'Gagal kembali ke menu owner';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMe() async {
    try {
      final me = await repo.me();
      user = me.user;
      appUpdate = me.appUpdate;
      isLoggedIn = true;

      await repo.saveCachedUser(me.user);
      notifyListeners();
    } catch (e) {
      debugPrint('fetchMe error: $e');
      rethrow;
    }
  }

  Future<void> fetchOwnerMe() async {
    try {
      owner = await repo.ownerMe();
      isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('fetchOwnerMe error: $e');
      rethrow;
    }
  }

  Future<void> refreshOwner() async {
    await fetchOwnerMe();
  }

  Future<bool> selectStore(int storeId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      owner = await repo.selectStore(storeId);
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage = data is Map && data['message'] != null
          ? _messageFromErrorData(data)
          : 'Gagal memilih toko';
      return false;
    } catch (e) {
      errorMessage = 'Gagal memilih toko';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repo.logout();
    user = null;
    owner = null;
    appUpdate = null;
    authRole = null;
    viaOwner = false;
    isLoggedIn = false;
    notifyListeners();
  }

  String _messageFromErrorData(Map<dynamic, dynamic> data) {
    final message = data['message']?.toString() ?? 'Login gagal';
    final reason = data['deactivation_reason']?.toString().trim();

    return reason != null && reason.isNotEmpty
        ? '$message\nAlasan: $reason'
        : message;
  }
}
