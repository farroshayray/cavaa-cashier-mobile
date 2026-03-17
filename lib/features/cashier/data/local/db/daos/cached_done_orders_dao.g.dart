// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_done_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$CachedDoneOrdersDaoMixin on DatabaseAccessor<CashierDb> {
  $CachedDoneOrdersTable get cachedDoneOrders =>
      attachedDatabase.cachedDoneOrders;
  CachedDoneOrdersDaoManager get managers => CachedDoneOrdersDaoManager(this);
}

class CachedDoneOrdersDaoManager {
  final _$CachedDoneOrdersDaoMixin _db;
  CachedDoneOrdersDaoManager(this._db);
  $$CachedDoneOrdersTableTableManager get cachedDoneOrders =>
      $$CachedDoneOrdersTableTableManager(
        _db.attachedDatabase,
        _db.cachedDoneOrders,
      );
}
