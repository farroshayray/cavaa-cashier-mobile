import 'dart:convert';

import 'package:cavaa_cashier/features/cashier/presentation/printing/offline_print_enricher.dart';
import 'package:cavaa_cashier/features/cashier/presentation/printing/receipt_order_enricher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enrichReceiptOrder', () {
    test('hydrates wifi fields from wifi_snapshot', () {
      final enriched = enrichReceiptOrder({
        'wifi_snapshot': {
          'wifi_shown': 1,
          'wifi_ssid': 'CavaaGuest',
          'wifi_password': 'secret123',
          'store_address': 'Jl. Contoh 1',
        },
      });

      expect(enriched['store_is_wifi_shown'], 1);
      expect(enriched['store_wifi_user'], 'CavaaGuest');
      expect(enriched['store_wifi_password'], 'secret123');
      expect(enriched['store_address'], 'Jl. Contoh 1');
    });

    test('decodes wifi_snapshot_json string', () {
      final enriched = enrichReceiptOrder({
        'wifi_snapshot_json': jsonEncode({
          'wifi_shown': true,
          'wifi_ssid': 'OfflineNet',
          'wifi_password': 'pass',
        }),
      });

      expect(enriched['wifi_snapshot'], isA<Map>());
      expect(enriched['store_wifi_user'], 'OfflineNet');
      expect(enriched['store_wifi_password'], 'pass');
      expect(receiptWifiShown(enriched), isTrue);
    });

    test('infers wifi shown when credentials exist but wifi_shown missing', () {
      final enriched = enrichReceiptOrder({
        'wifi_snapshot': {
          'wifi_ssid': 'CafeGuest',
          'wifi_password': 'guest123',
        },
      });

      expect(enriched['store_wifi_user'], 'CafeGuest');
      expect(enriched['store_wifi_password'], 'guest123');
      expect(receiptWifiShown(enriched), isTrue);
    });
  });

  group('enrichOfflinePrintOrder', () {
    test('merges partner name and decodes checkout wifi snapshot', () {
      final wifiJson = jsonEncode({
        'wifi_shown': 1,
        'wifi_ssid': 'StoreWiFi',
        'wifi_password': 'abc',
        'store_address': 'Alamat Toko',
      });

      final enriched = enrichOfflinePrintOrder({
        'partner_name': 'Warung Cavaa',
        'is_ppn_active': 1,
        'ppn': 11,
        'wifiSnapshotJson': wifiJson,
      });

      expect(enriched['store_name'], 'Warung Cavaa');
      expect(enriched['store_address'], 'Alamat Toko');
      expect(enriched['store_wifi_user'], 'StoreWiFi');
      expect(enriched['store_wifi_password'], 'abc');
      expect(receiptWifiShown(enriched), isTrue);
    });
  });
}
