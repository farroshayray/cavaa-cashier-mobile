import 'package:flutter_test/flutter_test.dart';

import 'package:cavaa_cashier/features/cashier/data/sync/order_detail_prefetch_policy.dart';

void main() {
  group('OrderDetailPrefetchPolicy', () {
    test('skips synced orders that already have line items', () {
      expect(
        OrderDetailPrefetchPolicy.shouldPrefetch({
          'id': 10,
          'sync_dirty': false,
          'order_details': [
            {'id': 1, 'status': 'PROCESSED'},
          ],
        }),
        isFalse,
      );
    });

    test('prefetches when mirror has no details', () {
      expect(
        OrderDetailPrefetchPolicy.shouldPrefetch({
          'id': 11,
          'sync_dirty': false,
          'order_details': [],
        }),
        isTrue,
      );
    });

    test('prefetches dirty orders even with details', () {
      expect(
        OrderDetailPrefetchPolicy.shouldPrefetch({
          'id': 12,
          'sync_dirty': true,
          'order_details': [
            {'id': 1, 'status': 'PROCESSED'},
          ],
        }),
        isTrue,
      );
    });

    test('selectForPrefetch caps batch size', () {
      final rows = List.generate(
        10,
        (i) => {
          'id': i + 1,
          'sync_dirty': false,
          'order_details': <Map<String, dynamic>>[],
        },
      );

      final selected = OrderDetailPrefetchPolicy.selectForPrefetch(rows);

      expect(selected.length, OrderDetailPrefetchPolicy.maxPerLoad);
    });
  });
}
