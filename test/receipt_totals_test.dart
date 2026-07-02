import 'package:flutter_test/flutter_test.dart';

import 'package:cavaa_cashier/features/cashier/presentation/printing/receipt_order_enricher.dart';
import 'package:cavaa_cashier/features/cashier/presentation/printing/receipt_totals.dart';

void main() {
  group('buildReceiptTotals', () {
    test('calculates PPN and grand total', () {
      final totals = buildReceiptTotals({
        'total_order_value': 10000,
        'is_ppn_active': 1,
        'ppn': 11,
        'payment': {
          'paid_amount': 12000,
          'change_amount': 1000,
          'rounding_amount': 0,
        },
      });

      expect(totals.subtotal, 10000);
      expect(totals.isPpnActive, isTrue);
      expect(totals.ppnAmount, 1100);
      expect(totals.grandTotal, 11100);
      expect(totals.paid, 12000);
      expect(totals.change, 1000);
    });

    test('includes cash rounding amount', () {
      final totals = buildReceiptTotals({
        'total_order_value': 10000,
        'is_ppn_active': false,
        'cash_rounding_amount': 75,
        'latest_payment': {
          'paid_amount': 10075,
          'change_amount': 0,
        },
      });

      expect(totals.grandTotal, 10075);
      expect(totals.roundingAmount, 75);
    });

    test('uses local paid/change fallback when nested payment is missing', () {
      final totals = buildReceiptTotals({
        'total_order_value': 10000,
        'is_ppn_active': false,
        'paid_amount_local': 20000,
        'change_amount_local': 10000,
      });

      expect(totals.grandTotal, 10000);
      expect(totals.paid, 20000);
      expect(totals.change, 10000);
    });
  });

  group('enrichReceiptOrder', () {
    test('maps wifi_snapshot when store fields missing', () {
      final enriched = enrichReceiptOrder({
        'wifi_snapshot': {
          'wifi_shown': 1,
          'wifi_ssid': 'farrocoffee',
          'wifi_password': 'secret',
        },
      });

      expect(receiptWifiShown(enriched), isTrue);
      expect(enriched['store_wifi_user'], 'farrocoffee');
      expect(enriched['store_wifi_password'], 'secret');
    });
  });
}
