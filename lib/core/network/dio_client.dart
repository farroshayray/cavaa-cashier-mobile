import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/env.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../navigation/app_navigator.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService storage;

  bool _isHandlingUnauthorized = false;

  String? _platform;
  int? _versionCode;
  String? _versionName;
  bool _appInfoLoaded = false;

  DioClient(this.storage)
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              'Accept': 'application/json',
            },
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

          // debugPrint('➡️ [REQ] ${options.method} ${options.path}');
          // debugPrint('➡️ [REQ HEADERS] ${options.headers}');
          // debugPrint('➡️ [REQ DATA] ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // debugPrint('✅ [RES] ${response.requestOptions.path}');
          // debugPrint('✅ [RES DATA] ${response.data}');
          handler.next(response);
        },
        onError: (e, handler) async {
          final path = e.requestOptions.path;
          final isLogin = path.contains('/api/v1/mobile/cashier/login');
          final isVersionCheck =
              path.contains('/api/v1/mobile/cashier/version-check');
          final statusCode = e.response?.statusCode;

          debugPrint('❌ DIO ERROR path=$path status=$statusCode');

          if (isLogin || isVersionCheck) {
            return handler.next(e);
          }

          if (statusCode == 401 && !_isHandlingUnauthorized) {
            _isHandlingUnauthorized = true;

            try {
              debugPrint('🚨 401 detected -> force logout');

              await storage.deleteToken();
              await storage.deleteCachedUser();

              final nav = appNavigatorKey.currentState;

              if (nav != null) {
                Future.microtask(() {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
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
}