import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/env.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../navigation/app_navigator.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService storage;

  bool _isHandlingUnauthorized = false;

  DioClient(this.storage)
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
          final token = await storage.getToken();

          final isLogin = options.path.contains('/api/v1/mobile/cashier/login');

          if (!isLogin && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // debugPrint('➡️ [REQ] ${options.method} ${options.path}');
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
          final statusCode = e.response?.statusCode;

          debugPrint('❌ DIO ERROR path=$path status=$statusCode');

          // skip kalau endpoint login
          if (isLogin) {
            return handler.next(e);
          }

          // handle 401 global
          if (statusCode == 401 && !_isHandlingUnauthorized) {
            _isHandlingUnauthorized = true;

            try {
              debugPrint('🚨 401 detected -> force logout');

              // 1. clear session
              await storage.deleteToken();
              await storage.deleteCachedUser();

              // 2. redirect ke login (AMAN)
              final nav = appNavigatorKey.currentState;

              if (nav != null) {
                // penting: delay ke next frame biar tidak bentrok lifecycle
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
}
