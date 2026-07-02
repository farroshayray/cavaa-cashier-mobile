import 'dart:convert';
import 'dart:io';

import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/orders_api.dart';
import '/features/cashier/data/sync/master_cache_service.dart';
import '/features/cashier/data/sync/offline_catch_up_policy.dart';
import '/features/cashier/data/sync/order_stage_sync_guard.dart';
import '/features/cashier/data/sync/sync_api.dart';
import '/features/cashier/data/sync/sync_payment_helpers.dart';

class SyncEngine {
  SyncEngine({
    required this.bookingOrdersDao,
    required this.syncApi,
    required this.db,
    MasterCacheService? masterCacheService,
    OrdersApi? ordersApi,
  })  : masterCacheService = masterCacheService ?? MasterCacheService(db),
        ordersApi = ordersApi;

  final BookingOrdersDao bookingOrdersDao;
  final SyncApi syncApi;
  final CashierDb db;
  final MasterCacheService masterCacheService;
  final OrdersApi? ordersApi;

  /// Resolves logged-in cashier id for offline detail push fallback.
  int? Function()? resolveCashierProcessId;

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
      SyncResult? lastResult;
      const maxPasses = 8;

      for (var pass = 0; pass < maxPasses; pass++) {
        final hasDirty = await hasPendingData();
        final push = await _buildPushPayload();
        final bookingPush = (push['booking_orders'] as List?) ?? [];

        if (pass > 0) {
          if (!hasDirty || bookingPush.isEmpty) {
            break;
          }
        } else if (bookingPush.isEmpty) {
          ApiDebugLog.sync(
            hasDirty
                ? 'push guard blocked all dirty orders on pass 0 — pull-only'
                : 'pull-only sync (no pending local changes)',
          );
        }

        final lastToken = await bookingOrdersDao.getSyncMeta('last_sync_token') ?? '';
        final detailPush = (push['order_details'] as List?) ?? [];
        ApiDebugLog.sync(
          'push payload pass=$pass',
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
            'pull_scopes': pass == 0 ? pullScopes : const ['orders'],
          },
          idempotencyKey: idempotencyKey,
        );

        _logSyncResponse(response);
        await _applyResponse(response);

        lastResult = SyncResult.fromJson(response, raw: response);

