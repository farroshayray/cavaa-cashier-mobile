import 'package:cavaa_cashier/features/cashier/data/sync/payment_submit_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isPaymentCompletedOnServer', () {
    test('UNPAID with PENDING payment is not completed', () {
      expect(
        isPaymentCompletedOnServer({
          'order_status': 'UNPAID',
          'payment_flag': false,
          'latest_payment': {'payment_status': 'PENDING'},
        }),
        isFalse,
      );
    });

    test('PAID with payment_flag is completed', () {
      expect(
        isPaymentCompletedOnServer({
          'order_status': 'PAID',
          'payment_flag': true,
        }),
        isTrue,
      );
    });

    test('openbill SERVED after payment is completed', () {
      expect(
        isPaymentCompletedOnServer({
          'order_status': 'SERVED',
          'openbill_flag': true,
          'payment_flag': true,
        }),
        isTrue,
      );
    });

    test('SERVED with latest_payment PAID is completed', () {
      expect(
        isPaymentCompletedOnServer({
          'order_status': 'SERVED',
          'latest_payment': {'payment_status': 'PAID'},
        }),
        isTrue,
      );
    });
  });

  group('recoverPaymentAfterSubmitFailure', () {
    test('returns success when server detail shows PAID', () async {
      final result = await recoverPaymentAfterSubmitFailure(
        serverId: 42,
        fetchOrderDetail: (_) async => {
          'id': 42,
          'order_status': 'PAID',
          'payment_flag': true,
        },
      );

      expect(result.succeeded, isTrue);
      expect(result.orderDetail?['order_status'], 'PAID');
    });

    test('returns failure when server still UNPAID', () async {
      final result = await recoverPaymentAfterSubmitFailure(
        serverId: 7,
        fetchOrderDetail: (_) async => {
          'order_status': 'UNPAID',
          'latest_payment': {'payment_status': 'PENDING'},
        },
      );

      expect(result.succeeded, isFalse);
      expect(result.ambiguous, isFalse);
      expect(result.message, isNotEmpty);
    });

    test('returns ambiguous when fetch fails', () async {
      final result = await recoverPaymentAfterSubmitFailure(
        serverId: 1,
        fetchOrderDetail: (_) async => throw Exception('network'),
      );

      expect(result.succeeded, isFalse);
      expect(result.ambiguous, isTrue);
    });
  });
}
