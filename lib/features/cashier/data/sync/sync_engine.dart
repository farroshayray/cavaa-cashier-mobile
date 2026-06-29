import 'dart:convert';

import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/sync/master_cache_service.dart';
import '/features/cashier/data/sync/sync_api.dart';

class SyncEngine {
  SyncEngine({
    required this.bookingOrdersDao,
    required this.syncApi,
    required this.db,
    MasterCacheService? masterCacheService,
  })  : masterCacheService = masterCacheService ?? MasterCacheService(db);

  final BookingOrdersDao bookingOrdersDao;
  final SyncApi syncApi;
  final CashierDb db;
  final MasterCacheService masterCacheService;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<bool> hasPendingData() async {
    final dirty = await bookingOrdersDao.getAllDirtyBookingOrders();
    return dirty.isNotEmpty;
  }

  Future<SyncResult> syncAll({List<String> pullScopes = const ['orders', 'master']}) async {
    if (_isRunning) {
      ApiDebugLog.sync('skipped — sync already running');
      return SyncResult.skipped();
    }

    _isRunning = true;
    try {
      final push = await _buildPushPayload();
      final lastToken = await bookingOrdersDao.getSyncMeta('last_sync_token') ?? '';

      final bookingPush = (push['booking_orders'] as List?) ?? [];
      final detailPush = (push['order_details'] as List?) ?? [];
      ApiDebugLog.sync(
        'push payload',
        'booking_orders=${bookingPush.length} '
        'order_details=${detailPush.length} '
        'deletes=${(push['deletes'] as List?)?.length ?? 0} '
        'last_sync_token=${lastToken.isEmpty ? '(empty)' : lastToken}',
      );

      if (bookingPush.isNotEmpty) {
        ApiDebugLog.sync('first push order', _safeJson(bookingPush.first));
      }

      final idempotencyKey = _buildBatchIdempotencyKey(push);
      final response = await syncApi.sync(
        payload: {
          'device_id': await bookingOrdersDao.getSyncMeta('device_id') ?? 'mobile',
          'last_sync_token': lastToken,
          'push': push,
          'pull_scopes': pullScopes,
        },
        idempotencyKey: idempotencyKey,
      );

      _logSyncResponse(response);
      await _applyResponse(response);

      return SyncResult.fromJson(response, raw: response);
    } catch (e, st) {
      ApiDebugLog.syncError('sync failed', '$e\n$st');
      return SyncResult.failed(e.toString());
    } finally {
      _isRunning = false;
    }
  }

  void _logSyncResponse(Map<String, dynamic> response) {
    final applied = (response['applied'] as List?) ?? [];
    final conflicts = (response['conflicts'] as List?) ?? [];
    final errors = (response['errors'] as List?) ?? [];
    final pulled = response['pulled'];
    int pulledOrders = 0;
    if (pulled is Map && pulled['orders'] is Map) {
      pulledOrders = ((pulled['orders'] as Map)['booking_orders'] as List?)?.length ?? 0;
    }

    ApiDebugLog.sync(
      'response summary',
      'applied=${applied.length} conflicts=${conflicts.length} '
      'errors=${errors.length} pulled_orders=$pulledOrders '
      'sync_token=${response['sync_token']}',
    );

    for (final raw in errors) {
      if (raw is Map) {
        ApiDebugLog.syncError(
          'server rejected',
          '${raw['sync_intent'] ?? '?'} client=${raw['client_uuid'] ?? '?'}: ${raw['message']}',
        );
      }
    }

    for (final raw in conflicts) {
      if (raw is Map) {
        ApiDebugLog.syncError(
          'conflict',
          '${raw['reason'] ?? '?'} table=${raw['table']} client=${raw['client_uuid']}',
        );
      }
    }

    final debug = response['debug'];
    if (debug is Map) {
      ApiDebugLog.sync('server debug', debug);
    }
  }

  Future<Map<String, dynamic>> _buildPushPayload() async {
    final dirtyOrders = await bookingOrdersDao.getAllDirtyBookingOrders();
    final bookingOrdersPayload = <Map<String, dynamic>>[];
    final orderDetailsPayload = <Map<String, dynamic>>[];
    final deletes = <Map<String, dynamic>>[];

    for (final order in dirtyOrders) {
      final intent = order.syncIntent ?? 'CREATE';
      if (intent == 'DELETE' && order.serverId != null) {
        deletes.add({'table': 'booking_orders', 'server_id': order.serverId});
        continue;
      }

      final bundle = await bookingOrdersDao.getBundleByClientUuid(order.clientUuid);
      final items = await _buildItemsPayload(bundle);

      final row = <String, dynamic>{
        'client_uuid': order.clientUuid,
        'client_timestamp': (order.updatedAt ?? DateTime.now()).toIso8601String(),
        'sync_intent': intent,
        'sync_version': order.syncVersion,
        if (order.serverId != null) 'id': order.serverId,
        'order_table': order.tableId,
        'table_id': order.tableId,
        'customer_name': order.customerName,
        'order_name': _checkoutOrderName(order.customerName),
        'payment_method': _checkoutPaymentMethod(order),
        'openbill_flag': order.openbillFlag,
        'total_amount': order.totalOrderValue,
        'total_order_value': order.totalOrderValue,
        'items': items,
        if (order.paidAmountLocal != null) 'paid_amount': order.paidAmountLocal,
        if (order.changeAmountLocal != null) 'change_amount': order.changeAmountLocal,
        if (order.latestPaymentServerId != null)
          'last_payment_id': order.latestPaymentServerId,
      };

      bookingOrdersPayload.add(row);

      final dirtyDetails = await bookingOrdersDao.getDirtyDetailsForOrder(order.clientUuid);
      for (final detail in dirtyDetails) {
        orderDetailsPayload.add({
          'id': detail.serverId,
          'client_detail_uuid': detail.clientDetailUuid,
          'sync_version': detail.syncVersion,
          'status': detail.status,
          'cashier_process_id': detail.cashierProcessId,
          'kitchen_process_id': detail.kitchenProcessId,
          'quantity': detail.quantity,
        });
      }
    }

    return {
      'booking_orders': bookingOrdersPayload,
      'order_details': orderDetailsPayload,
      'deletes': deletes,
    };
  }

