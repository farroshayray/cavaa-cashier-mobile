import 'package:flutter/foundation.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';

class LocalReconciliationService {
  final LocalOrdersDao localOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  final CachedProcessOrdersDao cachedProcessOrdersDao;
  final CachedDoneOrdersDao cachedDoneOrdersDao;

  LocalReconciliationService({
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
    required this.cachedProcessOrdersDao,
    required this.cachedDoneOrdersDao,
  });

  Future<void> reconcileAll() async {
    debugPrint('🧩 reconcileAll start');

    final localOrders = await localOrdersDao.getAllActiveOrders();
    final paymentOrders = await cachedPaymentOrdersDao.getAllActiveOrders();
    final processOrders = await cachedProcessOrdersDao.getAllActive();
    final doneOrders = await cachedDoneOrdersDao.getAllActive();

    final buckets = <String, _ReconcileBucket>{};

    void putBucket(String key, void Function(_ReconcileBucket bucket) fill) {
      final bucket = buckets.putIfAbsent(key, () => _ReconcileBucket());
      fill(bucket);
    }

    for (final row in localOrders) {
      final key = _buildLocalKey(row);
      putBucket(key, (b) => b.local = row);
    }

    for (final row in paymentOrders) {
      final key = _buildServerKey(
        serverId: row.serverId,
        bookingOrderCode: row.bookingOrderCode,
      );
      putBucket(key, (b) => b.payment = row);
    }

    for (final row in processOrders) {
      final key = _buildServerKey(
        serverId: row.serverId,
        bookingOrderCode: row.bookingOrderCode,
      );
      putBucket(key, (b) => b.process = row);
    }

    for (final row in doneOrders) {
      final key = _buildServerKey(
        serverId: row.serverId,
        bookingOrderCode: row.bookingOrderCode,
      );
      putBucket(key, (b) => b.done = row);
    }

    for (final entry in buckets.entries) {
      final bucket = entry.value;

      final finalStatus = _resolveFinalStatus(bucket);
      final finalRank = _statusRank(finalStatus);

      final local = bucket.local;
      final payment = bucket.payment;
      final process = bucket.process;
      final done = bucket.done;

      final serverId = _resolveServerId(bucket);
      final orderCode = _resolveOrderCode(bucket);

      debugPrint(
        '🧠 reconcile bucket key=${entry.key} '
        'serverId=$serverId code=$orderCode finalStatus=$finalStatus '
        'local=${local?.orderStatusLocal} '
        'payment=${payment?.orderStatus} '
        'process=${process?.orderStatus} '
        'done=${done?.orderStatus}',
      );

      // 1. kalau final status sudah bukan UNPAID,
      // payment cache harus dibersihkan
      if (serverId != null && finalRank >= _statusRank('PAID')) {
        if (payment != null) {
          await cachedPaymentOrdersDao.deleteCachedOrderByServerId(serverId);
          debugPrint('🧹 removed payment cache serverId=$serverId');
        }
      }

      // 2. kalau final status sudah SERVED,
      // process cache harus dibersihkan
      if (serverId != null && finalRank >= _statusRank('SERVED')) {
        if (process != null) {
          await cachedProcessOrdersDao.deleteByServerId(serverId);
          debugPrint('🧹 removed process cache serverId=$serverId');
        }
      }

      // 3. sinkronkan local row ke status final tertinggi
      if (local != null) {
        final localRank = _statusRank(local.orderStatusLocal);

        final hasPendingLocalChange =
            local.syncStatus != 'SYNCED' &&
            local.syncStatus != 'PENDING_DELETE';

        // hanya paksa naik kalau local sudah SYNCED
        // supaya tidak menimpa aksi lokal yang belum terkirim
        if (!hasPendingLocalChange && finalRank > localRank) {
          await localOrdersDao.updateOrderStatusByLocalId(
            localId: local.localId,
            status: finalStatus,
            syncStatus: 'SYNCED',
            backendStage: _backendStageFromStatus(finalStatus),
          );

          debugPrint(
            '⬆️ local upgraded localId=${local.localId} '
            'from=${local.orderStatusLocal} to=$finalStatus',
          );
        }

        // kalau row local shadow/mirror sudah benar-benar tercermin di cache final,
        // aman dibuang supaya tidak jadi sumber bentrok lagi
        final isSyncedMirror =
            local.syncStatus == 'SYNCED' &&
            local.serverId != null &&
            local.serverId! > 0 &&
            (done != null || process != null || payment != null);

        final isShadow = local.localId.startsWith('shadow_');

        if (isSyncedMirror && isShadow) {
          await localOrdersDao.deleteOrderByLocalId(local.localId);
          debugPrint('🗑️ removed synced shadow localId=${local.localId}');
        }
      }
    }

    debugPrint('✅ reconcileAll done');
  }

