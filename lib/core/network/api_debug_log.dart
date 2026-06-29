import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Structured HTTP + sync logging for cashier mobile debugging.
class ApiDebugLog {
  ApiDebugLog._();

  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: false,
      printEmojis: true,
    ),
  );

  static bool get enabled => kDebugMode;

  static void httpRequest({
    required String method,
    required String path,
    Map<String, dynamic>? headers,
    Object? body,
  }) {
    if (!enabled) return;
    _log.i(
      '➡️ HTTP $method $path\n'
      'headers: ${_redactHeaders(headers)}\n'
      'body: ${_truncate(body)}',
    );
  }

  static void httpResponse({
    required String method,
    required String path,
    required int? statusCode,
    Object? data,
  }) {
    if (!enabled) return;
    _log.i(
      '✅ HTTP $method $path → $statusCode\n'
      'data: ${_truncate(data)}',
    );
  }

  static void httpError({
    required String method,
    required String path,
    required int? statusCode,
    Object? data,
    Object? message,
  }) {
    if (!enabled) return;
    _log.e(
      '❌ HTTP $method $path → $statusCode\n'
      'message: $message\n'
      'data: ${_truncate(data)}',
    );
  }

  static void sync(String message, [Object? detail]) {
    if (!enabled) return;
    _log.i('🔄 SYNC $message${detail != null ? '\n$detail' : ''}');
  }

  static void syncError(String message, [Object? detail]) {
    if (!enabled) return;
    _log.e('❌ SYNC $message${detail != null ? '\n$detail' : ''}');
  }

  static String _truncate(Object? value, {int maxLen = 2000}) {
    if (value == null) return 'null';
    String text;
    try {
      text = value is String ? value : const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      text = value.toString();
    }
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}… [truncated ${text.length - maxLen} chars]';
  }

  static Map<String, dynamic>? _redactHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;
    final copy = Map<String, dynamic>.from(headers);
    for (final key in copy.keys.toList()) {
      final lower = key.toString().toLowerCase();
      if (lower == 'authorization') {
        final v = copy[key]?.toString() ?? '';
        copy[key] = v.length > 20 ? '${v.substring(0, 12)}…redacted' : '***';
      }
    }
    return copy;
  }
}
