import 'dart:convert';
import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class CachedPaymentMethodsDao {
  final CashierDb db;
  CachedPaymentMethodsDao(this.db);

  Future<CachedPaymentMethod?> getByKind(String kind) async {
    final rows = await (db.select(db.cachedPaymentMethods)
          ..where((t) => t.kind.equals(kind))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.cachedAt)])
          ..limit(1))
        .get();

    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> buildManualPaymentMap({
    int? serverManualPaymentId,
    String? paymentMethod,
  }) async {
    CachedPaymentMethod? row;

    if (serverManualPaymentId != null) {
      row = await getByServerManualPaymentId(serverManualPaymentId);
    }

    row ??= paymentMethod == null ? null : await getByKind(paymentMethod);

    if (row == null) return null;

    return <String, dynamic>{
      'payment_type': row.kind,
      'provider_name': row.providerName,
      'provider_account_name': row.providerAccountName,
      'provider_account_no': row.providerAccountNo,
      'qris_image_url': row.qrisImageUrl,
      'qris_image_local_path': row.qrisImageLocalPath,
      'server_manual_payment_id': row.serverManualPaymentId,
    };
  }

  Future<void> upsertManualPaymentMethod({
    required String localKey,
    required String kind,
    String? label,
    String? providerName,
    String? providerAccountName,
    String? providerAccountNo,
    String? qrisImageUrl,
    String? qrisImageLocalPath,
    int? serverManualPaymentId,
    Map<String, dynamic>? raw,
  }) async {
    await db.transaction(() async {
      await (db.delete(db.cachedPaymentMethods)
            ..where((t) => t.localKey.equals(localKey)))
          .go();

      if (serverManualPaymentId != null) {
        await (db.delete(db.cachedPaymentMethods)
              ..where((t) => t.serverManualPaymentId.equals(serverManualPaymentId)))
            .go();
      }

      await db.into(db.cachedPaymentMethods).insert(
        CachedPaymentMethodsCompanion.insert(
          localKey: localKey,
          kind: kind,
          serverManualPaymentId: Value(serverManualPaymentId),
          label: label ?? kind,
          providerName: Value(providerName),
          providerAccountName: Value(providerAccountName),
          providerAccountNo: Value(providerAccountNo),
          qrisImageUrl: Value(qrisImageUrl),
          qrisImageLocalPath: Value(qrisImageLocalPath),
          isActive: const Value(true),
          rawJson: jsonEncode(raw ?? {}),
          cachedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<CachedPaymentMethod?> getByServerManualPaymentId(int id) async {
    final rows = await (db.select(db.cachedPaymentMethods)
          ..where((t) => t.serverManualPaymentId.equals(id))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.cachedAt)])
          ..limit(1))
        .get();

    return rows.isEmpty ? null : rows.first;
  }

  Future<List<CachedPaymentMethod>> getAllActive() async {
    return (db.select(db.cachedPaymentMethods)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .get();
  }

  Future<List<Map<String, dynamic>>> buildAvailablePaymentMethodsList() async {
    final rows = await getAllActive();
    final methods = <Map<String, dynamic>>[];

    for (final row in rows) {
      if (row.kind == 'cashierCash') {
        methods.add({
          'value': 'CASH',
          'label': row.label,
          'type': 'CASH',
          'requires_proof': false,
        });
        continue;
      }

      if (row.kind == 'onlineQris') {
        methods.add({
          'value': 'QRIS',
          'label': row.label,
          'type': 'QRIS',
          'requires_proof': false,
        });
        continue;
      }

      if (row.kind == 'openbill') {
        continue;
      }

      final manualId = row.serverManualPaymentId;
      if (manualId == null) continue;

      methods.add({
        'value': manualId.toString(),
        'label': row.label,
        'type': row.kind,
        'requires_proof': true,
        'provider_name': row.providerName,
        'provider_account_name': row.providerAccountName,
        'provider_account_no': row.providerAccountNo,
        'qris_image_url': row.qrisImageUrl,
        'qris_image_local_path': row.qrisImageLocalPath,
      });
    }

    return methods;
  }
}