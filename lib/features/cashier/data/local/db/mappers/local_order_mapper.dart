import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class LocalOrderMapper {
  static LocalOrdersCompanion toLocalOrder({
    required String localId,
    required String clientOrderCode,
    required String customerName,
    required int? partnerId,
    required String? partnerName,
    required int? tableServerId,
    required String? tableNoSnapshot,
    required String paymentMethodSelected,
    required String paymentMethodEffective,
    required double subtotal,
    required double discountValue,
    required double ppnPercent,
    required bool isPpnActive,
    required double grandTotal,
    String orderStatusLocal = 'UNPAID',
    String syncStatus = 'PENDING',
  }) {
    final now = DateTime.now();

    return LocalOrdersCompanion.insert(
      localId: localId,
      clientOrderCode: clientOrderCode,
      customerName: customerName,
      createdAtLocal: now,
      updatedAtLocal: now,

      partnerId: Value(partnerId),
      partnerName: Value(partnerName),
      tableServerId: Value(tableServerId),
      tableNoSnapshot: Value(tableNoSnapshot),

      paymentMethodSelected: Value(paymentMethodSelected),
      paymentMethodEffective: Value(paymentMethodEffective),

      subtotal: Value(subtotal),
      discountValue: Value(discountValue),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      grandTotal: Value(grandTotal),

      orderStatusLocal: Value(orderStatusLocal),
      syncStatus: Value(syncStatus),
    );
  }

  static LocalOrderItemsCompanion toLocalItem({
    required String localId,
    required String orderLocalId,
    required int productServerId,
    required String productNameSnapshot,
    required double basePrice,
    required int qty,
    required String? customerNote,
    required double optionsPrice,
    required double lineTotal,
    int? promoId,
    String? promoType,
    double? promoAmount,
  }) {
    return LocalOrderItemsCompanion.insert(
      localId: localId,
      orderLocalId: orderLocalId,
      productServerId: productServerId,
      productNameSnapshot: productNameSnapshot,
      basePrice: Value(basePrice),
      qty: qty,
      createdAtLocal: DateTime.now(),

      customerNote: Value(customerNote),
      optionsPrice: Value(optionsPrice),
      lineTotal: Value(lineTotal),

      promoId: Value(promoId),
      promoType: Value(promoType),
      promoAmount: Value(promoAmount),
    );
  }

  static LocalOrderItemOptionsCompanion toLocalOption({
    required String localId,
    required String orderItemLocalId,
    required int optionServerId,
    required String optionNameSnapshot,
    required double price,
    String? parentNameSnapshot,
  }) {
    return LocalOrderItemOptionsCompanion.insert(
      localId: localId,
      orderItemLocalId: orderItemLocalId,
      optionServerId: optionServerId,
      optionNameSnapshot: optionNameSnapshot,
      price: Value(price),
      createdAtLocal: DateTime.now(),
      parentNameSnapshot: Value(parentNameSnapshot),
    );
  }
}