        final applied = ((response['applied'] as List?) ?? []).length;
        if (applied == 0 && !await hasPendingData()) {
          break;
        }
      }

      return lastResult ?? SyncResult(success: true, message: 'nothing to sync');
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
    final linked = await bookingOrdersDao.linkDirtyMirrorsToKnownServerRows();
    if (linked > 0) {
      ApiDebugLog.sync(
        'self-heal',
        'linked $linked offline mirrors to existing server rows',
      );
    }

    final redirty = await bookingOrdersDao.ensureHeaderDirtyForPendingDetails();
    if (redirty > 0) {
      ApiDebugLog.sync(
        'self-heal',
        're-dirtied $redirty orders with pending served details',
      );
    }

    final healed = await bookingOrdersDao.healStuckCashierOpenbillSyncIntents();
    if (healed > 0) {
      ApiDebugLog.sync(
        'self-heal',
        'adjusted $healed stuck cashier openbill sync intents',
      );
    }

    final healedCash = await bookingOrdersDao.healStuckCashTerminalSyncIntents();
    if (healedCash > 0) {
      ApiDebugLog.sync(
        'self-heal',
        'queued $healedCash stuck cash terminal sync intents',
      );
    }

    final healedSynced = await bookingOrdersDao.healMirrorsSyncedWithServer();
    if (healedSynced > 0) {
      ApiDebugLog.sync(
        'self-heal',
        'cleared $healedSynced mirrors already aligned with server',
      );
    }

    final dirtyOrders = await bookingOrdersDao.getAllDirtyBookingOrders();
    dirtyOrders.sort((a, b) {
      final aIsUpdate = (a.syncIntent ?? '').toUpperCase() == 'UPDATE' ? 0 : 1;
      final bIsUpdate = (b.syncIntent ?? '').toUpperCase() == 'UPDATE' ? 0 : 1;
      if (aIsUpdate != bIsUpdate) return aIsUpdate.compareTo(bIsUpdate);
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    final bookingOrdersPayload = <Map<String, dynamic>>[];
    final orderDetailsPayload = <Map<String, dynamic>>[];
    final deletes = <Map<String, dynamic>>[];

    for (final order in dirtyOrders) {
      final bundle = await bookingOrdersDao.getBundleByClientUuid(order.clientUuid);
      final useCatchUp = await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
        order: order,
        hasDirtyServedDetails: bookingOrdersDao.hasDirtyServedDetails,
      );

      final storedIntent = order.syncIntent ?? 'CREATE';
      final effectiveIntent = useCatchUp
          ? 'OFFLINE_CATCH_UP'
          : OrderStageSyncGuard.resolvePushIntent(
              storedIntent: storedIntent,
              orderStatus: order.orderStatus,
              serverId: order.serverId,
            );
      final neverSynced = order.serverId == null || order.serverId! <= 0;
      final offlineCatchUp = useCatchUp ||
          neverSynced ||
          storedIntent.toUpperCase() != effectiveIntent.toUpperCase();
      final guardError = OrderStageSyncGuard.validateIntent(
        currentStatus: order.orderStatus,
        syncIntent: effectiveIntent,
        neverSynced: neverSynced,
        offlineCatchUp: offlineCatchUp || !neverSynced,
      );
      if (guardError != null) {
        ApiDebugLog.syncError('push guard', '${order.clientUuid}: $guardError');
        continue;
      }

      if (effectiveIntent == 'DELETE' && order.serverId != null) {
        deletes.add({'table': 'booking_orders', 'server_id': order.serverId});
        continue;
      }

      final items = await _buildItemsPayload(bundle);
      final subtotal = _resolveSubtotalForPush(order, bundle);

      final row = <String, dynamic>{
        'client_uuid': order.clientUuid,
        // Use createdAt so idempotency key stays stable after failed retries bump updatedAt.
        'client_timestamp':
            (order.createdAt ?? order.updatedAt ?? DateTime.now()).toIso8601String(),
        'sync_intent': effectiveIntent,
        'stored_sync_intent': storedIntent,
        'sync_version': order.syncVersion,
        if (order.serverId != null) 'id': order.serverId,
        'order_table': order.tableId,
        'table_id': order.tableId,
        'customer_name': order.customerName,
        'order_name': _checkoutOrderName(order.customerName),
        'payment_method': _checkoutPaymentMethod(order),
        'openbill_flag': order.openbillFlag,
        if (order.orderBy != null && order.orderBy!.trim().isNotEmpty)
          'order_by': order.orderBy,
        'total_amount': subtotal,
        'total_order_value': subtotal,
        'order_status': order.orderStatus,
        'local_target_status': effectiveIntent == 'OFFLINE_CATCH_UP'
            ? OfflineCatchUpPolicy.resolveCatchUpTargetStatus(
                order: order,
                bundle: bundle,
              )
            : order.orderStatus,
        'items': items,
        if (order.paidAmountLocal != null) 'paid_amount': order.paidAmountLocal,
        if (order.changeAmountLocal != null) 'change_amount': order.changeAmountLocal,
      };

      final lastPaymentId = resolveLastPaymentIdForPush(
        latestPaymentServerId: order.latestPaymentServerId,
        paymentId: order.paymentId,
      );
      if (lastPaymentId != null) {
        row['last_payment_id'] = lastPaymentId;
      }

      if (effectiveIntent == 'OFFLINE_CATCH_UP') {
        row['order_details'] = _buildOrderDetailsCatchUpPayload(bundle);
      }

      if (effectiveIntent == 'SERVE_ITEMS') {
        final detailIds = _collectServedDetailIdsForPush(bundle);
        if (detailIds.isNotEmpty) {
          row['detail_ids'] = detailIds;
        }
      }

      bookingOrdersPayload.add(row);

      final dirtyDetails = await bookingOrdersDao.getDirtyDetailsForOrder(order.clientUuid);
      final skipDetailPush = effectiveIntent == 'CREATE' ||
          effectiveIntent == 'CONFIRM_OPENBILL' ||
          effectiveIntent == 'OFFLINE_CATCH_UP' ||
          neverSynced;
      for (final detail in dirtyDetails) {
        if (skipDetailPush) continue;

        final detailPayload = _buildDetailPushPayload(
          detail: detail,
          order: order,
        );

        if (detail.serverId != null) {
          orderDetailsPayload.add(detailPayload);
          continue;
        }

        if (order.serverId != null) {
          orderDetailsPayload.add({
            ...detailPayload,
            'booking_order_id': order.serverId,
            'product_id': detail.partnerProductId,
          });
        }
      }
    }

    return {
      'booking_orders': bookingOrdersPayload,
      'order_details': orderDetailsPayload,
      'deletes': deletes,
    };
  }

  List<Map<String, dynamic>> _buildOrderDetailsCatchUpPayload(BookingOrderBundle? bundle) {
    if (bundle == null) return [];

    return bundle.details.map((detail) {
      final status = (detail.status ?? '').trim();
      final row = <String, dynamic>{
        if (detail.serverId != null) 'id': detail.serverId,
        'client_detail_uuid': detail.clientDetailUuid,
        'quantity': detail.quantity,
      };
      if (status.isNotEmpty) {
        row['status'] = status;
      }
      return row;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _buildItemsPayload(BookingOrderBundle? bundle) async {
    if (bundle == null) return [];

    final items = <Map<String, dynamic>>[];
    for (final detail in bundle.details) {
      final options = bundle.optionsByDetailUuid[detail.clientDetailUuid] ?? [];
      final row = <String, dynamic>{
        if (detail.serverId != null) 'detail_id': detail.serverId,
        'product_id': detail.partnerProductId,
        'qty': detail.quantity,
        'note': detail.customerNote,
        'promo_id': detail.promoId,
        'option_ids': options.map((o) => o.optionId).toList(),
      };
      final status = (detail.status ?? '').trim();
      if (status.isNotEmpty) {
        row['status'] = status;
      }
      items.add(row);
    }
    return items;
  }

  /// Subtotal before PPN — prefer line-item sum over mirror field.
  num _resolveSubtotalForPush(BookingOrder order, BookingOrderBundle? bundle) {
    final fromDetails = _subtotalFromBundle(bundle);
    if (fromDetails > 0) {
      return fromDetails;
    }
    return order.totalOrderValue;
  }

  num _subtotalFromBundle(BookingOrderBundle? bundle) {
    if (bundle == null || bundle.details.isEmpty) return 0;

    return bundle.details.fold<num>(0, (sum, detail) {
      final base = detail.basePrice;
      final options = detail.optionsPrice;
      final promo = detail.promoAmount ?? 0;
      final qty = detail.quantity;
      final line = (base + options - promo) * qty;
      return sum + (line > 0 ? line : 0);
    });
  }

  List<int> _collectServedDetailIdsForPush(BookingOrderBundle? bundle) {
    if (bundle == null) return [];

    return bundle.details
        .where((detail) {
          if (detail.syncDirty != true) return false;
          final status = (detail.status ?? '').trim().toUpperCase();
          return status.contains('SERVED');
        })
        .map((detail) => detail.serverId)
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
  }

  Future<void> _applyResponse(Map<String, dynamic> response) async {
    final applied = (response['applied'] as List?) ?? [];
    for (final raw in applied) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        await bookingOrdersDao.applyAppliedResult(map);
        await bookingOrdersDao.queueRemainingSyncIntentIfNeeded(
          clientUuid: map['client_uuid']?.toString() ?? '',
          appliedIntent: map['sync_intent']?.toString() ?? '',
          appliedServerStatus: map['order_status']?.toString(),
        );
        ApiDebugLog.sync(
          'applied locally',
          '${map['sync_intent']} client=${map['client_uuid']} server_id=${map['server_id']}',
        );
      }
    }

    final conflicts = (response['conflicts'] as List?) ?? [];
    for (final raw in conflicts) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final clientUuid = map['client_uuid']?.toString();
        if ((map['local'] == null || map['local'] is! Map) &&
            clientUuid != null &&
            clientUuid.isNotEmpty) {
          final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
          if (bundle != null) {
            map['local'] = {
              'order_status': bundle.order.orderStatus,
              'booking_order_code': bundle.order.bookingOrderCode,
              'sync_version': bundle.order.syncVersion,
              'order_details': bundle.details
                  .map((d) => OrderMirrorMapper.detailToUiMap(d))
                  .toList(),
            };
          }
        }
        await bookingOrdersDao.saveConflict(map);
      }
    }

    final errors = (response['errors'] as List?) ?? [];
    for (final raw in errors) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final clientUuid = map['client_uuid']?.toString();
      final message = map['message']?.toString();
      if (clientUuid == null ||
          clientUuid.isEmpty ||
          message == null ||
          message.isEmpty) {
        continue;
      }
      await bookingOrdersDao.markSyncErrorByClientUuid(clientUuid, message);
    }

    final pulled = response['pulled'];
    if (pulled is Map) {
      final orders = pulled['orders'];
      if (orders is Map) {
        final bookingOrders = (orders['booking_orders'] as List?) ?? [];
        final pulledServerStatusById = <int, String>{};
        for (final raw in bookingOrders) {
          if (raw is Map) {
            final map = Map<String, dynamic>.from(raw);
            final serverId = _toInt(map['id']);
            if (serverId != null) {
              pulledServerStatusById[serverId] =
                  map['order_status']?.toString() ?? '';
            }
            await bookingOrdersDao.upsertFromServer(map);
          }
        }

        final healedSynced = await bookingOrdersDao.healMirrorsSyncedWithServer(
          serverStatusById: pulledServerStatusById,
        );
        if (healedSynced > 0) {
          ApiDebugLog.sync(
            'self-heal',
            'cleared $healedSynced stale dirty mirrors after pull',
          );
        }

        final standaloneDetails = (orders['order_details'] as List?) ?? [];
        for (final raw in standaloneDetails) {
          if (raw is Map) {
            await bookingOrdersDao.upsertDetailFromServerRow(
              Map<String, dynamic>.from(raw),
            );
          }
        }

        final deletedOrders = (orders['deleted_booking_orders'] as List?) ?? [];
        for (final raw in deletedOrders) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);
          final serverId = _toInt(map['id']);
          if (serverId == null) continue;
          final deletedAt = DateTime.tryParse((map['deleted_at'] ?? '').toString());
          await bookingOrdersDao.markDeletedByServerId(
            serverId,
            deletedAt: deletedAt,
          );
        }

        final orderPayments = (orders['order_payments'] as List?) ?? [];
        for (final raw in orderPayments) {
          if (raw is Map) {
            await bookingOrdersDao.upsertPaymentFromServer(
              Map<String, dynamic>.from(raw),
            );
          }
        }

        ApiDebugLog.sync(
          'pull applied',
          'booking_orders=${bookingOrders.length} '
          'standalone_details=${standaloneDetails.length} '
          'deleted_orders=${deletedOrders.length} '
          'order_payments=${orderPayments.length}',
        );

        final reconciled = await bookingOrdersDao.reconcileDuplicateMirrors();
        if (reconciled > 0) {
          ApiDebugLog.sync('self-heal', 'reconciled $reconciled duplicate mirrors after pull');
        }
      }

      final master = pulled['master'];
      if (master is Map) {
        final masterMap = Map<String, dynamic>.from(master);
        final lastToken =
            await bookingOrdersDao.getSyncMeta('last_sync_token') ?? '';
        if (lastToken.isEmpty) {
          await masterCacheService.saveAndBuildPayload(masterMap);
        } else {
          await masterCacheService.mergeMasterPayload(masterMap);
        }
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

    await _uploadPendingCashierProofs();
  }

  Future<void> _uploadPendingCashierProofs() async {
    final api = ordersApi;
    if (api == null) return;

    final pending = await bookingOrdersDao.getOrdersWithPendingCashierProof();
    for (final order in pending) {
      final proofPath = bookingOrdersDao.readCashierProofPath(order);
      final serverId = order.serverId;
      final paymentId = resolveLastPaymentIdForPush(
        latestPaymentServerId: order.latestPaymentServerId,
        paymentId: order.paymentId,
      );
      if (proofPath == null ||
          serverId == null ||
          serverId <= 0 ||
          paymentId == null) {
        continue;
      }
      if (!File(proofPath).existsSync()) {
        await bookingOrdersDao.clearCashierProofPath(order.clientUuid);
        continue;
      }

      try {
        await api.paymentOrder(
          id: serverId,
          paidAmount: order.paidAmountLocal ?? order.totalOrderValue,
          changeAmount: order.changeAmountLocal ?? 0,
          paymentMethod: order.paymentMethod,
          lastPaymentId: paymentId.toString(),
          cashierProofImagePath: proofPath,
        );
        await bookingOrdersDao.clearCashierProofPath(order.clientUuid);
        try {
          await File(proofPath).delete();
        } catch (_) {}
        ApiDebugLog.sync(
          'cashier proof uploaded',
          'order=$serverId payment=$paymentId',
        );
      } catch (e) {
        ApiDebugLog.syncError('cashier proof upload failed', e.toString());
      }
    }
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
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

    final parts = <String>[];
    for (final raw in orders) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      parts.add(
        '${map['client_uuid']}|${map['sync_intent']}|${map['client_timestamp']}',
      );
    }
    return SyncApi.buildBatchIdempotencyKey(parts);
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
    final method = (order.paymentMethod ?? '').trim();
    if (order.openbillFlag) {
      if (order.paidAmountLocal != null &&
          method.isNotEmpty &&
          method.toUpperCase() != 'OPENBILL') {
        return method;
      }
      return 'OPENBILL';
    }
    if (method.isEmpty) return 'CASH';
    return method;
  }

  Map<String, dynamic> _buildDetailPushPayload({
    required OrderDetail detail,
    required BookingOrder order,
  }) {
    final status = (detail.status ?? '').trim().toUpperCase();
    var cashierProcessId = detail.cashierProcessId;

    if ((cashierProcessId == null || cashierProcessId <= 0) &&
        status == 'SERVED BY CASHIER') {
      final fallback = order.cashierProcessId ?? resolveCashierProcessId?.call();
      if (fallback != null && fallback > 0) {
        cashierProcessId = fallback;
      }
    }

    return {
      if (detail.serverId != null) 'id': detail.serverId,
      'client_detail_uuid': detail.clientDetailUuid,
      'sync_version': detail.syncVersion,
      'status': detail.status,
      if (cashierProcessId != null && cashierProcessId > 0)
        'cashier_process_id': cashierProcessId,
      'kitchen_process_id': detail.kitchenProcessId,
      'quantity': detail.quantity,
    };
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

    final hasIssues = errorCount > 0 || conflictCount > 0;
    String? message;
    if (errorCount > 0) {
      message = 'Sync selesai dengan $errorCount error';
    } else if (conflictCount > 0) {
      message = 'Sync selesai dengan $conflictCount konflik';
    }

    return SyncResult(
      success: !hasIssues,
      syncToken: json['sync_token']?.toString(),
      appliedCount: ((json['applied'] as List?) ?? []).length,
      conflictCount: conflictCount,
      errorCount: errorCount,
      message: message,
      rawResponse: raw ?? json,
    );
  }

  factory SyncResult.skipped() => SyncResult(success: false, message: 'skipped');

  factory SyncResult.failed(String message) =>
      SyncResult(success: false, message: message);
}
