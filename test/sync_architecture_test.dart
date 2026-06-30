import 'package:cavaa_cashier/features/cashier/data/sync/order_stage_sync_guard.dart';
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

    test('PAY rejected after PAID', () {
      expect(
        OrderStageSyncGuard.validateIntent(
          currentStatus: 'PAID',
          syncIntent: 'PAY',
        ),
        isNotNull,
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
}
