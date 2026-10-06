import 'package:cavaa_cashier/features/cashier/presentation/printing/receipt_format_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('receiptOptionName', () {
    test('reads nested option.name', () {
      expect(
        receiptOptionName({
          'option': {'name': 'Extra Pedas'},
        }),
        'Extra Pedas',
      );
    });

    test('reads flat partner_product_option_name from mirror', () {
      expect(
        receiptOptionName({
          'partner_product_option_name': 'Level 2',
        }),
        'Level 2',
      );
    });

    test('returns dash when no option label', () {
      expect(receiptOptionName({}), '-');
    });
  });

  group('receiptOptionParentName', () {
    test('reads nested option.parent.name', () {
      expect(
        receiptOptionParentName({
          'option': {
            'parent': {'name': 'Level Pedas'},
          },
        }),
        'Level Pedas',
      );
    });

    test('reads flat parent_name from mirror', () {
      expect(
        receiptOptionParentName({
          'parent_name': 'Topping',
        }),
        'Topping',
      );
    });

    test('returns empty when parent missing', () {
      expect(receiptOptionParentName({}), '');
    });
  });
}
