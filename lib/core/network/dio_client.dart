import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../navigation/app_navigator.dart';
import '../services/app_update_provider.dart';
import '../services/connectivity_status_provider.dart';
import 'api_debug_log.dart';
import '../../features/auth/presentation/pages/login_page.dart';

const _forcedLogoutMessageKey = 'forced_logout_message';

class DioClient {
  final Dio dio;
  final SecureStorageService storage;
  final AppUpdateProvider? appUpdateProvider;
  final ConnectivityStatusProvider? connectivity;

  bool _isHandlingUnauthorized = false;

  String? _platform;
  int? _versionCode;
  String? _versionName;
  bool _appInfoLoaded = false;

  DioClient(
    this.storage, {
    this.appUpdateProvider,
    this.connectivity,
  })
    : dio = Dio(
        BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            await ensureAppInfoLoaded();

            if (_platform != null) {
              options.headers['X-Platform'] = _platform;
            }
            if (_versionCode != null) {
              options.headers['X-App-Version-Code'] = _versionCode;
            }
            if (_versionName != null && _versionName!.isNotEmpty) {
              options.headers['X-App-Version-Name'] = _versionName;
            }
          } catch (e) {
            debugPrint('Failed to attach app version headers: $e');
          }

          final token = await storage.getToken();
          final isLogin = options.path.contains('/api/v1/mobile/cashier/login');

          if (!isLogin && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          ApiDebugLog.httpRequest(
            method: options.method,
            path: options.uri.toString(),
            headers: Map<String, dynamic>.from(options.headers),
            body: options.data,
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          if ((response.statusCode ?? 0) < 500) {
            connectivity?.markServerReachable();
          }

          _captureAppUpdate(response);
          ApiDebugLog.httpResponse(
            method: response.requestOptions.method,
            path: response.requestOptions.uri.toString(),
            statusCode: response.statusCode,
            data: response.data,
          );
          handler.next(response);
        },
        onError: (e, handler) async {
          final path = e.requestOptions.path;
          final isLogin = path.contains('/api/v1/mobile/cashier/login');
          final isVersionCheck = path.contains(
            '/api/v1/mobile/cashier/version-check',
          );
          final statusCode = e.response?.statusCode;

          ApiDebugLog.httpError(
            method: e.requestOptions.method,
            path: e.requestOptions.uri.toString(),
            statusCode: statusCode,
            data: e.response?.data,
            message: e.message,
          );

          debugPrint('❌ DIO ERROR path=$path status=$statusCode');

          if (_isServerDownError(e)) {
            connectivity?.markServerDown(
              reason: 'path=$path status=$statusCode type=${e.type.name}',
            );
          }

          if (isLogin || isVersionCheck) {
            return handler.next(e);
          }

          final data = e.response?.data;
          final isInactiveAccount =
              statusCode == 403 &&
              data is Map &&
              data['code']?.toString() == 'account_inactive';
          final forcedLogoutMessage = data is Map
              ? _buildForcedLogoutMessage(data)
              : null;
          final shouldShowForcedLogoutMessage =
              isInactiveAccount ||
              (statusCode == 403 &&
                  forcedLogoutMessage != null &&
                  forcedLogoutMessage.isNotEmpty);

          if ((statusCode == 401 || shouldShowForcedLogoutMessage) &&
              !_isHandlingUnauthorized) {
            _isHandlingUnauthorized = true;

            try {
              debugPrint('🚨 401 detected -> force logout');

              if (shouldShowForcedLogoutMessage &&
                  forcedLogoutMessage != null) {
                await _saveForcedLogoutMessage(forcedLogoutMessage);
              }

              await storage.deleteToken();
              await storage.deleteCachedUser();

              final nav = appNavigatorKey.currentState;

              if (nav != null) {
                Future.microtask(() {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoginPage(
                        initialErrorMessage: shouldShowForcedLogoutMessage
                            ? forcedLogoutMessage
                            : null,
                      ),
                    ),
                    (_) => false,
                  );
                });
              } else {
                debugPrint('⚠️ Navigator not ready');
              }
            } catch (err, st) {
              debugPrint('❌ 401 handler failed: $err');
              debugPrint('$st');
            } finally {
              _isHandlingUnauthorized = false;
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  Future<void> ensureAppInfoLoaded() async {
    if (_appInfoLoaded) return;

    final info = await PackageInfo.fromPlatform();
    _platform = Platform.isAndroid ? 'android' : 'ios';
    _versionCode = int.tryParse(info.buildNumber) ?? 1;
    _versionName = info.version;
    _appInfoLoaded = true;

    debugPrint(
      'App info loaded: platform=$_platform, versionCode=$_versionCode, versionName=$_versionName',
    );
  }

  void setAppInfo({
    required String platform,
    required int versionCode,
    required String versionName,
  }) {
    _platform = platform;
    _versionCode = versionCode;
    _versionName = versionName;
    _appInfoLoaded = true;

    debugPrint(
      'App info set manually: platform=$_platform, versionCode=$_versionCode, versionName=$_versionName',
    );
  }

  String? get platform => _platform;
  int? get versionCode => _versionCode;
  String? get versionName => _versionName;

  bool _isServerDownError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504) {
      return true;
    }

    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.unknown;
  }

  void _captureAppUpdate(Response response) {
    final provider = appUpdateProvider;
    if (provider == null) return;

    final headerValue = response.headers.value('x-app-update');
    if (headerValue == null || headerValue.trim().isEmpty) return;

    try {
      final decoded = utf8.decode(base64Decode(headerValue.trim()));
      final data = jsonDecode(decoded);
      if (data is Map) {
        provider.setUpdate(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('Failed to parse X-App-Update header: $e');
    }
  }

  String? _buildForcedLogoutMessage(Map<dynamic, dynamic> data) {
    final message = data['message']?.toString().trim();
    final reason = data['deactivation_reason']?.toString().trim();

    final parts = <String>[
      if (message != null && message.isNotEmpty) message,
      if (reason != null && reason.isNotEmpty) 'Alasan: $reason',
    ];

    if (parts.isEmpty) return null;

    return parts.join('\n');
  }

  Future<void> _saveForcedLogoutMessage(String message) async {
    if (message.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forcedLogoutMessageKey, message);
  }
}
