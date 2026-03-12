import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityStatusProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool _isChecking = true;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  Future<void> init() async {
    try {
      _isChecking = true;
      notifyListeners();

      final result = await _connectivity.checkConnectivity();
      _updateFromResults(result);

      _sub = _connectivity.onConnectivityChanged.listen((results) {
        _updateFromResults(results);
      });
    } catch (e) {
      debugPrint('Connectivity init error: $e');
      _isOnline = true;
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> Function()? onBackOnline;

  void _updateFromResults(List<ConnectivityResult> results) {
    final prev = _isOnline;
    final hasConnectionType = results.any((r) => r != ConnectivityResult.none);

    _isOnline = hasConnectionType;
    _isChecking = false;
    notifyListeners();

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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}