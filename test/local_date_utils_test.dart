import 'package:flutter_test/flutter_test.dart';

import 'package:cavaa_cashier/features/cashier/data/local/db/local_date_utils.dart';

void main() {
  test('isSameLocalDay compares calendar day in local timezone', () {
    final utcLate = DateTime.utc(2026, 3, 16, 20, 0);
    final localEarly = DateTime(2026, 3, 17, 4, 0);

    expect(isSameLocalDay(utcLate, localEarly), isTrue);
    expect(
      isSameLocalDay(
        DateTime.utc(2026, 3, 15, 20, 0),
        localEarly,
      ),
      isFalse,
    );
  });
}
