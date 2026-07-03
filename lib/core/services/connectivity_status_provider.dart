import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '/core/config/env.dart';

class ConnectivityStatusProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final Dio _healthDio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
      headers: {'Accept': 'application/json'},
    ),
  );

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _serverRetryTimer;

  bool _hasNetwork = true;
  bool _isServerReachable = false;
  bool _isOnline = false;
  bool _isChecking = true;
  Future<bool>? _serverCheckInFlight;

  bool get hasNetwork => _hasNetwork;
  bool get isServerReachable => _isServerReachable;
  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  Future<void> init() async {
    try {
      _isChecking = true;
      notifyListeners();

      final result = await _connectivity.checkConnectivity();
      await _updateFromResults(result);

      _sub = _connectivity.onConnectivityChanged.listen((results) {
        unawaited(_updateFromResults(results));
      });
    } catch (e) {
      debugPrint('Connectivity init error: $e');
      _setStatus(
        hasNetwork: true,
        isServerReachable: true,
        isChecking: false,
      );
    }
  }

  Future<bool> checkServerReachability() {
    if (!_hasNetwork) {
      _setStatus(
        hasNetwork: false,
        isServerReachable: false,
        isChecking: false,
      );
      return Future.value(false);
    }

    final existing = _serverCheckInFlight;
    if (existing != null) return existing;

    final check = _probeServer().whenComplete(() {
      _serverCheckInFlight = null;
    });
    _serverCheckInFlight = check;
    return check;
  }

  void markServerDown({String? reason}) {
    if (!_hasNetwork || !_isServerReachable) return;

    debugPrint(
      'Server marked unreachable${reason == null ? '' : ': $reason'}',
    );
    _setStatus(
      hasNetwork: _hasNetwork,
      isServerReachable: false,
      isChecking: false,
    );
  }

  void markServerReachable() {
    if (!_hasNetwork || _isServerReachable) return;

    _setStatus(
      hasNetwork: _hasNetwork,
      isServerReachable: true,
      isChecking: false,
    );
  }

  Future<bool> _probeServer() async {
    try {
      final response = await _healthDio.get('/up');
      final statusCode = response.statusCode ?? 0;
      final reachable = statusCode >= 200 && statusCode < 500;
      _setStatus(
        hasNetwork: true,
        isServerReachable: reachable,
        isChecking: false,
      );
      return reachable;
    } catch (e) {
      debugPrint('Server health check failed: $e');
      _setStatus(
        hasNetwork: true,
        isServerReachable: false,
        isChecking: false,
      );
      return false;
    }
  }

  Future<void> Function()? onBackOnline;
  Future<void> Function()? onInitialOnline;
  bool _initialOnlineHandled = false;

  Future<void> _updateFromResults(List<ConnectivityResult> results) async {
    final hasConnectionType = results.any((r) => r != ConnectivityResult.none);

    if (!hasConnectionType) {
      _setStatus(
        hasNetwork: false,
        isServerReachable: false,
        isChecking: false,
      );
      return;
    }

    _setStatus(
      hasNetwork: true,
      isServerReachable: _isServerReachable,
      isChecking: true,
    );

    await checkServerReachability();
  }

  void _setStatus({
    required bool hasNetwork,
    required bool isServerReachable,
    required bool isChecking,
  }) {
    final prev = _isOnline;

    _hasNetwork = hasNetwork;
    _isServerReachable = isServerReachable;
    _isOnline = _hasNetwork && _isServerReachable;
    _isChecking = isChecking;

    notifyListeners();
    _configureServerRetry();

    if (_isOnline && !_initialOnlineHandled) {
      _initialOnlineHandled = true;
      Future.microtask(() async {
        try {
          await onInitialOnline?.call();
        } catch (e) {
          debugPrint('Connectivity onInitialOnline error: $e');
        }
      });
      return;
    }

    if (!prev && _isOnline) {
      Future.microtask(() async {
        try {
          await onBackOnline?.call();
        } catch (e) {
          debugPrint('Connectivity onBackOnline error: $e');
        }
      });
    }
  }

  void _configureServerRetry() {
    final shouldRetry = _hasNetwork && !_isServerReachable;
    if (!shouldRetry) {
      _serverRetryTimer?.cancel();
      _serverRetryTimer = null;
      return;
    }

    if (_serverRetryTimer != null) return;

    _serverRetryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasNetwork && !_isServerReachable) {
        unawaited(checkServerReachability());
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _serverRetryTimer?.cancel();
    super.dispose();
  }
}
