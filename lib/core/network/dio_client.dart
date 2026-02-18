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
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        // =====================
        // HANDLE 401
        // =====================
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await storage.clearToken();

            final nav = appNavigatorKey.currentState;
            if (nav != null) {
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            }

            return; 
          }
          return handler.next(e);
        },
      ),
    );
  }
}
