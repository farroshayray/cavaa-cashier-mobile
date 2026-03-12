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
          // debugPrint('❌ [ERR] ${e.requestOptions.path}');
          // debugPrint('❌ [ERR STATUS] ${e.response?.statusCode}');
          // debugPrint('❌ [ERR DATA] ${e.response?.data}');

          final path = e.requestOptions.path;
          final isLogin = path.contains('/api/v1/mobile/cashier/login');

          // penting: login jangan di-refresh / retry
          if (isLogin) {
            return handler.next(e);
          }

          // kalau ada logic refresh token, letakkan di sini hanya untuk endpoint selain login
          handler.next(e);
        },
      ),
    );
  }
}