  String _buildLocalKey(LocalOrder row) {
    if (row.serverId != null && row.serverId! > 0) {
      return 'sid:${row.serverId}';
    }

    final code = (row.serverOrderCode ?? row.clientOrderCode).trim();
    if (code.isNotEmpty) {
      return 'code:$code';
    }

    return 'local:${row.localId}';
  }

  String _buildServerKey({
    required int serverId,
    required String bookingOrderCode,
  }) {
    if (serverId > 0) return 'sid:$serverId';

    final code = bookingOrderCode.trim();
    if (code.isNotEmpty) return 'code:$code';

    return 'unknown:${DateTime.now().microsecondsSinceEpoch}';
  }

  int? _resolveServerId(_ReconcileBucket bucket) {
    return bucket.local?.serverId ??
        bucket.payment?.serverId ??
        bucket.process?.serverId ??
        bucket.done?.serverId;
  }

  String? _resolveOrderCode(_ReconcileBucket bucket) {
    return bucket.local?.serverOrderCode ??
        bucket.local?.clientOrderCode ??
        bucket.payment?.bookingOrderCode ??
        bucket.process?.bookingOrderCode ??
        bucket.done?.bookingOrderCode;
  }

  String _resolveFinalStatus(_ReconcileBucket bucket) {
    final statuses = <String>[
      if (bucket.local != null) bucket.local!.orderStatusLocal,
      if (bucket.payment != null) _normalizeStatus(bucket.payment!.orderStatus, source: 'payment'),
      if (bucket.process != null) _normalizeStatus(bucket.process!.orderStatus, source: 'process'),
      if (bucket.done != null) _normalizeStatus(bucket.done!.orderStatus, source: 'done'),
    ];

    if (statuses.isEmpty) return 'UNPAID';

    statuses.sort((a, b) => _statusRank(a).compareTo(_statusRank(b)));
    return statuses.last;
  }

  String _normalizeStatus(String? raw, {required String source}) {
    final s = (raw ?? '').trim().toUpperCase();

    if (s == 'UNPAID' || s == 'PAID' || s == 'PROCESSED' || s == 'SERVED') {
      return s;
    }

    if (source == 'done') return 'SERVED';
    if (source == 'process') return 'PROCESSED';
    if (source == 'payment') return 'UNPAID';

    return 'UNPAID';
  }

  int _statusRank(String status) {
    switch (status) {
      case 'UNPAID':
        return 0;
      case 'PAID':
        return 1;
      case 'PROCESSED':
        return 2;
      case 'SERVED':
        return 3;
      default:
        return 0;
    }
  }

  String _backendStageFromStatus(String status) {
    switch (status) {
      case 'UNPAID':
        return 'PURCHASED';
      case 'PAID':
        return 'PAID';
      case 'PROCESSED':
        return 'PROCESSED';
      case 'SERVED':
        return 'SERVED';
      default:
        return 'NONE';
    }
  }
}

class _ReconcileBucket {
  LocalOrder? local;
  CachedPaymentOrder? payment;
  CachedProcessOrder? process;
  CachedDoneOrder? done;
}