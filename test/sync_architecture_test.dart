import 'package:cavaa_cashier/features/cashier/data/local/db/cashier_db.dart';
import 'package:cavaa_cashier/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/offline_catch_up_policy.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_catch_up_sync_policy.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_edit_conflict_detector.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/sync_payment_helpers.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_stage_rank.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_stage_sync_guard.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_sync_intent_chain.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/sync_api.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/sync_engine.dart';
import 'package:cavaa_cashier/features/cashier/presentation/utils/order_tab_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncResult success criteria', () {
    test('fails when conflicts are present', () {
      final result = SyncResult.fromJson({
        'applied': [],
        'conflicts': [
          {'code': 'SYNC_VERSION_STALE'},
        ],
        'errors': [],
      });

      expect(result.success, isFalse);
      expect(result.conflictCount, 1);
    });

    test('fails when errors are present', () {
      final result = SyncResult.fromJson({
        'applied': [{'client_uuid': 'a'}],
        'conflicts': [],
        'errors': [
          {'message': 'failed'},
        ],
      });

      expect(result.success, isFalse);
      expect(result.errorCount, 1);
    });

    test('succeeds when applied without conflicts or errors', () {
      final result = SyncResult.fromJson({
        'applied': [{'client_uuid': 'a'}],
        'conflicts': [],
        'errors': [],
        'sync_token': 'token-1',
      });

      expect(result.success, isTrue);
      expect(result.syncToken, 'token-1');
    });
  });

  group('OrderStageSyncGuard — offline mutation intents', () {
    test('CREATE allowed for UNPAID checkout', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'UNPAID',
          syncIntent: 'CREATE',
        ),
        isNull,
      );
    });

    test('PAY allowed for UNPAID and EXPIRED', () {
      for (final status in ['UNPAID', 'EXPIRED', 'PAYMENT REQUEST']) {
        expect(
          OrderStageSyncGuard.validateIntent(
            currentStatus: status,
            syncIntent: 'PAY',
          ),
          isNull,
          reason: status,
        );
      }
    });

    test('PAY rejected after PAID when already synced online', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'PAID',
          syncIntent: 'PAY',
        ),
        isNotNull,
      );
    });

    test('PAY allowed for offline catch-up when local is PAID', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'PAID',
          syncIntent: 'PAY',
          offlineCatchUp: true,
        ),
        isNull,
      );
    });

    test('PAY allowed for offline catch-up when local is PROCESSED', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'PROCESSED',
          syncIntent: 'PAY',
          offlineCatchUp: true,
        ),
        isNull,
      );
    });

    test('PAY allowed for offline catch-up when local is SERVED', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'PAY',
          offlineCatchUp: true,
        ),
        isNull,
      );
    });

    test('PAY rejected for SERVED without offline catch-up', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'PAY',
        ),
        isNotNull,
      );
    });

    test('FINISH allowed for offline catch-up when local is SERVED', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'FINISH',
          offlineCatchUp: true,
        ),
        isNull,
      );
    });

    test('SERVE_ITEMS allowed for offline catch-up when local is SERVED', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'SERVE_ITEMS',
          offlineCatchUp: true,
        ),
        isNull,
      );
    });

    test('never-synced order always pushes CREATE first', () {
      expect(
        OrderStageSyncGuard.resolvePushIntent(
          storedIntent: 'FINISH',
          orderStatus: 'SERVED',
          serverId: null,
        ),
        'CREATE',
      );
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'CREATE',
          neverSynced: true,
        ),
        isNull,
      );
    });

    test('open bill full cycle intents', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'OPENBILL_CONFIRMATION',
          syncIntent: 'CONFIRM_OPENBILL',
        ),
        isNull,
      );
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'OPENBILL_WAITING_ORDER',
          syncIntent: 'PROCESS',
        ),
        isNull,
      );
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'PROCESSED',
          syncIntent: 'FINISH',
        ),
        isNull,
      );
    });

    test('DELETE always allowed', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'DELETE',
        ),
        isNull,
      );
    });
  });

  group('Batch idempotency key', () {
    test('changes when dirty order set changes', () {
      final keyA = SyncApi.buildBatchIdempotencyKey([
        'uuid-1|PAY|2026-06-30T10:00:00Z',
      ]);
      final keyB = SyncApi.buildBatchIdempotencyKey([
        'uuid-1|PAY|2026-06-30T10:00:00Z',
        'uuid-2|CREATE|2026-06-30T10:01:00Z',
      ]);

      expect(keyA, isNot(keyB));
      expect(keyA.length, 64);
      expect(keyB.length, 64);
    });

    test('stable for identical batch payload', () {
      final parts = [
        'uuid-1|PAY|2026-06-30T10:00:00Z',
        'uuid-2|CREATE|2026-06-30T10:01:00Z',
      ];
      expect(
        SyncApi.buildBatchIdempotencyKey(parts),
        SyncApi.buildBatchIdempotencyKey(parts),
      );
    });
  });

  group('OrderStageRank — pull merge policy', () {
    test('cash local PAID is ahead of server UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'PAID',
          serverStatus: 'UNPAID',
        ),
        isTrue,
      );
    });

    test('cash local SERVED is ahead of server UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'SERVED',
          serverStatus: 'UNPAID',
        ),
        isTrue,
      );
    });

    test('server SERVED is not behind local UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'UNPAID',
          serverStatus: 'SERVED',
        ),
        isFalse,
      );
    });

    test('openbill OPENBILL_CONFIRMATION is ahead of server draft UNPAID rank', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'OPENBILL_CONFIRMATION',
          serverStatus: 'OPENBILL_CONFIRMATION',
          openbillFlag: true,
        ),
        isFalse,
      );
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'OPENBILL_WAITING_ORDER',
          serverStatus: 'OPENBILL_CONFIRMATION',
          openbillFlag: true,
        ),
        isTrue,
      );
    });

    test('openbill UNPAID with PAY intent is ahead of server UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'UNPAID',
          serverStatus: 'UNPAID',
          openbillFlag: true,
          syncIntent: 'PAY',
        ),
        isFalse,
      );
    });

    test('openbill server UNPAID beats local OPENBILL_WAITING_ORDER', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'OPENBILL_WAITING_ORDER',
          serverStatus: 'UNPAID',
          openbillFlag: true,
        ),
        isFalse,
      );
      expect(
        OrderStageRank.rankFor(
          status: 'UNPAID',
          openbillFlag: true,
        ),
        greaterThan(
          OrderStageRank.rankFor(
            status: 'OPENBILL_WAITING_ORDER',
            openbillFlag: true,
          ),
        ),
      );
    });

    test('openbill server OPENBILL_CONFIRMATION beats local payment-ready UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'UNPAID',
          serverStatus: 'OPENBILL_CONFIRMATION',
          openbillFlag: true,
        ),
        isFalse,
      );
    });

    test('openbill server OPENBILL_WAITING_ORDER beats local payment-ready UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'UNPAID',
          serverStatus: 'OPENBILL_WAITING_ORDER',
          openbillFlag: true,
        ),
        isFalse,
      );
    });

    test('openbill UNPAID local equals server UNPAID is not ahead', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'UNPAID',
          serverStatus: 'UNPAID',
          openbillFlag: true,
        ),
        isFalse,
      );
    });

    test('isTerminalStatus recognizes served lifecycle end states', () {
      expect(OrderStageRank.isTerminalStatus('SERVED'), isTrue);
      expect(OrderStageRank.isTerminalStatus('DONE'), isTrue);
      expect(OrderStageRank.isTerminalStatus('PAID'), isFalse);
      expect(OrderStageRank.isTerminalStatus('UNPAID'), isFalse);
    });

    test('SERVED local equals server is not ahead but is terminal', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
        ),
        isFalse,
      );
      expect(OrderStageRank.isTerminalStatus('SERVED'), isTrue);
    });
  });

  group('OrderSyncIntentChain — after CREATE', () {
    test('cash PROCESSED queues FINISH', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'PROCESSED',
          storedIntent: 'PROCESS',
        ),
        'FINISH',
      );
    });

    test('cash SERVED queues PROCESS', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'SERVED',
          storedIntent: 'FINISH',
        ),
        'PROCESS',
      );
    });

    test('cash PAID queues PROCESS', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'PAID',
          storedIntent: 'PAY',
        ),
        'PROCESS',
      );
    });

    test('openbill OPENBILL_CONFIRMATION queues CONFIRM_OPENBILL', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'OPENBILL_CONFIRMATION',
          storedIntent: 'CREATE',
          openbillFlag: true,
        ),
        'CONFIRM_OPENBILL',
      );
    });

    test('cashier openbill WAITING_ORDER queues CONFIRM_OPENBILL when server still CONFIRMATION', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'CREATE',
          openbillFlag: true,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_CONFIRMATION',
        ),
        'CONFIRM_OPENBILL',
      );
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'CONFIRM_OPENBILL',
          openbillFlag: true,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_CONFIRMATION',
        ),
        isNull,
      );
    });

    test('cashier openbill WAITING_ORDER needs no follow-up when server already WAITING', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'CREATE',
          openbillFlag: true,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_WAITING_ORDER',
        ),
        isNull,
      );
    });

    test('customer openbill WAITING_ORDER still queues CONFIRM_OPENBILL', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'CREATE',
          openbillFlag: true,
          orderBy: 'CUSTOMER',
        ),
        'CONFIRM_OPENBILL',
      );
    });

    test('openbill UNPAID ready to pay queues PAY only when paid locally', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'PAY',
          openbillFlag: true,
          paidAmountLocal: 50000,
        ),
        isNull,
      );
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'CREATE',
          openbillFlag: true,
          paidAmountLocal: 50000,
        ),
        'PAY',
      );
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'PAY',
          openbillFlag: true,
        ),
        isNull,
      );
    });

    test('fresh UNPAID checkout does not queue follow-up intent', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'CREATE',
        ),
        isNull,
      );
    });
  });

  group('OrderSyncIntentChain — multi-pass chain', () {
    test('CONFIRM_OPENBILL on openbill WAITING_ORDER needs no PROCESS follow-up', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'PROCESS',
          appliedIntent: 'CONFIRM_OPENBILL',
          openbillFlag: true,
        ),
        isNull,
      );
    });

    test('CONFIRM_OPENBILL with dirty served details queues SERVE_ITEMS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'CONFIRM_OPENBILL',
          appliedIntent: 'CONFIRM_OPENBILL',
          openbillFlag: true,
          hasDirtyServedDetails: true,
        ),
        'SERVE_ITEMS',
      );
    });

    test('PAY on SERVED leads to PROCESS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'SERVED',
          storedIntent: 'FINISH',
          appliedIntent: 'PAY',
        ),
        'PROCESS',
      );
    });

    test('PROCESS on SERVED leads to FINISH', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'SERVED',
          storedIntent: 'FINISH',
          appliedIntent: 'PROCESS',
        ),
        'FINISH',
      );
    });

    test('PAY on PROCESSED leads to PROCESS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'PROCESSED',
          storedIntent: 'PROCESS',
          appliedIntent: 'PAY',
        ),
        'PROCESS',
      );
    });

    test('OFFLINE_CATCH_UP partial cash SERVED+PAID queues PROCESS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'SERVED',
          storedIntent: 'OFFLINE_CATCH_UP',
          appliedIntent: 'OFFLINE_CATCH_UP',
          serverStatusAfterApply: 'PAID',
        ),
        'PROCESS',
      );
    });

    test('OFFLINE_CATCH_UP partial cash SERVED+PROCESSED queues FINISH', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'SERVED',
          storedIntent: 'OFFLINE_CATCH_UP',
          appliedIntent: 'OFFLINE_CATCH_UP',
          serverStatusAfterApply: 'PROCESSED',
        ),
        'FINISH',
      );
    });

    test('OFFLINE_CATCH_UP partial cash PROCESSED+PAID queues PROCESS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'PROCESSED',
          storedIntent: 'OFFLINE_CATCH_UP',
          appliedIntent: 'OFFLINE_CATCH_UP',
          serverStatusAfterApply: 'PAID',
        ),
        'PROCESS',
      );
    });

    test('CREATE + local UNPAID + server WAITING + dirty served queues SERVE_ITEMS', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'CREATE',
          openbillFlag: true,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_WAITING_ORDER',
          hasDirtyServedDetails: true,
        ),
        'SERVE_ITEMS',
      );
    });

    test('CREATE + local SERVED + paidAmount + server WAITING queues SERVE_ITEMS not PAY', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'SERVED',
          storedIntent: 'CREATE',
          openbillFlag: true,
          paidAmountLocal: 50000,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_WAITING_ORDER',
          hasDirtyServedDetails: true,
        ),
        'SERVE_ITEMS',
      );
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'SERVED',
          storedIntent: 'CREATE',
          openbillFlag: true,
          paidAmountLocal: 50000,
          orderBy: 'CASHIER',
          serverStatusAfterCreate: 'OPENBILL_WAITING_ORDER',
          hasDirtyServedDetails: false,
        ),
        'SERVE_ITEMS',
      );
    });

    test('SERVE_ITEMS applied + paidAmount + server UNPAID queues PAY', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'SERVED',
          storedIntent: 'SERVE_ITEMS',
          appliedIntent: 'SERVE_ITEMS',
          openbillFlag: true,
          paidAmountLocal: 50000,
          serverStatusAfterApply: 'UNPAID',
        ),
        'PAY',
      );
    });
  });

  group('OfflineCatchUpPolicy', () {
    BookingOrder _order({
      required String clientUuid,
      required String status,
      bool syncDirty = true,
      String? syncIntent,
      bool openbillFlag = true,
      String? orderBy = 'CASHIER',
      int? serverId,
      double? paidAmountLocal,
    }) {
      return BookingOrder(
        clientUuid: clientUuid,
        customerName: 'guest',
        orderStatus: status,
        syncDirty: syncDirty,
        syncIntent: syncIntent,
        openbillFlag: openbillFlag,
        orderBy: orderBy,
        serverId: serverId,
        paidAmountLocal: paidAmountLocal,
        discountValue: 0,
        totalOrderValue: 0,
        isPpnActive: false,
        paymentFlag: false,
        syncVersion: 0,
        createdAt: DateTime(2026, 6, 30, 10),
        updatedAt: DateTime(2026, 6, 30, 10),
      );
    }

    test('simple openbill checkout still uses CREATE', () async {
      final order = _order(
        clientUuid: 'ob-1',
        status: 'OPENBILL_WAITING_ORDER',
        syncIntent: 'CREATE',
        serverId: null,
      );

      expect(
        await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
          order: order,
          hasDirtyServedDetails: (_) async => false,
        ),
        isFalse,
      );
    });

    test('openbill served offline uses OFFLINE_CATCH_UP', () async {
      final order = _order(
        clientUuid: 'ob-2',
        status: 'SERVED',
        syncIntent: 'PAY',
        serverId: 42,
        paidAmountLocal: 50000,
      );

      expect(
        await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
          order: order,
          hasDirtyServedDetails: (_) async => false,
        ),
        isTrue,
      );
    });

    test('cash SERVED with serverId uses FINISH step intent not catch-up', () async {
      final order = _order(
        clientUuid: 'cash-1',
        status: 'SERVED',
        syncIntent: 'FINISH',
        openbillFlag: false,
        serverId: 99,
        paidAmountLocal: 50000,
      );

      expect(
        await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
          order: order,
          hasDirtyServedDetails: (_) async => false,
        ),
        isFalse,
      );
    });

    test('cash PROCESSED with serverId uses PROCESS step intent not catch-up', () async {
      final order = _order(
        clientUuid: 'cash-2',
        status: 'PROCESSED',
        syncIntent: 'PROCESS',
        openbillFlag: false,
        serverId: 100,
      );

      expect(
        await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
          order: order,
          hasDirtyServedDetails: (_) async => false,
        ),
        isFalse,
      );
    });

    test('OFFLINE_CATCH_UP guard always allowed', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'SERVED',
          syncIntent: 'OFFLINE_CATCH_UP',
        ),
        isNull,
      );
    });

    test('resolvePushIntent preserves OFFLINE_CATCH_UP', () {
      expect(
        OrderStageSyncGuard.resolvePushIntent(
          storedIntent: 'OFFLINE_CATCH_UP',
          orderStatus: 'SERVED',
          serverId: 10,
        ),
        'OFFLINE_CATCH_UP',
      );
    });

    test('openbill waiting with mixed served lines keeps kitchen catch-up target', () {
      final order = _order(
        clientUuid: 'ob-served',
        status: 'OPENBILL_WAITING_ORDER',
      );
      final bundle = BookingOrderBundle(
        order: order,
        details: [
          OrderDetail(
            clientDetailUuid: 'detail-1',
            bookingOrderClientUuid: 'ob-served',
            partnerProductId: 1,
            quantity: 1,
            basePrice: 10000,
            optionsPrice: 0,
            syncVersion: 0,
            status: 'SERVED BY CASHIER',
            syncDirty: true,
            createdAt: DateTime(2026, 6, 30, 10),
            updatedAt: DateTime(2026, 6, 30, 10),
          ),
          OrderDetail(
            clientDetailUuid: 'detail-2',
            bookingOrderClientUuid: 'ob-served',
            partnerProductId: 2,
            quantity: 1,
            basePrice: 12000,
            optionsPrice: 0,
            syncVersion: 0,
            status: null,
            syncDirty: true,
            createdAt: DateTime(2026, 6, 30, 10),
            updatedAt: DateTime(2026, 6, 30, 10),
          ),
        ],
        optionsByDetailUuid: const {},
      );

      expect(
        OfflineCatchUpPolicy.resolveCatchUpTargetStatus(
          order: order,
          bundle: bundle,
        ),
        'OPENBILL_WAITING_ORDER',
      );
    });

    test('openbill waiting with all lines served targets UNPAID catch-up', () {
      final order = _order(
        clientUuid: 'ob-all-served',
        status: 'OPENBILL_WAITING_ORDER',
      );
      final bundle = BookingOrderBundle(
        order: order,
        details: [
          OrderDetail(
            clientDetailUuid: 'detail-1',
            bookingOrderClientUuid: 'ob-all-served',
            partnerProductId: 1,
            quantity: 1,
            basePrice: 10000,
            optionsPrice: 0,
            syncVersion: 0,
            status: 'SERVED BY CASHIER',
            syncDirty: true,
            createdAt: DateTime(2026, 6, 30, 10),
            updatedAt: DateTime(2026, 6, 30, 10),
          ),
        ],
        optionsByDetailUuid: const {},
      );

      expect(
        OfflineCatchUpPolicy.resolveCatchUpTargetStatus(
          order: order,
          bundle: bundle,
        ),
        'UNPAID',
      );
    });
  });

  group('OrderCatchUpSyncPolicy', () {
    test('openbill UNPAID synced with server UNPAID needs no catch-up', () {
      expect(
        OrderCatchUpSyncPolicy.needsCatchUp(
          localStatus: 'UNPAID',
          serverStatus: 'UNPAID',
          openbillFlag: true,
          hasDirtyServedDetails: false,
        ),
        isFalse,
      );
    });

    test('dirty served details still need catch-up', () {
      expect(
        OrderCatchUpSyncPolicy.needsCatchUp(
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
          openbillFlag: true,
          hasDirtyServedDetails: true,
        ),
        isTrue,
      );
    });

    test('openbill SERVED local ahead of server UNPAID needs catch-up', () {
      expect(
        OrderCatchUpSyncPolicy.needsCatchUp(
          localStatus: 'SERVED',
          serverStatus: 'UNPAID',
          openbillFlag: true,
          hasDirtyServedDetails: false,
          paidAmountLocal: 50000,
        ),
        isTrue,
      );
    });

    test('openbill SERVED local and server both SERVED needs no catch-up', () {
      expect(
        OrderCatchUpSyncPolicy.needsCatchUp(
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
          openbillFlag: true,
          hasDirtyServedDetails: false,
          paidAmountLocal: 50000,
        ),
        isFalse,
      );
    });

    test('openbill UNPAID with PAY intent still needs catch-up', () {
      expect(
        OrderCatchUpSyncPolicy.needsCatchUp(
          localStatus: 'UNPAID',
          serverStatus: 'UNPAID',
          openbillFlag: true,
          hasDirtyServedDetails: false,
          paidAmountLocal: 50000,
          syncIntent: 'PAY',
        ),
        isTrue,
      );
    });

    test('shouldClearSyncDirty when cash SERVED matches server SERVED', () {
      expect(
        OrderCatchUpSyncPolicy.shouldClearSyncDirty(
          syncDirty: true,
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
          openbillFlag: false,
          hasDirtyServedDetails: false,
          paidAmountLocal: 50000,
        ),
        isTrue,
      );
    });

    test('shouldClearSyncDirty false when cash SERVED but server still PAID', () {
      expect(
        OrderCatchUpSyncPolicy.shouldClearSyncDirty(
          syncDirty: true,
          localStatus: 'SERVED',
          serverStatus: 'PAID',
          openbillFlag: false,
          hasDirtyServedDetails: false,
          paidAmountLocal: 50000,
        ),
        isFalse,
      );
    });

    test('shouldClearSyncDirty false when not dirty', () {
      expect(
        OrderCatchUpSyncPolicy.shouldClearSyncDirty(
          syncDirty: false,
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
          openbillFlag: false,
          hasDirtyServedDetails: false,
        ),
        isFalse,
      );
    });

    test('shouldClearSyncDirty false when dirty served details remain', () {
      expect(
        OrderCatchUpSyncPolicy.shouldClearSyncDirty(
          syncDirty: true,
          localStatus: 'SERVED',
          serverStatus: 'SERVED',
          openbillFlag: true,
          hasDirtyServedDetails: true,
        ),
        isFalse,
      );
    });
  });

  group('OfflineCatchUpPolicy UPDATE exemption', () {
    test('UPDATE intent does not use offline catch-up on UNPAID openbill', () async {
      final order = BookingOrder(
        clientUuid: 'uuid-1',
        customerName: 'guest',
        orderStatus: 'UNPAID',
        openbillFlag: true,
        syncDirty: true,
        syncIntent: 'UPDATE',
        paidAmountLocal: 50000,
        discountValue: 0,
        totalOrderValue: 0,
        isPpnActive: false,
        paymentFlag: false,
        syncVersion: 0,
        createdAt: DateTime(2026, 6, 30, 10),
        updatedAt: DateTime(2026, 6, 30, 10),
      );

      final useCatchUp = await OfflineCatchUpPolicy.shouldUseOfflineCatchUp(
        order: order,
        hasDirtyServedDetails: (_) async => true,
      );

      expect(useCatchUp, isFalse);
    });
  });

  group('OrderEditConflictDetector', () {
    test('detects qty divergence on same detail id', () {
      final result = OrderEditConflictDetector.compare(
        localDetails: [
          {'id': 10, 'product_name': 'Nasi', 'quantity': 2},
        ],
        serverDetails: [
          {'id': 10, 'product_name': 'Nasi', 'quantity': 1},
        ],
      );

      expect(result.hasDivergence, isTrue);
      expect(result.editableDiffs, isNotEmpty);
    });

    test('detects new local line without server id', () {
      final result = OrderEditConflictDetector.compare(
        localDetails: [
          {'product_name': 'Teh', 'quantity': 1},
        ],
        serverDetails: const [],
      );

      expect(result.hasDivergence, isTrue);
      expect(result.editableDiffs.first, contains('Baris baru lokal'));
    });
  });

  group('resolveLastPaymentIdForPush', () {
    test('prefers latestPaymentServerId over paymentId', () {
      expect(
        resolveLastPaymentIdForPush(
          latestPaymentServerId: 99,
          paymentId: 12,
        ),
        99,
      );
    });

    test('falls back to paymentId when latest is null', () {
      expect(
        resolveLastPaymentIdForPush(
          latestPaymentServerId: null,
          paymentId: 12,
        ),
        12,
      );
    });

    test('returns null when both ids missing', () {
      expect(
        resolveLastPaymentIdForPush(
          latestPaymentServerId: null,
          paymentId: null,
        ),
        isNull,
      );
    });
  });

  group('compareOrdersOldestFirst', () {
    test('sorts by created_at ASC with stable tie-breaker', () {
      final a = {
        'created_at': '2026-01-01T10:00:00.000Z',
        'updated_at': '2026-01-02T12:00:00.000Z',
        'client_uuid': 'aaa',
      };
      final b = {
        'created_at': '2026-01-01T10:00:00.000Z',
        'updated_at': '2026-01-01T11:00:00.000Z',
        'client_uuid': 'bbb',
      };
      final c = {
        'created_at': '2026-01-01T09:00:00.000Z',
        'client_uuid': 'ccc',
      };

      expect(compareOrdersOldestFirst(a, b), lessThan(0));
      expect(compareOrdersOldestFirst(b, a), greaterThan(0));
      expect(compareOrdersOldestFirst(c, a), lessThan(0));

      final items = [b, c, a]..sort(compareOrdersOldestFirst);
      expect(items.map((e) => e['client_uuid']).toList(), ['ccc', 'aaa', 'bbb']);
    });
  });
}
