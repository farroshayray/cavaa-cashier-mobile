import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/models/checkout_exceptions.dart';
import '/features/cashier/data/models/orders_repository.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

class EditableCartItem {
  final int? detailId;
  final bool isLocked;
  final String? lockStatusLabel;
  final String? detailStatusSnapshot;
  final int? kitchenProcessIdSnapshot;
  final int minQty;
  CartItem cart;

  EditableCartItem({
    this.detailId,
    required this.cart,
    this.isLocked = false,
    this.lockStatusLabel,
    this.detailStatusSnapshot,
    this.kitchenProcessIdSnapshot,
    this.minQty = 1,
  });

  Product get product => cart.product;
  int get qty => cart.qty;
  set qty(int value) => cart.qty = value;
  Map<int, Set<int>> get selected => cart.selected;
  String get note => cart.note;
  set note(String value) => cart.note = value;
  num get unitFinalPrice => cart.unitFinalPrice;
  num get lineTotal => cart.lineTotal;
}

class EditOrderProvider extends ChangeNotifier {
  EditOrderProvider({
    required this.ordersRepo,
    required this.bookingOrdersDao,
    required this.tabCoordinator,
  });

  final OrdersRepository ordersRepo;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;
  final Uuid _uuid = const Uuid();

  bool isLoading = false;
  bool isSaving = false;
  String? error;

  String? localId;
  int? serverId;
  String customerName = '';
  int? tableServerId;
  String? tableNoSnapshot;
  String orderStatus = 'UNPAID';
  bool isPpnActive = false;
  num ppnPercent = 0;
  String? paymentMethodEffective;
  bool openbillFlag = false;

  final List<EditableCartItem> items = [];

  bool get isOpenbillOrder =>
      openbillFlag ||
      paymentMethodEffective == 'OPENBILL' ||
      orderStatus.startsWith('OPENBILL');

  bool get allItemsServed {
    if (items.isEmpty) return false;
    return items.every(
      (item) => isDetailServedStatus(item.detailStatusSnapshot ?? ''),
    );
  }

  num get subtotal => items.fold<num>(0, (sum, item) => sum + item.lineTotal);

  num get grandTotalWithPpn {
    if (!isPpnActive) return subtotal.ceil();
    return (subtotal + (subtotal * ppnPercent / 100)).ceil();
  }

  bool get hasItems => items.isNotEmpty;

  List<CartItem> get stockOverlayLines =>
      items.map((item) => item.cart).toList(growable: false);

  void reset() {
    isLoading = false;
    isSaving = false;
    error = null;
    localId = null;
    serverId = null;
    customerName = '';
    tableServerId = null;
    tableNoSnapshot = null;
    orderStatus = 'UNPAID';
    isPpnActive = false;
    ppnPercent = 0;
    paymentMethodEffective = null;
    openbillFlag = false;
    items.clear();
  }

