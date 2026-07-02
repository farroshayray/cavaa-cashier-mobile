import 'dart:async';

import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';

/// Periodic background sync when device is online.
class SyncWorker {
  SyncWorker({
    required this.syncService,
    required this.connectivity,
    this.interval = const Duration(minutes: 2),
  });

  final SyncService syncService;
  final ConnectivityStatusProvider connectivity;
  final Duration interval;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_tick()));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_running || !connectivity.isOnline || syncService.isRunning) return;
    _running = true;
    try {
      await syncService.syncPendingOrders();
    } catch (_) {
    } finally {
      _running = false;
    }
  }
}
