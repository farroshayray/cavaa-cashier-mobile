import 'package:cavaa_cashier/features/cashier/data/sync/sync_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idempotency key is stable for same client payload', () {
    final keyA = SyncApi.buildIdempotencyKey(
      clientUuid: 'abc-123',
      syncIntent: 'CREATE',
      clientTimestamp: '2026-06-29T10:00:00Z',
    );
    final keyB = SyncApi.buildIdempotencyKey(
      clientUuid: 'abc-123',
      syncIntent: 'CREATE',
      clientTimestamp: '2026-06-29T10:00:00Z',
    );

    expect(keyA, keyB);
    expect(keyA.length, 64);
  });
}
