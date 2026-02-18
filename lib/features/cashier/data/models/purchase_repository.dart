import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/purchase_api.dart';

class PurchaseRepository {
  final PurchaseApi api;

  PurchaseRepository({required this.api});

  Future<PurchasePayload> fetchPurchaseData() async {
    final json = await api.getProducts();
    return PurchasePayload.fromJson(json);
  }
}
