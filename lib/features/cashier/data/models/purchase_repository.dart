import '/core/storage/secure_storage_service.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/models/purchase_repository.dart';
import '/features/cashier/data/purchase_api.dart';

class PurchaseRepository {
  final PurchaseApi api;
  final SecureStorageService storage;

  PurchaseRepository({required this.api, required this.storage});

  Future<PurchasePayload> fetchPurchaseData() async {
    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong. Silakan login ulang.');
    }

    final json = await api.getProducts(token: token);
    return PurchasePayload.fromJson(json);
  }
}
