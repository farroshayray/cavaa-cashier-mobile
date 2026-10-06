import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '/core/config/env.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';
import '/features/cashier/data/models/purchase_models.dart';

/// Downloads manual payment QRIS images for offline display.
class ManualPaymentImageCache {
  ManualPaymentImageCache._();

  static Future<String?> downloadToLocal(String rawPath) async {
    try {
      if (rawPath.trim().isEmpty) return null;

      final imageUrl = rawPath.startsWith('http')
          ? rawPath
          : '${Env.baseUrl}/storage/${rawPath.replaceFirst(RegExp(r'^\/?storage\/?'), '')}';

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'manual_payment_images'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final ext = p.extension(Uri.parse(imageUrl).path);
      final safeExt = ext.isEmpty ? '.jpg' : ext;
      final fileName =
          '${rawPath.hashCode.abs()}$safeExt';
      final filePath = p.join(folder.path, fileName);

      final existing = File(filePath);
      if (await existing.exists()) {
        return filePath;
      }

      final dio = Dio();
      await dio.download(imageUrl, filePath);

      if (await existing.exists()) {
        return filePath;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> prefetchPaymentOptions({
    required CashierDb db,
    required List<PaymentOption> options,
  }) async {
    final dao = CachedPaymentMethodsDao(db);

    for (final option in options) {
      if (option.kind != PayKind.manual) continue;
      final imageUrl = option.qrisImageUrl?.trim();
      if (imageUrl == null || imageUrl.isEmpty) continue;

      final localPath = await downloadToLocal(imageUrl);
      if (localPath == null) continue;

      await dao.updateQrisLocalPath(
        serverManualPaymentId: option.manualId,
        kind: option.manualType ?? option.value,
        qrisImageLocalPath: localPath,
      );
    }
  }

  static Future<void> prefetchMissingFromCache(CashierDb db) async {
    final dao = CachedPaymentMethodsDao(db);
    final rows = await dao.getAllActive();

    for (final row in rows) {
      final imageUrl = row.qrisImageUrl?.trim();
      final localPath = row.qrisImageLocalPath?.trim();
      if (imageUrl == null || imageUrl.isEmpty) continue;
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) continue;
      }

      final downloaded = await downloadToLocal(imageUrl);
      if (downloaded == null) continue;

      await dao.updateQrisLocalPath(
        serverManualPaymentId: row.serverManualPaymentId,
        kind: row.kind,
        qrisImageLocalPath: downloaded,
      );
    }
  }
}
