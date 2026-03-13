import 'dart:convert';
import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class CachedPaymentMethodsDao {
  final CashierDb db;
  CachedPaymentMethodsDao(this.db);

  Future<CachedPaymentMethod?> getByKind(String kind) {
    return (db.select(db.cachedPaymentMethods)
          ..where((t) => t.kind.equals(kind))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.cachedAt)]))
        .getSingleOrNull();
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

  Future<CachedPaymentMethod?> getByServerManualPaymentId(int id) {
    return (db.select(db.cachedPaymentMethods)
          ..where((t) => t.serverManualPaymentId.equals(id))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.cachedAt)]))
        .getSingleOrNull();
  }
}