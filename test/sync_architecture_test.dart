import 'package:cavaa_cashier/features/cashier/data/sync/order_stage_rank.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_stage_sync_guard.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/order_sync_intent_chain.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/sync_api.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/sync_engine.dart';
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

    test('openbill OPENBILL_CONFIRMATION is ahead of server UNPAID', () {
      expect(
        OrderStageRank.isLocalAheadOfServer(
          localStatus: 'OPENBILL_CONFIRMATION',
          serverStatus: 'UNPAID',
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
        isTrue,
      );
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

    test('openbill UNPAID ready to pay queues PAY only when flagged', () {
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'PAY',
          openbillFlag: true,
        ),
        'PAY',
      );
      expect(
        OrderSyncIntentChain.firstIntentAfterCreate(
          localStatus: 'UNPAID',
          storedIntent: 'CREATE',
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
    test('CONFIRM_OPENBILL leads to PROCESS', () {
      expect(
        OrderSyncIntentChain.resolveNext(
          localStatus: 'OPENBILL_WAITING_ORDER',
          storedIntent: 'PROCESS',
          appliedIntent: 'CONFIRM_OPENBILL',
          openbillFlag: true,
        ),
        'PROCESS',
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
  });
}
