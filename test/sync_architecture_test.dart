import 'package:cavaa_cashier/features/cashier/data/local/db/cashier_db.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/offline_catch_up_policy.dart';
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
    test('cash PROCESSED queues PAY', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'PROCESSED',
          storedIntent: 'PROCESS',
        ),
        'PAY',
      );
    });

    test('cash SERVED queues PAY', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'SERVED',
          storedIntent: 'FINISH',
        ),
        'PAY',
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
