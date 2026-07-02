import 'dart:convert';

import 'package:cavaa_cashier/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderMirrorMapper.hydrateReceiptPayload', () {
    test('hydrates latest_payment from json and keeps payment fallback fields', () {
      final updatedAt = DateTime(2026, 7, 2, 10, 0, 0).toIso8601String();
      final source = <String, dynamic>{
        'paid_amount_local': 50000,
        'change_amount_local': 2500,
        'cash_rounding_amount': 100,
        'updated_at': updatedAt,
      };

      final latestPaymentJson = jsonEncode({
        'paid_amount': 50000,
        'change_amount': 2500,
        'updated_at': updatedAt,
      });

      final hydrated = OrderMirrorMapper.hydrateReceiptPayload(
        source,
        latestPaymentJson: latestPaymentJson,
      );

      expect(hydrated['latest_payment'], isA<Map<String, dynamic>>());
      expect(hydrated['payment'], isA<Map<String, dynamic>>());
      expect(hydrated['payment']['paid_amount'], 50000);
      expect(hydrated['payment']['change_amount'], 2500);
      expect(hydrated['payment']['rounding_amount'], 100);
      expect(hydrated['payment']['updated_at'], updatedAt);
    });

    test('fills employee_name from order_by when missing', () {
      final hydrated = OrderMirrorMapper.hydrateReceiptPayload({
        'order_by': 'Kasir Shift Pagi',
      });

      expect(hydrated['employee_name'], 'Kasir Shift Pagi');
    });
  });
}