  Future<List<Map<String, dynamic>>> _buildItemsPayload(BookingOrderBundle? bundle) async {
    if (bundle == null) return [];

    final items = <Map<String, dynamic>>[];
    for (final detail in bundle.details) {
      final options = bundle.optionsByDetailUuid[detail.clientDetailUuid] ?? [];
      items.add({
        if (detail.serverId != null) 'detail_id': detail.serverId,
        'product_id': detail.partnerProductId,
        'qty': detail.quantity,
        'note': detail.customerNote,
        'promo_id': detail.promoId,
        'option_ids': options.map((o) => o.optionId).toList(),
      });
    }
    return items;
  }

  Future<void> _applyResponse(Map<String, dynamic> response) async {
    final applied = (response['applied'] as List?) ?? [];
    for (final raw in applied) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        await bookingOrdersDao.applyAppliedResult(map);
        ApiDebugLog.sync(
          'applied locally',
          '${map['sync_intent']} client=${map['client_uuid']} server_id=${map['server_id']}',
        );
      }
    }

    final conflicts = (response['conflicts'] as List?) ?? [];
    for (final raw in conflicts) {
      if (raw is Map) {
        await bookingOrdersDao.saveConflict(Map<String, dynamic>.from(raw));
      }
    }

    final pulled = response['pulled'];
    if (pulled is Map) {
      final orders = pulled['orders'];
      if (orders is Map) {
        final bookingOrders = (orders['booking_orders'] as List?) ?? [];
        for (final raw in bookingOrders) {
          if (raw is Map) {
            await bookingOrdersDao.upsertFromServer(Map<String, dynamic>.from(raw));
          }
        }

        final standaloneDetails = (orders['order_details'] as List?) ?? [];
        for (final raw in standaloneDetails) {
          if (raw is Map) {
            await bookingOrdersDao.upsertDetailFromServerRow(
              Map<String, dynamic>.from(raw),
            );
          }
        }

        ApiDebugLog.sync(
          'pull applied',
          'booking_orders=${bookingOrders.length} '
          'standalone_details=${standaloneDetails.length}',
        );
      }

      final master = pulled['master'];
      if (master is Map) {
        await masterCacheService.saveAndBuildPayload(
          Map<String, dynamic>.from(master),
        );
        await bookingOrdersDao.setSyncMeta(
          'last_master_sync',
          DateTime.now().toIso8601String(),
        );
        ApiDebugLog.sync('master cache updated');
      }
    }

    final syncToken = response['sync_token']?.toString();
    if (syncToken != null && syncToken.isNotEmpty) {
      await bookingOrdersDao.setSyncMeta('last_sync_token', syncToken);
    }
  }

  String _buildBatchIdempotencyKey(Map<String, dynamic> push) {
    final orders = (push['booking_orders'] as List?) ?? [];
    if (orders.isEmpty) {
      return SyncApi.buildIdempotencyKey(
        clientUuid: 'batch',
        syncIntent: 'PULL',
        clientTimestamp: DateTime.now().toIso8601String(),
      );
    }

    final first = Map<String, dynamic>.from(orders.first as Map);
    return SyncApi.buildIdempotencyKey(
      clientUuid: first['client_uuid']?.toString() ?? 'batch',
      syncIntent: first['sync_intent']?.toString() ?? 'SYNC',
      clientTimestamp: first['client_timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  String _checkoutOrderName(String customerName) {
    final trimmed = customerName.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('guest-')) {
      return trimmed.substring(6).trim().isEmpty ? 'guest' : trimmed.substring(6).trim();
    }
    return trimmed.isEmpty ? 'guest' : trimmed;
  }

  String? _checkoutPaymentMethod(BookingOrder order) {
    if (order.openbillFlag) return 'OPENBILL';
    final method = (order.paymentMethod ?? '').trim();
    if (method.isEmpty) return 'CASH';
    return method;
  }

  String _safeJson(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class SyncResult {
  SyncResult({
    required this.success,
    this.syncToken,
    this.appliedCount = 0,
    this.conflictCount = 0,
    this.errorCount = 0,
    this.message,
    this.rawResponse,
  });

  final bool success;
  final String? syncToken;
  final int appliedCount;
  final int conflictCount;
  final int errorCount;
  final String? message;
  final Map<String, dynamic>? rawResponse;

  factory SyncResult.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? raw,
  }) {
    final errorCount = ((json['errors'] as List?) ?? []).length;
    final conflictCount = ((json['conflicts'] as List?) ?? []).length;

    return SyncResult(
      success: errorCount == 0,
      syncToken: json['sync_token']?.toString(),
      appliedCount: ((json['applied'] as List?) ?? []).length,
      conflictCount: conflictCount,
      errorCount: errorCount,
      message: errorCount > 0
          ? 'Sync selesai dengan $errorCount error'
          : (conflictCount > 0 ? 'Sync selesai dengan $conflictCount konflik' : null),
      rawResponse: raw ?? json,
    );
  }

  factory SyncResult.skipped() => SyncResult(success: false, message: 'skipped');

  factory SyncResult.failed(String message) =>
      SyncResult(success: false, message: message);
}
