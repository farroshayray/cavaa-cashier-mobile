import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/purchase_api.dart';
import '/features/cashier/data/sync/sync_api.dart';
import '/features/cashier/data/sync/master_cache_service.dart';

import 'package:flutter/foundation.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class PurchaseRepository {
  final PurchaseApi api;
  final CashierDb db;
  final SyncApi? syncApi;

  PurchaseRepository({
    required this.api,
    required this.db,
    this.syncApi,
  });

  MasterCacheService get _masterCache => MasterCacheService(db);

  Future<PurchasePayload?> loadFromLocalCache() async {
    return _masterCache.loadFromLocalCache();
  }

  Future<PurchasePayload> fetchPurchaseData({bool preferCache = false}) async {
    if (preferCache) {
      final cached = await _masterCache.loadFromLocalCache();
      if (cached != null) {
        return cached;
      }
    }

    if (syncApi != null) {
      try {
        final response = await syncApi!.sync(
          payload: {
            'pull_scopes': ['master'],
            'push': <String, dynamic>{},
          },
          idempotencyKey: SyncApi.buildIdempotencyKey(
            clientUuid: 'master-bootstrap',
            syncIntent: 'PULL_MASTER',
            clientTimestamp: DateTime.now().toIso8601String(),
          ),
        );
        final master = response['pulled']?['master'];
        if (master is Map) {
          return _saveMasterJson(Map<String, dynamic>.from(master));
        }
      } catch (e) {
        debugPrint('fetchPurchaseData via /sync master failed: $e');
      }
    }

    try {
      final json = await api.getProducts();
      return _saveMasterJson(json);
    } catch (e) {
      debugPrint('fetchPurchaseData online failed: $e');

      final cached = await _masterCache.loadFromLocalCache();
      if (cached != null) {
        debugPrint('fallback master from local DB cache');
        return cached;
      }

      rethrow;
    }
  }

  Future<PurchasePayload> _saveMasterJson(Map<String, dynamic> json) async {
    return _masterCache.saveAndBuildPayload(json);
  }
}