  Future<void> loadFromOrder({
    required Map<String, dynamic> order,
    required List<Product> catalog,
  }) async {
    isLoading = true;
    error = null;
    items.clear();
    notifyListeners();

    try {
      localId = (order['local_id'] ?? order['local_client_uuid'] ?? '')
          .toString()
          .trim();
      if (localId != null && localId!.isEmpty) localId = null;

      serverId = _toInt(order['server_id']) ?? _toInt(order['id']);
      if (serverId != null && serverId! <= 0) serverId = null;

      customerName = (order['customer_name'] ?? '').toString();
      orderStatus = (order['order_status'] ?? 'UNPAID').toString();
      isPpnActive = parseBool(order['is_ppn_active']);
      ppnPercent = parseNum(order['ppn']);
      paymentMethodEffective = order['payment_method']?.toString();
      openbillFlag = parseBool(order['openbill_flag']);

      final table = order['table'];
      if (table is Map) {
        tableNoSnapshot = table['table_no']?.toString();
        tableServerId = _toInt(table['id']);
      }
      tableServerId ??= _toInt(order['table_id']);

      final details = (order['order_details'] as List?) ?? [];
      for (final raw in details.whereType<Map>()) {
        final detail = Map<String, dynamic>.from(raw);
        final productId = orderProductId(detail);
        final locked = isOrderDetailLocked(detail);
        final detailId = orderDetailId(detail);
        final lockLabel = locked ? _lockStatusLabel(detail) : null;

        Product? product;
        for (final candidate in catalog) {
          if (candidate.id == productId) {
            product = candidate;
            break;
          }
        }
        product ??= _productFromDetailSnapshot(detail, productId);

        final selected = _selectedFromDetail(product, detail);
        final unitPrice = _unitPrice(product, selected);
        final qty = parseInt(detail['quantity'] ?? detail['qty'], defaultValue: 1);

        items.add(
          EditableCartItem(
            detailId: detailId,
            isLocked: locked,
            lockStatusLabel: lockLabel,
            detailStatusSnapshot: detailStatusOf(detail),
            kitchenProcessIdSnapshot:
                locked ? detailKitchenProcessId(detail) : null,
            minQty: locked ? qty : 1,
            cart: CartItem(
              product: product,
              qty: qty,
              selected: selected,
              note: (detail['customer_note'] ?? '').toString(),
              unitFinalPrice: unitPrice,
            ),
          ),
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void addWithOptions({
    required Product product,
    required int qty,
    required Map<int, Set<int>> selected,
    required String note,
    required num unitFinalPrice,
  }) {
    final selectedCopy = <int, Set<int>>{
      for (final entry in selected.entries) entry.key: {...entry.value},
    };

    final same = items.indexWhere(
      (item) =>
          !item.isLocked &&
          item.product.id == product.id &&
          _sameSelected(item.selected, selectedCopy) &&
          item.note == note,
    );

    if (same >= 0) {
      items[same].qty += qty;
    } else {
      items.add(
        EditableCartItem(
          cart: CartItem(
            product: product,
            qty: qty,
            selected: selectedCopy,
            note: note,
            unitFinalPrice: unitFinalPrice,
          ),
        ),
      );
    }
    notifyListeners();
  }

  void updateItemAt(
    int index, {
    required int qty,
    required Map<int, Set<int>> selected,
    required String note,
    required num unitFinalPrice,
  }) {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    if (item.isLocked) return;
    final selectedCopy = <int, Set<int>>{
      for (final entry in selected.entries) entry.key: {...entry.value},
    };
    final nextQty = qty < item.minQty ? item.minQty : qty;

    item.cart = CartItem(
      product: item.product,
      qty: nextQty,
      selected: selectedCopy,
      note: note,
      unitFinalPrice: unitFinalPrice,
    );

    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= items.length) return;
    if (items[index].isLocked) return;
    items.removeAt(index);
    notifyListeners();
  }

  void setQty(int index, int qty, {required int maxQty}) {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    if (item.isLocked) return;
    var next = qty < item.minQty ? item.minQty : qty;
    if (next > maxQty) next = maxQty;
    item.qty = next;
    notifyListeners();
  }

  void setNote(int index, String note) {
    if (index < 0 || index >= items.length) return;
    if (items[index].isLocked) return;
    items[index].note = note;
    notifyListeners();
  }

  List<Map<String, dynamic>> buildItemsPayload() {
    return items.map((item) {
      final optionIds = item.selected.values.expand((s) => s).toList();
      return <String, dynamic>{
        if (item.detailId != null) 'detail_id': item.detailId,
        'product_id': item.product.id,
        'qty': item.qty,
        'note': item.note,
        'option_ids': optionIds,
        if (item.product.promotion != null) 'promo_id': item.product.promotion!.id,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> save({
    required bool isOnline,
    bool sendToProcess = false,
  }) async {
    if (items.isEmpty) {
      throw Exception('Order harus memiliki minimal 1 item');
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      if (allItemsServed) {
        orderStatus = isOpenbillOrder ? 'UNPAID' : 'SERVED';
      }

      final payload = buildItemsPayload();
      final snapshot = await _buildSnapshotMap();
      final snapshotJson = jsonEncode(snapshot);
      final subtotalValue = subtotal.toDouble();
      final grandTotalValue = grandTotalWithPpn.toDouble();
      final lines = _buildLocalLines();

      if (serverId != null && serverId! > 0 && isOnline) {
        final updated = await ordersRepo.updateOrder(
          id: serverId!,
          orderTable: tableServerId,
          orderName: guestPayloadName(guestDisplayName(customerName)),
          items: payload,
        );

        await bookingOrdersDao.upsertFromServer(updated);

        if (allItemsServed) {
          return _transitionOrderAfterAllServed(updated, isOnline: isOnline);
        }

        if (sendToProcess) {
          return _sendOrderToProcess(
            isOnline: true,
            currentSnapshot: updated,
          );
        }

        return updated;
      }

      final effectiveClientUuid = await _resolveClientUuidForOfflineSave(
        snapshotJson: snapshotJson,
        subtotalValue: subtotalValue,
        grandTotalValue: grandTotalValue,
      );

      await bookingOrdersDao.replaceDetailsFromEdit(
        clientUuid: effectiveClientUuid,
        lines: lines,
        subtotal: subtotalValue,
        grandTotal: grandTotalValue,
        syncIntent: serverId != null && serverId! > 0 ? 'UPDATE' : 'CREATE',
      );

      if (allItemsServed) {
        return _transitionOrderAfterAllServed(snapshot, isOnline: isOnline);
      }

      if (sendToProcess) {
        return _sendOrderToProcess(
          isOnline: isOnline,
          currentSnapshot: snapshot,
          snapshotJson: snapshotJson,
        );
      }

      return snapshot;
    } on StockInsufficientException catch (e) {
      error = e.allItems.map((item) => item.label).join('\n');
      rethrow;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String> _resolveClientUuidForOfflineSave({
    required String snapshotJson,
    required double subtotalValue,
    required double grandTotalValue,
  }) async {
    if (localId != null && localId!.isNotEmpty) return localId!;

    final snapshotMap = jsonDecode(snapshotJson) as Map<String, dynamic>;
    final fromSnapshot = (snapshotMap['local_id'] ??
            snapshotMap['local_client_uuid'] ??
            '')
        .toString()
        .trim();
    if (fromSnapshot.isNotEmpty) {
      localId = fromSnapshot;
      return fromSnapshot;
    }

    if (serverId != null && serverId! > 0) {
      final existing = await bookingOrdersDao.getByServerId(serverId!);
      if (existing != null) {
        localId = existing.clientUuid;
        return existing.clientUuid;
      }

      final details = (snapshotMap['order_details'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      final uuid = await bookingOrdersDao.ensureEditMirror(
        serverId: serverId!,
        bookingOrderCode: snapshotMap['booking_order_code']?.toString() ??
            'ORDER-$serverId',
        customerName: customerName,
        tableServerId: tableServerId,
        tableNoSnapshot: tableNoSnapshot,
        orderStatus: orderStatus,
        paymentMethodEffective: paymentMethodEffective,
        subtotal: subtotalValue,
        grandTotal: grandTotalValue,
        isPpnActive: isPpnActive,
        ppn: ppnPercent.toDouble(),
        openbillFlag: openbillFlag,
        orderBy: snapshotMap['order_by']?.toString(),
        syncVersion: _toInt(snapshotMap['sync_version']),
        seedDetails: details.isNotEmpty ? details : null,
      );
      localId = uuid;
      return uuid;
    }

    throw Exception('Order mirror tidak ditemukan');
  }

  Future<Map<String, dynamic>> _buildSnapshotMap() async {
    final orderDetails = items.map((item) {
      final optionRows = <Map<String, dynamic>>[];
      for (final group in item.product.optionGroups) {
        final selectedIds = item.selected[group.id] ?? {};
        for (final opt in group.items.where((o) => selectedIds.contains(o.id))) {
          optionRows.add({
            'option_id': opt.id,
            'partner_product_option_name': opt.name,
            'parent_name': group.name,
            'price': opt.price,
          });
        }
      }

      return {
        if (item.detailId != null) 'id': item.detailId,
        'partner_product_id': item.product.id,
        'product_name': item.product.name,
        'base_price': item.product.price,
        'options_price': item.unitFinalPrice - item.product.price,
        'quantity': item.qty,
        'customer_note': item.note,
        'order_detail_options': optionRows,
        if (item.detailStatusSnapshot != null &&
            item.detailStatusSnapshot!.isNotEmpty)
          'status': item.detailStatusSnapshot,
        if (item.isLocked && item.kitchenProcessIdSnapshot != null)
          'kitchen_process_id': item.kitchenProcessIdSnapshot,
      };
    }).toList();

    return {
      'id': serverId ?? -1,
      if (localId != null) ...{
        'local_id': localId,
        'local_client_uuid': localId,
      },
      'server_id': serverId,
      'customer_name': customerName,
      'order_status': orderStatus,
      'payment_method': paymentMethodEffective,
      'payment_flag': false,
      'is_ppn_active': isPpnActive,
      'ppn': ppnPercent,
      'total_order_value': subtotal,
      'grand_total': grandTotalWithPpn,
      'table': {
        'id': tableServerId,
        'table_no': tableNoSnapshot ?? '-',
      },
      'order_details': orderDetails,
      'pending_update': true,
    };
  }

  List<Map<String, dynamic>> _buildLocalLines() {
    return items.map((item) {
      final optionLines = <Map<String, dynamic>>[];
      for (final group in item.product.optionGroups) {
        final selectedIds = item.selected[group.id] ?? {};
        for (final opt in group.items.where((o) => selectedIds.contains(o.id))) {
          optionLines.add({
            'option_server_id': opt.id,
            'option_name_snapshot': opt.name,
            'parent_name_snapshot': group.name,
            'price': opt.price.toDouble(),
          });
        }
      }

      return {
        if (item.detailId != null) 'server_order_detail_id': item.detailId,
        'product_server_id': item.product.id,
        'product_name_snapshot': item.product.name,
        'base_price': item.product.price.toDouble(),
        'qty': item.qty,
        'customer_note': item.note,
        'options_price': (item.unitFinalPrice - item.product.price).toDouble(),
        'promo_id': item.product.promotion?.id,
        if (item.detailStatusSnapshot != null)
          'detail_status': item.detailStatusSnapshot,
        'options': optionLines,
      };
    }).toList();
  }

  Product _productFromDetailSnapshot(Map<String, dynamic> detail, int productId) {
    return Product(
      id: productId,
      categoryId: parseInt(detail['category_id']),
      name: (detail['product_name'] ?? 'Produk').toString(),
      description: null,
      price: parseNum(detail['base_price']),
      isHot: false,
      isActive: true,
      quantityAvailable: 999,
      alwaysAvailable: true,
      imagePath: null,
      promotion: null,
      stockType: 'direct',
      recipes: const [],
      optionGroups: _optionGroupsFromDetail(detail),
    );
  }

  List<OptionGroup> _optionGroupsFromDetail(Map<String, dynamic> detail) {
    final options = (detail['order_detail_options'] as List?) ?? [];
    if (options.isEmpty) return const [];

    final items = options.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return OptionItem(
        id: parseInt(map['option_id'] ?? map['id']),
        name: (map['partner_product_option_name'] ?? map['name'] ?? '-').toString(),
        price: parseNum(map['price']),
        quantityAvailable: 999,
        alwaysAvailable: true,
        stockType: 'direct',
        recipes: const [],
      );
    }).toList();

    return [
      OptionGroup(
        id: 1,
        name: 'Opsi',
        min: 0,
        max: items.length,
        required: false,
        items: items,
      ),
    ];
  }

  Map<int, Set<int>> _selectedFromDetail(Product product, Map<String, dynamic> detail) {
    final selected = <int, Set<int>>{};
    final options = (detail['order_detail_options'] as List?) ?? [];

    for (final group in product.optionGroups) {
      selected[group.id] = <int>{};
    }

    for (final raw in options.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      final optionId = parseInt(map['option_id'] ?? map['id']);
      for (final group in product.optionGroups) {
        if (group.items.any((item) => item.id == optionId)) {
          selected[group.id] = {...(selected[group.id] ?? {}), optionId};
        }
      }
    }

    return selected;
  }

  num _unitPrice(Product product, Map<int, Set<int>> selected) {
    num optionsPrice = 0;
    for (final group in product.optionGroups) {
      final ids = selected[group.id] ?? {};
      for (final item in group.items) {
        if (ids.contains(item.id)) optionsPrice += item.price;
      }
    }

    num promoAmount = 0;
    final promo = product.promotion;
    if (promo != null) {
      if (promo.type == 'percentage') {
        promoAmount = product.price * promo.value / 100;
      } else {
        promoAmount = promo.value;
      }
    }

    return product.price + optionsPrice - promoAmount;
  }

  String _lockStatusLabel(Map<String, dynamic> detail) {
    final status = detailStatusOf(detail);
    if (isDetailServedStatus(status)) {
      return 'Sudah selesai';
    }
    return 'Sudah diproses';
  }

  Future<Map<String, dynamic>> _transitionOrderAfterAllServed(
    Map<String, dynamic> order, {
    required bool isOnline,
  }) async {
    final openbill = isOpenbillOrder ||
        parseBool(order['openbill_flag']) ||
        order['payment_method']?.toString() == 'OPENBILL' ||
        (order['order_status'] ?? '').toString().startsWith('OPENBILL');
    final fallbackStatus = openbill ? 'UNPAID' : 'SERVED';
    final status = (order['order_status'] ?? fallbackStatus).toString();
    final normalized = <String, dynamic>{
      ...order,
      'order_status': status,
    };

    orderStatus = status;

    if (serverId != null && serverId! > 0) {
      await tabCoordinator.transitionOrderStage(
        serverId: serverId!,
        orderStatus: status,
        syncIntent: isOnline ? null : 'UPDATE',
        syncDirty: !isOnline,
        orderSnapshot: normalized,
      );
    } else if (localId != null && localId!.isNotEmpty) {
      await tabCoordinator.transitionOrderStageByClientUuid(
        clientUuid: localId!,
        orderStatus: status,
        syncIntent: isOnline ? 'UPDATE' : 'FINISH',
      );
    }

    return normalized;
  }

  Future<Map<String, dynamic>> _sendOrderToProcess({
    required bool isOnline,
    required Map<String, dynamic> currentSnapshot,
    String? snapshotJson,
  }) async {
    const targetStatus = 'OPENBILL_WAITING_ORDER';

    if (serverId != null && serverId! > 0) {
      if (isOnline) {
        final processed = await ordersRepo.processOrder(
          serverId!,
          sendToKitchenWaiting: true,
        );
        await bookingOrdersDao.upsertFromServer(processed);
        await tabCoordinator.transitionOrderStage(
          serverId: serverId!,
          orderStatus: targetStatus,
          syncDirty: false,
          orderSnapshot: processed,
        );
        return processed;
      }

      await tabCoordinator.transitionOrderStage(
        serverId: serverId!,
        orderStatus: targetStatus,
        syncIntent: 'CONFIRM_OPENBILL',
        syncDirty: true,
        orderSnapshot: currentSnapshot,
      );

      return {
        ...currentSnapshot,
        'order_status': targetStatus,
        'pending_process': true,
      };
    }

    if (localId != null && localId!.isNotEmpty) {
      await tabCoordinator.transitionOrderStageByClientUuid(
        clientUuid: localId!,
        orderStatus: targetStatus,
        syncIntent: 'CONFIRM_OPENBILL',
      );

      return {
        ...currentSnapshot,
        'order_status': targetStatus,
        'pending_process': true,
      };
    }
    return currentSnapshot;
  }

  bool _sameSelected(Map<int, Set<int>> a, Map<int, Set<int>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      final setA = a[key] ?? {};
      final setB = b[key] ?? {};
      if (setA.length != setB.length) return false;
      for (final id in setA) {
        if (!setB.contains(id)) return false;
      }
    }
    return true;
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
