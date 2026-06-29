import '/features/cashier/data/local/db/cashier_db.dart';

class OrderMirrorMapper {
  static Map<String, dynamic> orderToUiMap(BookingOrder row) {
    return {
      'id': row.serverId,
      'local_client_uuid': row.clientUuid,
      'booking_order_code': row.bookingOrderCode,
      'partner_id': row.partnerId,
      'partner_name': row.partnerName,
      'table_id': row.tableId,
      'table_no': row.tableNo,
      'customer_id': row.customerId,
      'employee_order_id': row.employeeOrderId,
      'order_by': row.orderBy,
      'customer_name': row.customerName,
      'order_status': row.orderStatus,
      'payment_method': row.paymentMethod,
      'openbill_flag': row.openbillFlag,
      'discount_id': row.discountId,
      'discount_value': row.discountValue,
      'total_order_value': row.totalOrderValue,
      'ppn': row.ppn,
      'is_ppn_active': row.isPpnActive,
      'customer_order_note': row.customerOrderNote,
      'employee_order_note': row.employeeOrderNote,
      'cashier_process_id': row.cashierProcessId,
      'kitchen_process_id': row.kitchenProcessId,
      'payment_id': row.paymentId,
      'payment_flag': row.paymentFlag,
      'sync_version': row.syncVersion,
      'sync_dirty': row.syncDirty,
      'paid_amount_local': row.paidAmountLocal,
      'change_amount_local': row.changeAmountLocal,
      'cash_rounding_amount': row.cashRoundingAmount,
      'cash_rounding_unit': row.cashRoundingUnit,
      'created_at': row.createdAt?.toIso8601String(),
      'updated_at': row.updatedAt?.toIso8601String(),
      'is_local_only': row.serverId == null,
    };
  }

  static Map<String, dynamic> detailToUiMap(OrderDetail row) {
    return {
      'id': row.serverId,
      'local_detail_uuid': row.clientDetailUuid,
      'booking_order_id': row.bookingOrderServerId,
      'product_code': row.productCode,
      'product_name': row.productName,
      'partner_product_id': row.partnerProductId,
      'quantity': row.quantity,
      'base_price': row.basePrice,
      'cogs': row.cogs,
      'options_price': row.optionsPrice,
      'customer_note': row.customerNote,
      'promo_id': row.promoId,
      'promo_amount': row.promoAmount,
      'promo_type': row.promoType,
      'status': row.status,
      'cashier_process_id': row.cashierProcessId,
      'kitchen_process_id': row.kitchenProcessId,
      'sync_version': row.syncVersion,
    };
  }

  static Map<String, dynamic> optionToUiMap(OrderDetailOption row) {
    return {
      'id': row.serverId,
      'option_id': row.optionId,
      'parent_name': row.parentName,
      'partner_product_option_name': row.partnerProductOptionName,
      'price': row.price,
    };
  }
}
