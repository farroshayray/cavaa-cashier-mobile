// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_process_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$CachedProcessOrdersDaoMixin on DatabaseAccessor<CashierDb> {
  $CachedProcessOrdersTable get cachedProcessOrders =>
      attachedDatabase.cachedProcessOrders;
  CachedProcessOrdersDaoManager get managers =>
      CachedProcessOrdersDaoManager(this);
}

class CachedProcessOrdersDaoManager {
  final _$CachedProcessOrdersDaoMixin _db;
  CachedProcessOrdersDaoManager(this._db);
  $$CachedProcessOrdersTableTableManager get cachedProcessOrders =>
      $$CachedProcessOrdersTableTableManager(
        _db.attachedDatabase,
        _db.cachedProcessOrders,
      );
}
