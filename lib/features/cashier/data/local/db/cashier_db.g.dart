// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashier_db.dart';

// ignore_for_file: type=lint
class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(99999),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    order,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final int id;
  final int serverId;
  final String name;
  final int order;
  final String rawJson;
  final DateTime cachedAt;
  const CachedCategory({
    required this.id,
    required this.serverId,
    required this.name,
    required this.order,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['name'] = Variable<String>(name);
    map['order'] = Variable<int>(order);
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      name: Value(name),
      order: Value(order),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      order: serializer.fromJson<int>(json['order']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'name': serializer.toJson<String>(name),
      'order': serializer.toJson<int>(order),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCategory copyWith({
    int? id,
    int? serverId,
    String? name,
    int? order,
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedCategory(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    name: name ?? this.name,
    order: order ?? this.order,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      order: data.order.present ? data.order.value : this.order,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, name, order, rawJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.order == this.order &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> name;
  final Value<int> order;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.order = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String name,
    this.order = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
  }) : serverId = Value(serverId),
       name = Value(name),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCategory> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<int>? order,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (order != null) 'order': order,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? name,
    Value<int>? order,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
  }) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      order: order ?? this.order,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockTypeMeta = const VerificationMeta(
    'stockType',
  );
  @override
  late final GeneratedColumn<String> stockType = GeneratedColumn<String>(
    'stock_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('linked'),
  );
  static const VerificationMeta _quantityAvailableMeta = const VerificationMeta(
    'quantityAvailable',
  );
  @override
  late final GeneratedColumn<int> quantityAvailable = GeneratedColumn<int>(
    'quantity_available',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alwaysAvailableMeta = const VerificationMeta(
    'alwaysAvailable',
  );
  @override
  late final GeneratedColumn<bool> alwaysAvailable = GeneratedColumn<bool>(
    'always_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("always_available" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _promoIdMeta = const VerificationMeta(
    'promoId',
  );
  @override
  late final GeneratedColumn<int> promoId = GeneratedColumn<int>(
    'promo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promoTypeMeta = const VerificationMeta(
    'promoType',
  );
  @override
  late final GeneratedColumn<String> promoType = GeneratedColumn<String>(
    'promo_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promoValueMeta = const VerificationMeta(
    'promoValue',
  );
  @override
  late final GeneratedColumn<double> promoValue = GeneratedColumn<double>(
    'promo_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtServerMeta = const VerificationMeta(
    'updatedAtServer',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtServer =
      GeneratedColumn<DateTime>(
        'updated_at_server',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    categoryId,
    price,
    stockType,
    quantityAvailable,
    alwaysAvailable,
    isActive,
    promoId,
    promoType,
    promoValue,
    imagePath,
    description,
    rawJson,
    updatedAtServer,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('stock_type')) {
      context.handle(
        _stockTypeMeta,
        stockType.isAcceptableOrUnknown(data['stock_type']!, _stockTypeMeta),
      );
    }
    if (data.containsKey('quantity_available')) {
      context.handle(
        _quantityAvailableMeta,
        quantityAvailable.isAcceptableOrUnknown(
          data['quantity_available']!,
          _quantityAvailableMeta,
        ),
      );
    }
    if (data.containsKey('always_available')) {
      context.handle(
        _alwaysAvailableMeta,
        alwaysAvailable.isAcceptableOrUnknown(
          data['always_available']!,
          _alwaysAvailableMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('promo_id')) {
      context.handle(
        _promoIdMeta,
        promoId.isAcceptableOrUnknown(data['promo_id']!, _promoIdMeta),
      );
    }
    if (data.containsKey('promo_type')) {
      context.handle(
        _promoTypeMeta,
        promoType.isAcceptableOrUnknown(data['promo_type']!, _promoTypeMeta),
      );
    }
    if (data.containsKey('promo_value')) {
      context.handle(
        _promoValueMeta,
        promoValue.isAcceptableOrUnknown(data['promo_value']!, _promoValueMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('updated_at_server')) {
      context.handle(
        _updatedAtServerMeta,
        updatedAtServer.isAcceptableOrUnknown(
          data['updated_at_server']!,
          _updatedAtServerMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      stockType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_type'],
      )!,
      quantityAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_available'],
      )!,
      alwaysAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}always_available'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      promoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}promo_id'],
      ),
      promoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promo_type'],
      ),
      promoValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}promo_value'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      updatedAtServer: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_server'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class CachedProduct extends DataClass implements Insertable<CachedProduct> {
  final int id;
  final int serverId;
  final String name;
  final int categoryId;
  final double price;
  final String stockType;
  final int quantityAvailable;
  final bool alwaysAvailable;
  final bool isActive;
  final int? promoId;
  final String? promoType;
  final double? promoValue;
  final String? imagePath;
  final String? description;
  final String rawJson;
  final DateTime? updatedAtServer;
  final DateTime cachedAt;
  const CachedProduct({
    required this.id,
    required this.serverId,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.stockType,
    required this.quantityAvailable,
    required this.alwaysAvailable,
    required this.isActive,
    this.promoId,
    this.promoType,
    this.promoValue,
    this.imagePath,
    this.description,
    required this.rawJson,
    this.updatedAtServer,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<int>(categoryId);
    map['price'] = Variable<double>(price);
    map['stock_type'] = Variable<String>(stockType);
    map['quantity_available'] = Variable<int>(quantityAvailable);
    map['always_available'] = Variable<bool>(alwaysAvailable);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || promoId != null) {
      map['promo_id'] = Variable<int>(promoId);
    }
    if (!nullToAbsent || promoType != null) {
      map['promo_type'] = Variable<String>(promoType);
    }
    if (!nullToAbsent || promoValue != null) {
      map['promo_value'] = Variable<double>(promoValue);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['raw_json'] = Variable<String>(rawJson);
    if (!nullToAbsent || updatedAtServer != null) {
      map['updated_at_server'] = Variable<DateTime>(updatedAtServer);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      name: Value(name),
      categoryId: Value(categoryId),
      price: Value(price),
      stockType: Value(stockType),
      quantityAvailable: Value(quantityAvailable),
      alwaysAvailable: Value(alwaysAvailable),
      isActive: Value(isActive),
      promoId: promoId == null && nullToAbsent
          ? const Value.absent()
          : Value(promoId),
      promoType: promoType == null && nullToAbsent
          ? const Value.absent()
          : Value(promoType),
      promoValue: promoValue == null && nullToAbsent
          ? const Value.absent()
          : Value(promoValue),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      rawJson: Value(rawJson),
      updatedAtServer: updatedAtServer == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtServer),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProduct(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      price: serializer.fromJson<double>(json['price']),
      stockType: serializer.fromJson<String>(json['stockType']),
      quantityAvailable: serializer.fromJson<int>(json['quantityAvailable']),
      alwaysAvailable: serializer.fromJson<bool>(json['alwaysAvailable']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      promoId: serializer.fromJson<int?>(json['promoId']),
      promoType: serializer.fromJson<String?>(json['promoType']),
      promoValue: serializer.fromJson<double?>(json['promoValue']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      description: serializer.fromJson<String?>(json['description']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      updatedAtServer: serializer.fromJson<DateTime?>(json['updatedAtServer']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int>(categoryId),
      'price': serializer.toJson<double>(price),
      'stockType': serializer.toJson<String>(stockType),
      'quantityAvailable': serializer.toJson<int>(quantityAvailable),
      'alwaysAvailable': serializer.toJson<bool>(alwaysAvailable),
      'isActive': serializer.toJson<bool>(isActive),
      'promoId': serializer.toJson<int?>(promoId),
      'promoType': serializer.toJson<String?>(promoType),
      'promoValue': serializer.toJson<double?>(promoValue),
      'imagePath': serializer.toJson<String?>(imagePath),
      'description': serializer.toJson<String?>(description),
      'rawJson': serializer.toJson<String>(rawJson),
      'updatedAtServer': serializer.toJson<DateTime?>(updatedAtServer),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProduct copyWith({
    int? id,
    int? serverId,
    String? name,
    int? categoryId,
    double? price,
    String? stockType,
    int? quantityAvailable,
    bool? alwaysAvailable,
    bool? isActive,
    Value<int?> promoId = const Value.absent(),
    Value<String?> promoType = const Value.absent(),
    Value<double?> promoValue = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? rawJson,
    Value<DateTime?> updatedAtServer = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedProduct(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    price: price ?? this.price,
    stockType: stockType ?? this.stockType,
    quantityAvailable: quantityAvailable ?? this.quantityAvailable,
    alwaysAvailable: alwaysAvailable ?? this.alwaysAvailable,
    isActive: isActive ?? this.isActive,
    promoId: promoId.present ? promoId.value : this.promoId,
    promoType: promoType.present ? promoType.value : this.promoType,
    promoValue: promoValue.present ? promoValue.value : this.promoValue,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    description: description.present ? description.value : this.description,
    rawJson: rawJson ?? this.rawJson,
    updatedAtServer: updatedAtServer.present
        ? updatedAtServer.value
        : this.updatedAtServer,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProduct copyWithCompanion(CachedProductsCompanion data) {
    return CachedProduct(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      price: data.price.present ? data.price.value : this.price,
      stockType: data.stockType.present ? data.stockType.value : this.stockType,
      quantityAvailable: data.quantityAvailable.present
          ? data.quantityAvailable.value
          : this.quantityAvailable,
      alwaysAvailable: data.alwaysAvailable.present
          ? data.alwaysAvailable.value
          : this.alwaysAvailable,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      promoId: data.promoId.present ? data.promoId.value : this.promoId,
      promoType: data.promoType.present ? data.promoType.value : this.promoType,
      promoValue: data.promoValue.present
          ? data.promoValue.value
          : this.promoValue,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      description: data.description.present
          ? data.description.value
          : this.description,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      updatedAtServer: data.updatedAtServer.present
          ? data.updatedAtServer.value
          : this.updatedAtServer,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProduct(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('price: $price, ')
          ..write('stockType: $stockType, ')
          ..write('quantityAvailable: $quantityAvailable, ')
          ..write('alwaysAvailable: $alwaysAvailable, ')
          ..write('isActive: $isActive, ')
          ..write('promoId: $promoId, ')
          ..write('promoType: $promoType, ')
          ..write('promoValue: $promoValue, ')
          ..write('imagePath: $imagePath, ')
          ..write('description: $description, ')
          ..write('rawJson: $rawJson, ')
          ..write('updatedAtServer: $updatedAtServer, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    categoryId,
    price,
    stockType,
    quantityAvailable,
    alwaysAvailable,
    isActive,
    promoId,
    promoType,
    promoValue,
    imagePath,
    description,
    rawJson,
    updatedAtServer,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProduct &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.price == this.price &&
          other.stockType == this.stockType &&
          other.quantityAvailable == this.quantityAvailable &&
          other.alwaysAvailable == this.alwaysAvailable &&
          other.isActive == this.isActive &&
          other.promoId == this.promoId &&
          other.promoType == this.promoType &&
          other.promoValue == this.promoValue &&
          other.imagePath == this.imagePath &&
          other.description == this.description &&
          other.rawJson == this.rawJson &&
          other.updatedAtServer == this.updatedAtServer &&
          other.cachedAt == this.cachedAt);
}

class CachedProductsCompanion extends UpdateCompanion<CachedProduct> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> name;
  final Value<int> categoryId;
  final Value<double> price;
  final Value<String> stockType;
  final Value<int> quantityAvailable;
  final Value<bool> alwaysAvailable;
  final Value<bool> isActive;
  final Value<int?> promoId;
  final Value<String?> promoType;
  final Value<double?> promoValue;
  final Value<String?> imagePath;
  final Value<String?> description;
  final Value<String> rawJson;
  final Value<DateTime?> updatedAtServer;
  final Value<DateTime> cachedAt;
  const CachedProductsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.price = const Value.absent(),
    this.stockType = const Value.absent(),
    this.quantityAvailable = const Value.absent(),
    this.alwaysAvailable = const Value.absent(),
    this.isActive = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoType = const Value.absent(),
    this.promoValue = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.description = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.updatedAtServer = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedProductsCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String name,
    required int categoryId,
    required double price,
    this.stockType = const Value.absent(),
    this.quantityAvailable = const Value.absent(),
    this.alwaysAvailable = const Value.absent(),
    this.isActive = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoType = const Value.absent(),
    this.promoValue = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.description = const Value.absent(),
    required String rawJson,
    this.updatedAtServer = const Value.absent(),
    required DateTime cachedAt,
  }) : serverId = Value(serverId),
       name = Value(name),
       categoryId = Value(categoryId),
       price = Value(price),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedProduct> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<double>? price,
    Expression<String>? stockType,
    Expression<int>? quantityAvailable,
    Expression<bool>? alwaysAvailable,
    Expression<bool>? isActive,
    Expression<int>? promoId,
    Expression<String>? promoType,
    Expression<double>? promoValue,
    Expression<String>? imagePath,
    Expression<String>? description,
    Expression<String>? rawJson,
    Expression<DateTime>? updatedAtServer,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (price != null) 'price': price,
      if (stockType != null) 'stock_type': stockType,
      if (quantityAvailable != null) 'quantity_available': quantityAvailable,
      if (alwaysAvailable != null) 'always_available': alwaysAvailable,
      if (isActive != null) 'is_active': isActive,
      if (promoId != null) 'promo_id': promoId,
      if (promoType != null) 'promo_type': promoType,
      if (promoValue != null) 'promo_value': promoValue,
      if (imagePath != null) 'image_path': imagePath,
      if (description != null) 'description': description,
      if (rawJson != null) 'raw_json': rawJson,
      if (updatedAtServer != null) 'updated_at_server': updatedAtServer,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedProductsCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? name,
    Value<int>? categoryId,
    Value<double>? price,
    Value<String>? stockType,
    Value<int>? quantityAvailable,
    Value<bool>? alwaysAvailable,
    Value<bool>? isActive,
    Value<int?>? promoId,
    Value<String?>? promoType,
    Value<double?>? promoValue,
    Value<String?>? imagePath,
    Value<String?>? description,
    Value<String>? rawJson,
    Value<DateTime?>? updatedAtServer,
    Value<DateTime>? cachedAt,
  }) {
    return CachedProductsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      stockType: stockType ?? this.stockType,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      alwaysAvailable: alwaysAvailable ?? this.alwaysAvailable,
      isActive: isActive ?? this.isActive,
      promoId: promoId ?? this.promoId,
      promoType: promoType ?? this.promoType,
      promoValue: promoValue ?? this.promoValue,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      rawJson: rawJson ?? this.rawJson,
      updatedAtServer: updatedAtServer ?? this.updatedAtServer,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stockType.present) {
      map['stock_type'] = Variable<String>(stockType.value);
    }
    if (quantityAvailable.present) {
      map['quantity_available'] = Variable<int>(quantityAvailable.value);
    }
    if (alwaysAvailable.present) {
      map['always_available'] = Variable<bool>(alwaysAvailable.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (promoId.present) {
      map['promo_id'] = Variable<int>(promoId.value);
    }
    if (promoType.present) {
      map['promo_type'] = Variable<String>(promoType.value);
    }
    if (promoValue.present) {
      map['promo_value'] = Variable<double>(promoValue.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (updatedAtServer.present) {
      map['updated_at_server'] = Variable<DateTime>(updatedAtServer.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProductsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('price: $price, ')
          ..write('stockType: $stockType, ')
          ..write('quantityAvailable: $quantityAvailable, ')
          ..write('alwaysAvailable: $alwaysAvailable, ')
          ..write('isActive: $isActive, ')
          ..write('promoId: $promoId, ')
          ..write('promoType: $promoType, ')
          ..write('promoValue: $promoValue, ')
          ..write('imagePath: $imagePath, ')
          ..write('description: $description, ')
          ..write('rawJson: $rawJson, ')
          ..write('updatedAtServer: $updatedAtServer, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedOptionGroupsTable extends CachedOptionGroups
    with TableInfo<$CachedOptionGroupsTable, CachedOptionGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedOptionGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _productServerIdMeta = const VerificationMeta(
    'productServerId',
  );
  @override
  late final GeneratedColumn<int> productServerId = GeneratedColumn<int>(
    'product_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minSelectMeta = const VerificationMeta(
    'minSelect',
  );
  @override
  late final GeneratedColumn<int> minSelect = GeneratedColumn<int>(
    'min_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxSelectMeta = const VerificationMeta(
    'maxSelect',
  );
  @override
  late final GeneratedColumn<int> maxSelect = GeneratedColumn<int>(
    'max_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _requiredFlagMeta = const VerificationMeta(
    'requiredFlag',
  );
  @override
  late final GeneratedColumn<bool> requiredFlag = GeneratedColumn<bool>(
    'required_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    productServerId,
    name,
    minSelect,
    maxSelect,
    requiredFlag,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_option_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedOptionGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('product_server_id')) {
      context.handle(
        _productServerIdMeta,
        productServerId.isAcceptableOrUnknown(
          data['product_server_id']!,
          _productServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productServerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_select')) {
      context.handle(
        _minSelectMeta,
        minSelect.isAcceptableOrUnknown(data['min_select']!, _minSelectMeta),
      );
    }
    if (data.containsKey('max_select')) {
      context.handle(
        _maxSelectMeta,
        maxSelect.isAcceptableOrUnknown(data['max_select']!, _maxSelectMeta),
      );
    }
    if (data.containsKey('required_flag')) {
      context.handle(
        _requiredFlagMeta,
        requiredFlag.isAcceptableOrUnknown(
          data['required_flag']!,
          _requiredFlagMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedOptionGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedOptionGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      productServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_select'],
      )!,
      maxSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_select'],
      )!,
      requiredFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required_flag'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedOptionGroupsTable createAlias(String alias) {
    return $CachedOptionGroupsTable(attachedDatabase, alias);
  }
}

class CachedOptionGroup extends DataClass
    implements Insertable<CachedOptionGroup> {
  final int id;
  final int serverId;
  final int productServerId;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool requiredFlag;
  final String rawJson;
  final DateTime cachedAt;
  const CachedOptionGroup({
    required this.id,
    required this.serverId,
    required this.productServerId,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.requiredFlag,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['product_server_id'] = Variable<int>(productServerId);
    map['name'] = Variable<String>(name);
    map['min_select'] = Variable<int>(minSelect);
    map['max_select'] = Variable<int>(maxSelect);
    map['required_flag'] = Variable<bool>(requiredFlag);
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedOptionGroupsCompanion toCompanion(bool nullToAbsent) {
    return CachedOptionGroupsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      productServerId: Value(productServerId),
      name: Value(name),
      minSelect: Value(minSelect),
      maxSelect: Value(maxSelect),
      requiredFlag: Value(requiredFlag),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedOptionGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedOptionGroup(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      productServerId: serializer.fromJson<int>(json['productServerId']),
      name: serializer.fromJson<String>(json['name']),
      minSelect: serializer.fromJson<int>(json['minSelect']),
      maxSelect: serializer.fromJson<int>(json['maxSelect']),
      requiredFlag: serializer.fromJson<bool>(json['requiredFlag']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'productServerId': serializer.toJson<int>(productServerId),
      'name': serializer.toJson<String>(name),
      'minSelect': serializer.toJson<int>(minSelect),
      'maxSelect': serializer.toJson<int>(maxSelect),
      'requiredFlag': serializer.toJson<bool>(requiredFlag),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedOptionGroup copyWith({
    int? id,
    int? serverId,
    int? productServerId,
    String? name,
    int? minSelect,
    int? maxSelect,
    bool? requiredFlag,
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedOptionGroup(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    productServerId: productServerId ?? this.productServerId,
    name: name ?? this.name,
    minSelect: minSelect ?? this.minSelect,
    maxSelect: maxSelect ?? this.maxSelect,
    requiredFlag: requiredFlag ?? this.requiredFlag,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedOptionGroup copyWithCompanion(CachedOptionGroupsCompanion data) {
    return CachedOptionGroup(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productServerId: data.productServerId.present
          ? data.productServerId.value
          : this.productServerId,
      name: data.name.present ? data.name.value : this.name,
      minSelect: data.minSelect.present ? data.minSelect.value : this.minSelect,
      maxSelect: data.maxSelect.present ? data.maxSelect.value : this.maxSelect,
      requiredFlag: data.requiredFlag.present
          ? data.requiredFlag.value
          : this.requiredFlag,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedOptionGroup(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productServerId: $productServerId, ')
          ..write('name: $name, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('requiredFlag: $requiredFlag, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    productServerId,
    name,
    minSelect,
    maxSelect,
    requiredFlag,
    rawJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedOptionGroup &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.productServerId == this.productServerId &&
          other.name == this.name &&
          other.minSelect == this.minSelect &&
          other.maxSelect == this.maxSelect &&
          other.requiredFlag == this.requiredFlag &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedOptionGroupsCompanion extends UpdateCompanion<CachedOptionGroup> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<int> productServerId;
  final Value<String> name;
  final Value<int> minSelect;
  final Value<int> maxSelect;
  final Value<bool> requiredFlag;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  const CachedOptionGroupsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productServerId = const Value.absent(),
    this.name = const Value.absent(),
    this.minSelect = const Value.absent(),
    this.maxSelect = const Value.absent(),
    this.requiredFlag = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedOptionGroupsCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required int productServerId,
    required String name,
    this.minSelect = const Value.absent(),
    this.maxSelect = const Value.absent(),
    this.requiredFlag = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
  }) : serverId = Value(serverId),
       productServerId = Value(productServerId),
       name = Value(name),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedOptionGroup> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? productServerId,
    Expression<String>? name,
    Expression<int>? minSelect,
    Expression<int>? maxSelect,
    Expression<bool>? requiredFlag,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (productServerId != null) 'product_server_id': productServerId,
      if (name != null) 'name': name,
      if (minSelect != null) 'min_select': minSelect,
      if (maxSelect != null) 'max_select': maxSelect,
      if (requiredFlag != null) 'required_flag': requiredFlag,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedOptionGroupsCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<int>? productServerId,
    Value<String>? name,
    Value<int>? minSelect,
    Value<int>? maxSelect,
    Value<bool>? requiredFlag,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
  }) {
    return CachedOptionGroupsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      productServerId: productServerId ?? this.productServerId,
      name: name ?? this.name,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      requiredFlag: requiredFlag ?? this.requiredFlag,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (productServerId.present) {
      map['product_server_id'] = Variable<int>(productServerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minSelect.present) {
      map['min_select'] = Variable<int>(minSelect.value);
    }
    if (maxSelect.present) {
      map['max_select'] = Variable<int>(maxSelect.value);
    }
    if (requiredFlag.present) {
      map['required_flag'] = Variable<bool>(requiredFlag.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedOptionGroupsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('productServerId: $productServerId, ')
          ..write('name: $name, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('requiredFlag: $requiredFlag, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedOptionItemsTable extends CachedOptionItems
    with TableInfo<$CachedOptionItemsTable, CachedOptionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedOptionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _groupServerIdMeta = const VerificationMeta(
    'groupServerId',
  );
  @override
  late final GeneratedColumn<int> groupServerId = GeneratedColumn<int>(
    'group_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productServerIdMeta = const VerificationMeta(
    'productServerId',
  );
  @override
  late final GeneratedColumn<int> productServerId = GeneratedColumn<int>(
    'product_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockTypeMeta = const VerificationMeta(
    'stockType',
  );
  @override
  late final GeneratedColumn<String> stockType = GeneratedColumn<String>(
    'stock_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('linked'),
  );
  static const VerificationMeta _quantityAvailableMeta = const VerificationMeta(
    'quantityAvailable',
  );
  @override
  late final GeneratedColumn<int> quantityAvailable = GeneratedColumn<int>(
    'quantity_available',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alwaysAvailableMeta = const VerificationMeta(
    'alwaysAvailable',
  );
  @override
  late final GeneratedColumn<bool> alwaysAvailable = GeneratedColumn<bool>(
    'always_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("always_available" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    groupServerId,
    productServerId,
    name,
    price,
    stockType,
    quantityAvailable,
    alwaysAvailable,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_option_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedOptionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('group_server_id')) {
      context.handle(
        _groupServerIdMeta,
        groupServerId.isAcceptableOrUnknown(
          data['group_server_id']!,
          _groupServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_groupServerIdMeta);
    }
    if (data.containsKey('product_server_id')) {
      context.handle(
        _productServerIdMeta,
        productServerId.isAcceptableOrUnknown(
          data['product_server_id']!,
          _productServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productServerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('stock_type')) {
      context.handle(
        _stockTypeMeta,
        stockType.isAcceptableOrUnknown(data['stock_type']!, _stockTypeMeta),
      );
    }
    if (data.containsKey('quantity_available')) {
      context.handle(
        _quantityAvailableMeta,
        quantityAvailable.isAcceptableOrUnknown(
          data['quantity_available']!,
          _quantityAvailableMeta,
        ),
      );
    }
    if (data.containsKey('always_available')) {
      context.handle(
        _alwaysAvailableMeta,
        alwaysAvailable.isAcceptableOrUnknown(
          data['always_available']!,
          _alwaysAvailableMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedOptionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedOptionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      groupServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_server_id'],
      )!,
      productServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      stockType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_type'],
      )!,
      quantityAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_available'],
      )!,
      alwaysAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}always_available'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedOptionItemsTable createAlias(String alias) {
    return $CachedOptionItemsTable(attachedDatabase, alias);
  }
}

class CachedOptionItem extends DataClass
    implements Insertable<CachedOptionItem> {
  final int id;
  final int serverId;
  final int groupServerId;
  final int productServerId;
  final String name;
  final double price;
  final String stockType;
  final int quantityAvailable;
  final bool alwaysAvailable;
  final String rawJson;
  final DateTime cachedAt;
  const CachedOptionItem({
    required this.id,
    required this.serverId,
    required this.groupServerId,
    required this.productServerId,
    required this.name,
    required this.price,
    required this.stockType,
    required this.quantityAvailable,
    required this.alwaysAvailable,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['group_server_id'] = Variable<int>(groupServerId);
    map['product_server_id'] = Variable<int>(productServerId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['stock_type'] = Variable<String>(stockType);
    map['quantity_available'] = Variable<int>(quantityAvailable);
    map['always_available'] = Variable<bool>(alwaysAvailable);
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedOptionItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedOptionItemsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      groupServerId: Value(groupServerId),
      productServerId: Value(productServerId),
      name: Value(name),
      price: Value(price),
      stockType: Value(stockType),
      quantityAvailable: Value(quantityAvailable),
      alwaysAvailable: Value(alwaysAvailable),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedOptionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedOptionItem(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      groupServerId: serializer.fromJson<int>(json['groupServerId']),
      productServerId: serializer.fromJson<int>(json['productServerId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      stockType: serializer.fromJson<String>(json['stockType']),
      quantityAvailable: serializer.fromJson<int>(json['quantityAvailable']),
      alwaysAvailable: serializer.fromJson<bool>(json['alwaysAvailable']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'groupServerId': serializer.toJson<int>(groupServerId),
      'productServerId': serializer.toJson<int>(productServerId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'stockType': serializer.toJson<String>(stockType),
      'quantityAvailable': serializer.toJson<int>(quantityAvailable),
      'alwaysAvailable': serializer.toJson<bool>(alwaysAvailable),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedOptionItem copyWith({
    int? id,
    int? serverId,
    int? groupServerId,
    int? productServerId,
    String? name,
    double? price,
    String? stockType,
    int? quantityAvailable,
    bool? alwaysAvailable,
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedOptionItem(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    groupServerId: groupServerId ?? this.groupServerId,
    productServerId: productServerId ?? this.productServerId,
    name: name ?? this.name,
    price: price ?? this.price,
    stockType: stockType ?? this.stockType,
    quantityAvailable: quantityAvailable ?? this.quantityAvailable,
    alwaysAvailable: alwaysAvailable ?? this.alwaysAvailable,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedOptionItem copyWithCompanion(CachedOptionItemsCompanion data) {
    return CachedOptionItem(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      groupServerId: data.groupServerId.present
          ? data.groupServerId.value
          : this.groupServerId,
      productServerId: data.productServerId.present
          ? data.productServerId.value
          : this.productServerId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      stockType: data.stockType.present ? data.stockType.value : this.stockType,
      quantityAvailable: data.quantityAvailable.present
          ? data.quantityAvailable.value
          : this.quantityAvailable,
      alwaysAvailable: data.alwaysAvailable.present
          ? data.alwaysAvailable.value
          : this.alwaysAvailable,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedOptionItem(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupServerId: $groupServerId, ')
          ..write('productServerId: $productServerId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('stockType: $stockType, ')
          ..write('quantityAvailable: $quantityAvailable, ')
          ..write('alwaysAvailable: $alwaysAvailable, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    groupServerId,
    productServerId,
    name,
    price,
    stockType,
    quantityAvailable,
    alwaysAvailable,
    rawJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedOptionItem &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.groupServerId == this.groupServerId &&
          other.productServerId == this.productServerId &&
          other.name == this.name &&
          other.price == this.price &&
          other.stockType == this.stockType &&
          other.quantityAvailable == this.quantityAvailable &&
          other.alwaysAvailable == this.alwaysAvailable &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedOptionItemsCompanion extends UpdateCompanion<CachedOptionItem> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<int> groupServerId;
  final Value<int> productServerId;
  final Value<String> name;
  final Value<double> price;
  final Value<String> stockType;
  final Value<int> quantityAvailable;
  final Value<bool> alwaysAvailable;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  const CachedOptionItemsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.groupServerId = const Value.absent(),
    this.productServerId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.stockType = const Value.absent(),
    this.quantityAvailable = const Value.absent(),
    this.alwaysAvailable = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedOptionItemsCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required int groupServerId,
    required int productServerId,
    required String name,
    this.price = const Value.absent(),
    this.stockType = const Value.absent(),
    this.quantityAvailable = const Value.absent(),
    this.alwaysAvailable = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
  }) : serverId = Value(serverId),
       groupServerId = Value(groupServerId),
       productServerId = Value(productServerId),
       name = Value(name),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedOptionItem> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? groupServerId,
    Expression<int>? productServerId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<String>? stockType,
    Expression<int>? quantityAvailable,
    Expression<bool>? alwaysAvailable,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (groupServerId != null) 'group_server_id': groupServerId,
      if (productServerId != null) 'product_server_id': productServerId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (stockType != null) 'stock_type': stockType,
      if (quantityAvailable != null) 'quantity_available': quantityAvailable,
      if (alwaysAvailable != null) 'always_available': alwaysAvailable,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedOptionItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<int>? groupServerId,
    Value<int>? productServerId,
    Value<String>? name,
    Value<double>? price,
    Value<String>? stockType,
    Value<int>? quantityAvailable,
    Value<bool>? alwaysAvailable,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
  }) {
    return CachedOptionItemsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      groupServerId: groupServerId ?? this.groupServerId,
      productServerId: productServerId ?? this.productServerId,
      name: name ?? this.name,
      price: price ?? this.price,
      stockType: stockType ?? this.stockType,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      alwaysAvailable: alwaysAvailable ?? this.alwaysAvailable,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (groupServerId.present) {
      map['group_server_id'] = Variable<int>(groupServerId.value);
    }
    if (productServerId.present) {
      map['product_server_id'] = Variable<int>(productServerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stockType.present) {
      map['stock_type'] = Variable<String>(stockType.value);
    }
    if (quantityAvailable.present) {
      map['quantity_available'] = Variable<int>(quantityAvailable.value);
    }
    if (alwaysAvailable.present) {
      map['always_available'] = Variable<bool>(alwaysAvailable.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedOptionItemsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupServerId: $groupServerId, ')
          ..write('productServerId: $productServerId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('stockType: $stockType, ')
          ..write('quantityAvailable: $quantityAvailable, ')
          ..write('alwaysAvailable: $alwaysAvailable, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedTablesTable extends CachedTables
    with TableInfo<$CachedTablesTable, CachedTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tableNoMeta = const VerificationMeta(
    'tableNo',
  );
  @override
  late final GeneratedColumn<String> tableNo = GeneratedColumn<String>(
    'table_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableCodeMeta = const VerificationMeta(
    'tableCode',
  );
  @override
  late final GeneratedColumn<String> tableCode = GeneratedColumn<String>(
    'table_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableClassMeta = const VerificationMeta(
    'tableClass',
  );
  @override
  late final GeneratedColumn<String> tableClass = GeneratedColumn<String>(
    'table_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableUrlMeta = const VerificationMeta(
    'tableUrl',
  );
  @override
  late final GeneratedColumn<String> tableUrl = GeneratedColumn<String>(
    'table_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    tableNo,
    tableCode,
    tableClass,
    status,
    imagePath,
    tableUrl,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('table_no')) {
      context.handle(
        _tableNoMeta,
        tableNo.isAcceptableOrUnknown(data['table_no']!, _tableNoMeta),
      );
    } else if (isInserting) {
      context.missing(_tableNoMeta);
    }
    if (data.containsKey('table_code')) {
      context.handle(
        _tableCodeMeta,
        tableCode.isAcceptableOrUnknown(data['table_code']!, _tableCodeMeta),
      );
    }
    if (data.containsKey('table_class')) {
      context.handle(
        _tableClassMeta,
        tableClass.isAcceptableOrUnknown(data['table_class']!, _tableClassMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('table_url')) {
      context.handle(
        _tableUrlMeta,
        tableUrl.isAcceptableOrUnknown(data['table_url']!, _tableUrlMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      tableNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no'],
      )!,
      tableCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_code'],
      ),
      tableClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_class'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      tableUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_url'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedTablesTable createAlias(String alias) {
    return $CachedTablesTable(attachedDatabase, alias);
  }
}

class CachedTable extends DataClass implements Insertable<CachedTable> {
  final int id;
  final int serverId;
  final String tableNo;
  final String? tableCode;
  final String? tableClass;
  final String status;
  final String? imagePath;
  final String? tableUrl;
  final String rawJson;
  final DateTime cachedAt;
  const CachedTable({
    required this.id,
    required this.serverId,
    required this.tableNo,
    this.tableCode,
    this.tableClass,
    required this.status,
    this.imagePath,
    this.tableUrl,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['table_no'] = Variable<String>(tableNo);
    if (!nullToAbsent || tableCode != null) {
      map['table_code'] = Variable<String>(tableCode);
    }
    if (!nullToAbsent || tableClass != null) {
      map['table_class'] = Variable<String>(tableClass);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || tableUrl != null) {
      map['table_url'] = Variable<String>(tableUrl);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedTablesCompanion toCompanion(bool nullToAbsent) {
    return CachedTablesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      tableNo: Value(tableNo),
      tableCode: tableCode == null && nullToAbsent
          ? const Value.absent()
          : Value(tableCode),
      tableClass: tableClass == null && nullToAbsent
          ? const Value.absent()
          : Value(tableClass),
      status: Value(status),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      tableUrl: tableUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(tableUrl),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTable(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      tableNo: serializer.fromJson<String>(json['tableNo']),
      tableCode: serializer.fromJson<String?>(json['tableCode']),
      tableClass: serializer.fromJson<String?>(json['tableClass']),
      status: serializer.fromJson<String>(json['status']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      tableUrl: serializer.fromJson<String?>(json['tableUrl']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'tableNo': serializer.toJson<String>(tableNo),
      'tableCode': serializer.toJson<String?>(tableCode),
      'tableClass': serializer.toJson<String?>(tableClass),
      'status': serializer.toJson<String>(status),
      'imagePath': serializer.toJson<String?>(imagePath),
      'tableUrl': serializer.toJson<String?>(tableUrl),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedTable copyWith({
    int? id,
    int? serverId,
    String? tableNo,
    Value<String?> tableCode = const Value.absent(),
    Value<String?> tableClass = const Value.absent(),
    String? status,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> tableUrl = const Value.absent(),
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedTable(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    tableNo: tableNo ?? this.tableNo,
    tableCode: tableCode.present ? tableCode.value : this.tableCode,
    tableClass: tableClass.present ? tableClass.value : this.tableClass,
    status: status ?? this.status,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    tableUrl: tableUrl.present ? tableUrl.value : this.tableUrl,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedTable copyWithCompanion(CachedTablesCompanion data) {
    return CachedTable(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      tableNo: data.tableNo.present ? data.tableNo.value : this.tableNo,
      tableCode: data.tableCode.present ? data.tableCode.value : this.tableCode,
      tableClass: data.tableClass.present
          ? data.tableClass.value
          : this.tableClass,
      status: data.status.present ? data.status.value : this.status,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      tableUrl: data.tableUrl.present ? data.tableUrl.value : this.tableUrl,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTable(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('tableNo: $tableNo, ')
          ..write('tableCode: $tableCode, ')
          ..write('tableClass: $tableClass, ')
          ..write('status: $status, ')
          ..write('imagePath: $imagePath, ')
          ..write('tableUrl: $tableUrl, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    tableNo,
    tableCode,
    tableClass,
    status,
    imagePath,
    tableUrl,
    rawJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTable &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.tableNo == this.tableNo &&
          other.tableCode == this.tableCode &&
          other.tableClass == this.tableClass &&
          other.status == this.status &&
          other.imagePath == this.imagePath &&
          other.tableUrl == this.tableUrl &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedTablesCompanion extends UpdateCompanion<CachedTable> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> tableNo;
  final Value<String?> tableCode;
  final Value<String?> tableClass;
  final Value<String> status;
  final Value<String?> imagePath;
  final Value<String?> tableUrl;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  const CachedTablesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.tableCode = const Value.absent(),
    this.tableClass = const Value.absent(),
    this.status = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.tableUrl = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedTablesCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String tableNo,
    this.tableCode = const Value.absent(),
    this.tableClass = const Value.absent(),
    this.status = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.tableUrl = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
  }) : serverId = Value(serverId),
       tableNo = Value(tableNo),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedTable> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? tableNo,
    Expression<String>? tableCode,
    Expression<String>? tableClass,
    Expression<String>? status,
    Expression<String>? imagePath,
    Expression<String>? tableUrl,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (tableNo != null) 'table_no': tableNo,
      if (tableCode != null) 'table_code': tableCode,
      if (tableClass != null) 'table_class': tableClass,
      if (status != null) 'status': status,
      if (imagePath != null) 'image_path': imagePath,
      if (tableUrl != null) 'table_url': tableUrl,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedTablesCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? tableNo,
    Value<String?>? tableCode,
    Value<String?>? tableClass,
    Value<String>? status,
    Value<String?>? imagePath,
    Value<String?>? tableUrl,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
  }) {
    return CachedTablesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      tableNo: tableNo ?? this.tableNo,
      tableCode: tableCode ?? this.tableCode,
      tableClass: tableClass ?? this.tableClass,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      tableUrl: tableUrl ?? this.tableUrl,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (tableNo.present) {
      map['table_no'] = Variable<String>(tableNo.value);
    }
    if (tableCode.present) {
      map['table_code'] = Variable<String>(tableCode.value);
    }
    if (tableClass.present) {
      map['table_class'] = Variable<String>(tableClass.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (tableUrl.present) {
      map['table_url'] = Variable<String>(tableUrl.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTablesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('tableNo: $tableNo, ')
          ..write('tableCode: $tableCode, ')
          ..write('tableClass: $tableClass, ')
          ..write('status: $status, ')
          ..write('imagePath: $imagePath, ')
          ..write('tableUrl: $tableUrl, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPaymentMethodsTable extends CachedPaymentMethods
    with TableInfo<$CachedPaymentMethodsTable, CachedPaymentMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPaymentMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localKeyMeta = const VerificationMeta(
    'localKey',
  );
  @override
  late final GeneratedColumn<String> localKey = GeneratedColumn<String>(
    'local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverManualPaymentIdMeta =
      const VerificationMeta('serverManualPaymentId');
  @override
  late final GeneratedColumn<int> serverManualPaymentId = GeneratedColumn<int>(
    'server_manual_payment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerNameMeta = const VerificationMeta(
    'providerName',
  );
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
    'provider_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerAccountNameMeta =
      const VerificationMeta('providerAccountName');
  @override
  late final GeneratedColumn<String> providerAccountName =
      GeneratedColumn<String>(
        'provider_account_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _providerAccountNoMeta = const VerificationMeta(
    'providerAccountNo',
  );
  @override
  late final GeneratedColumn<String> providerAccountNo =
      GeneratedColumn<String>(
        'provider_account_no',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _qrisImageUrlMeta = const VerificationMeta(
    'qrisImageUrl',
  );
  @override
  late final GeneratedColumn<String> qrisImageUrl = GeneratedColumn<String>(
    'qris_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qrisImageLocalPathMeta =
      const VerificationMeta('qrisImageLocalPath');
  @override
  late final GeneratedColumn<String> qrisImageLocalPath =
      GeneratedColumn<String>(
        'qris_image_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localKey,
    kind,
    serverManualPaymentId,
    label,
    providerName,
    providerAccountName,
    providerAccountNo,
    qrisImageUrl,
    qrisImageLocalPath,
    isActive,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPaymentMethod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_key')) {
      context.handle(
        _localKeyMeta,
        localKey.isAcceptableOrUnknown(data['local_key']!, _localKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_localKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('server_manual_payment_id')) {
      context.handle(
        _serverManualPaymentIdMeta,
        serverManualPaymentId.isAcceptableOrUnknown(
          data['server_manual_payment_id']!,
          _serverManualPaymentIdMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    }
    if (data.containsKey('provider_account_name')) {
      context.handle(
        _providerAccountNameMeta,
        providerAccountName.isAcceptableOrUnknown(
          data['provider_account_name']!,
          _providerAccountNameMeta,
        ),
      );
    }
    if (data.containsKey('provider_account_no')) {
      context.handle(
        _providerAccountNoMeta,
        providerAccountNo.isAcceptableOrUnknown(
          data['provider_account_no']!,
          _providerAccountNoMeta,
        ),
      );
    }
    if (data.containsKey('qris_image_url')) {
      context.handle(
        _qrisImageUrlMeta,
        qrisImageUrl.isAcceptableOrUnknown(
          data['qris_image_url']!,
          _qrisImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('qris_image_local_path')) {
      context.handle(
        _qrisImageLocalPathMeta,
        qrisImageLocalPath.isAcceptableOrUnknown(
          data['qris_image_local_path']!,
          _qrisImageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPaymentMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPaymentMethod(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      serverManualPaymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_manual_payment_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      providerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      ),
      providerAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_account_name'],
      ),
      providerAccountNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_account_no'],
      ),
      qrisImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qris_image_url'],
      ),
      qrisImageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qris_image_local_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPaymentMethodsTable createAlias(String alias) {
    return $CachedPaymentMethodsTable(attachedDatabase, alias);
  }
}

class CachedPaymentMethod extends DataClass
    implements Insertable<CachedPaymentMethod> {
  final int id;
  final String localKey;
  final String kind;
  final int? serverManualPaymentId;
  final String label;
  final String? providerName;
  final String? providerAccountName;
  final String? providerAccountNo;
  final String? qrisImageUrl;
  final String? qrisImageLocalPath;
  final bool isActive;
  final String rawJson;
  final DateTime cachedAt;
  const CachedPaymentMethod({
    required this.id,
    required this.localKey,
    required this.kind,
    this.serverManualPaymentId,
    required this.label,
    this.providerName,
    this.providerAccountName,
    this.providerAccountNo,
    this.qrisImageUrl,
    this.qrisImageLocalPath,
    required this.isActive,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_key'] = Variable<String>(localKey);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || serverManualPaymentId != null) {
      map['server_manual_payment_id'] = Variable<int>(serverManualPaymentId);
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || providerName != null) {
      map['provider_name'] = Variable<String>(providerName);
    }
    if (!nullToAbsent || providerAccountName != null) {
      map['provider_account_name'] = Variable<String>(providerAccountName);
    }
    if (!nullToAbsent || providerAccountNo != null) {
      map['provider_account_no'] = Variable<String>(providerAccountNo);
    }
    if (!nullToAbsent || qrisImageUrl != null) {
      map['qris_image_url'] = Variable<String>(qrisImageUrl);
    }
    if (!nullToAbsent || qrisImageLocalPath != null) {
      map['qris_image_local_path'] = Variable<String>(qrisImageLocalPath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return CachedPaymentMethodsCompanion(
      id: Value(id),
      localKey: Value(localKey),
      kind: Value(kind),
      serverManualPaymentId: serverManualPaymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverManualPaymentId),
      label: Value(label),
      providerName: providerName == null && nullToAbsent
          ? const Value.absent()
          : Value(providerName),
      providerAccountName: providerAccountName == null && nullToAbsent
          ? const Value.absent()
          : Value(providerAccountName),
      providerAccountNo: providerAccountNo == null && nullToAbsent
          ? const Value.absent()
          : Value(providerAccountNo),
      qrisImageUrl: qrisImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(qrisImageUrl),
      qrisImageLocalPath: qrisImageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(qrisImageLocalPath),
      isActive: Value(isActive),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPaymentMethod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPaymentMethod(
      id: serializer.fromJson<int>(json['id']),
      localKey: serializer.fromJson<String>(json['localKey']),
      kind: serializer.fromJson<String>(json['kind']),
      serverManualPaymentId: serializer.fromJson<int?>(
        json['serverManualPaymentId'],
      ),
      label: serializer.fromJson<String>(json['label']),
      providerName: serializer.fromJson<String?>(json['providerName']),
      providerAccountName: serializer.fromJson<String?>(
        json['providerAccountName'],
      ),
      providerAccountNo: serializer.fromJson<String?>(
        json['providerAccountNo'],
      ),
      qrisImageUrl: serializer.fromJson<String?>(json['qrisImageUrl']),
      qrisImageLocalPath: serializer.fromJson<String?>(
        json['qrisImageLocalPath'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localKey': serializer.toJson<String>(localKey),
      'kind': serializer.toJson<String>(kind),
      'serverManualPaymentId': serializer.toJson<int?>(serverManualPaymentId),
      'label': serializer.toJson<String>(label),
      'providerName': serializer.toJson<String?>(providerName),
      'providerAccountName': serializer.toJson<String?>(providerAccountName),
      'providerAccountNo': serializer.toJson<String?>(providerAccountNo),
      'qrisImageUrl': serializer.toJson<String?>(qrisImageUrl),
      'qrisImageLocalPath': serializer.toJson<String?>(qrisImageLocalPath),
      'isActive': serializer.toJson<bool>(isActive),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPaymentMethod copyWith({
    int? id,
    String? localKey,
    String? kind,
    Value<int?> serverManualPaymentId = const Value.absent(),
    String? label,
    Value<String?> providerName = const Value.absent(),
    Value<String?> providerAccountName = const Value.absent(),
    Value<String?> providerAccountNo = const Value.absent(),
    Value<String?> qrisImageUrl = const Value.absent(),
    Value<String?> qrisImageLocalPath = const Value.absent(),
    bool? isActive,
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedPaymentMethod(
    id: id ?? this.id,
    localKey: localKey ?? this.localKey,
    kind: kind ?? this.kind,
    serverManualPaymentId: serverManualPaymentId.present
        ? serverManualPaymentId.value
        : this.serverManualPaymentId,
    label: label ?? this.label,
    providerName: providerName.present ? providerName.value : this.providerName,
    providerAccountName: providerAccountName.present
        ? providerAccountName.value
        : this.providerAccountName,
    providerAccountNo: providerAccountNo.present
        ? providerAccountNo.value
        : this.providerAccountNo,
    qrisImageUrl: qrisImageUrl.present ? qrisImageUrl.value : this.qrisImageUrl,
    qrisImageLocalPath: qrisImageLocalPath.present
        ? qrisImageLocalPath.value
        : this.qrisImageLocalPath,
    isActive: isActive ?? this.isActive,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPaymentMethod copyWithCompanion(CachedPaymentMethodsCompanion data) {
    return CachedPaymentMethod(
      id: data.id.present ? data.id.value : this.id,
      localKey: data.localKey.present ? data.localKey.value : this.localKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      serverManualPaymentId: data.serverManualPaymentId.present
          ? data.serverManualPaymentId.value
          : this.serverManualPaymentId,
      label: data.label.present ? data.label.value : this.label,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      providerAccountName: data.providerAccountName.present
          ? data.providerAccountName.value
          : this.providerAccountName,
      providerAccountNo: data.providerAccountNo.present
          ? data.providerAccountNo.value
          : this.providerAccountNo,
      qrisImageUrl: data.qrisImageUrl.present
          ? data.qrisImageUrl.value
          : this.qrisImageUrl,
      qrisImageLocalPath: data.qrisImageLocalPath.present
          ? data.qrisImageLocalPath.value
          : this.qrisImageLocalPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentMethod(')
          ..write('id: $id, ')
          ..write('localKey: $localKey, ')
          ..write('kind: $kind, ')
          ..write('serverManualPaymentId: $serverManualPaymentId, ')
          ..write('label: $label, ')
          ..write('providerName: $providerName, ')
          ..write('providerAccountName: $providerAccountName, ')
          ..write('providerAccountNo: $providerAccountNo, ')
          ..write('qrisImageUrl: $qrisImageUrl, ')
          ..write('qrisImageLocalPath: $qrisImageLocalPath, ')
          ..write('isActive: $isActive, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localKey,
    kind,
    serverManualPaymentId,
    label,
    providerName,
    providerAccountName,
    providerAccountNo,
    qrisImageUrl,
    qrisImageLocalPath,
    isActive,
    rawJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPaymentMethod &&
          other.id == this.id &&
          other.localKey == this.localKey &&
          other.kind == this.kind &&
          other.serverManualPaymentId == this.serverManualPaymentId &&
          other.label == this.label &&
          other.providerName == this.providerName &&
          other.providerAccountName == this.providerAccountName &&
          other.providerAccountNo == this.providerAccountNo &&
          other.qrisImageUrl == this.qrisImageUrl &&
          other.qrisImageLocalPath == this.qrisImageLocalPath &&
          other.isActive == this.isActive &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedPaymentMethodsCompanion
    extends UpdateCompanion<CachedPaymentMethod> {
  final Value<int> id;
  final Value<String> localKey;
  final Value<String> kind;
  final Value<int?> serverManualPaymentId;
  final Value<String> label;
  final Value<String?> providerName;
  final Value<String?> providerAccountName;
  final Value<String?> providerAccountNo;
  final Value<String?> qrisImageUrl;
  final Value<String?> qrisImageLocalPath;
  final Value<bool> isActive;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  const CachedPaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.localKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.serverManualPaymentId = const Value.absent(),
    this.label = const Value.absent(),
    this.providerName = const Value.absent(),
    this.providerAccountName = const Value.absent(),
    this.providerAccountNo = const Value.absent(),
    this.qrisImageUrl = const Value.absent(),
    this.qrisImageLocalPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedPaymentMethodsCompanion.insert({
    this.id = const Value.absent(),
    required String localKey,
    required String kind,
    this.serverManualPaymentId = const Value.absent(),
    required String label,
    this.providerName = const Value.absent(),
    this.providerAccountName = const Value.absent(),
    this.providerAccountNo = const Value.absent(),
    this.qrisImageUrl = const Value.absent(),
    this.qrisImageLocalPath = const Value.absent(),
    this.isActive = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
  }) : localKey = Value(localKey),
       kind = Value(kind),
       label = Value(label),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedPaymentMethod> custom({
    Expression<int>? id,
    Expression<String>? localKey,
    Expression<String>? kind,
    Expression<int>? serverManualPaymentId,
    Expression<String>? label,
    Expression<String>? providerName,
    Expression<String>? providerAccountName,
    Expression<String>? providerAccountNo,
    Expression<String>? qrisImageUrl,
    Expression<String>? qrisImageLocalPath,
    Expression<bool>? isActive,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localKey != null) 'local_key': localKey,
      if (kind != null) 'kind': kind,
      if (serverManualPaymentId != null)
        'server_manual_payment_id': serverManualPaymentId,
      if (label != null) 'label': label,
      if (providerName != null) 'provider_name': providerName,
      if (providerAccountName != null)
        'provider_account_name': providerAccountName,
      if (providerAccountNo != null) 'provider_account_no': providerAccountNo,
      if (qrisImageUrl != null) 'qris_image_url': qrisImageUrl,
      if (qrisImageLocalPath != null)
        'qris_image_local_path': qrisImageLocalPath,
      if (isActive != null) 'is_active': isActive,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedPaymentMethodsCompanion copyWith({
    Value<int>? id,
    Value<String>? localKey,
    Value<String>? kind,
    Value<int?>? serverManualPaymentId,
    Value<String>? label,
    Value<String?>? providerName,
    Value<String?>? providerAccountName,
    Value<String?>? providerAccountNo,
    Value<String?>? qrisImageUrl,
    Value<String?>? qrisImageLocalPath,
    Value<bool>? isActive,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
  }) {
    return CachedPaymentMethodsCompanion(
      id: id ?? this.id,
      localKey: localKey ?? this.localKey,
      kind: kind ?? this.kind,
      serverManualPaymentId:
          serverManualPaymentId ?? this.serverManualPaymentId,
      label: label ?? this.label,
      providerName: providerName ?? this.providerName,
      providerAccountName: providerAccountName ?? this.providerAccountName,
      providerAccountNo: providerAccountNo ?? this.providerAccountNo,
      qrisImageUrl: qrisImageUrl ?? this.qrisImageUrl,
      qrisImageLocalPath: qrisImageLocalPath ?? this.qrisImageLocalPath,
      isActive: isActive ?? this.isActive,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localKey.present) {
      map['local_key'] = Variable<String>(localKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (serverManualPaymentId.present) {
      map['server_manual_payment_id'] = Variable<int>(
        serverManualPaymentId.value,
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (providerAccountName.present) {
      map['provider_account_name'] = Variable<String>(
        providerAccountName.value,
      );
    }
    if (providerAccountNo.present) {
      map['provider_account_no'] = Variable<String>(providerAccountNo.value);
    }
    if (qrisImageUrl.present) {
      map['qris_image_url'] = Variable<String>(qrisImageUrl.value);
    }
    if (qrisImageLocalPath.present) {
      map['qris_image_local_path'] = Variable<String>(qrisImageLocalPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('localKey: $localKey, ')
          ..write('kind: $kind, ')
          ..write('serverManualPaymentId: $serverManualPaymentId, ')
          ..write('label: $label, ')
          ..write('providerName: $providerName, ')
          ..write('providerAccountName: $providerAccountName, ')
          ..write('providerAccountNo: $providerAccountNo, ')
          ..write('qrisImageUrl: $qrisImageUrl, ')
          ..write('qrisImageLocalPath: $qrisImageLocalPath, ')
          ..write('isActive: $isActive, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPartnerSettingsTable extends CachedPartnerSettings
    with TableInfo<$CachedPartnerSettingsTable, CachedPartnerSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPartnerSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _partnerIdMeta = const VerificationMeta(
    'partnerId',
  );
  @override
  late final GeneratedColumn<int> partnerId = GeneratedColumn<int>(
    'partner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isQrActiveMeta = const VerificationMeta(
    'isQrActive',
  );
  @override
  late final GeneratedColumn<bool> isQrActive = GeneratedColumn<bool>(
    'is_qr_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_qr_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCashierActiveMeta = const VerificationMeta(
    'isCashierActive',
  );
  @override
  late final GeneratedColumn<bool> isCashierActive = GeneratedColumn<bool>(
    'is_cashier_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cashier_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOpenbillMeta = const VerificationMeta(
    'isOpenbill',
  );
  @override
  late final GeneratedColumn<bool> isOpenbill = GeneratedColumn<bool>(
    'is_openbill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_openbill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ppnMeta = const VerificationMeta('ppn');
  @override
  late final GeneratedColumn<double> ppn = GeneratedColumn<double>(
    'ppn',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPpnActiveMeta = const VerificationMeta(
    'isPpnActive',
  );
  @override
  late final GeneratedColumn<bool> isPpnActive = GeneratedColumn<bool>(
    'is_ppn_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ppn_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cashRoundingUnitMeta = const VerificationMeta(
    'cashRoundingUnit',
  );
  @override
  late final GeneratedColumn<int> cashRoundingUnit = GeneratedColumn<int>(
    'cash_rounding_unit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    partnerId,
    name,
    isQrActive,
    isCashierActive,
    isOpenbill,
    ppn,
    isPpnActive,
    cashRoundingUnit,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_partner_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPartnerSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('partner_id')) {
      context.handle(
        _partnerIdMeta,
        partnerId.isAcceptableOrUnknown(data['partner_id']!, _partnerIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_qr_active')) {
      context.handle(
        _isQrActiveMeta,
        isQrActive.isAcceptableOrUnknown(
          data['is_qr_active']!,
          _isQrActiveMeta,
        ),
      );
    }
    if (data.containsKey('is_cashier_active')) {
      context.handle(
        _isCashierActiveMeta,
        isCashierActive.isAcceptableOrUnknown(
          data['is_cashier_active']!,
          _isCashierActiveMeta,
        ),
      );
    }
    if (data.containsKey('is_openbill')) {
      context.handle(
        _isOpenbillMeta,
        isOpenbill.isAcceptableOrUnknown(data['is_openbill']!, _isOpenbillMeta),
      );
    }
    if (data.containsKey('ppn')) {
      context.handle(
        _ppnMeta,
        ppn.isAcceptableOrUnknown(data['ppn']!, _ppnMeta),
      );
    }
    if (data.containsKey('is_ppn_active')) {
      context.handle(
        _isPpnActiveMeta,
        isPpnActive.isAcceptableOrUnknown(
          data['is_ppn_active']!,
          _isPpnActiveMeta,
        ),
      );
    }
    if (data.containsKey('cash_rounding_unit')) {
      context.handle(
        _cashRoundingUnitMeta,
        cashRoundingUnit.isAcceptableOrUnknown(
          data['cash_rounding_unit']!,
          _cashRoundingUnitMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {partnerId};
  @override
  CachedPartnerSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPartnerSetting(
      partnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partner_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isQrActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_qr_active'],
      )!,
      isCashierActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cashier_active'],
      )!,
      isOpenbill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_openbill'],
      )!,
      ppn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn'],
      )!,
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      cashRoundingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_rounding_unit'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPartnerSettingsTable createAlias(String alias) {
    return $CachedPartnerSettingsTable(attachedDatabase, alias);
  }
}

class CachedPartnerSetting extends DataClass
    implements Insertable<CachedPartnerSetting> {
  final int partnerId;
  final String name;
  final bool isQrActive;
  final bool isCashierActive;
  final bool isOpenbill;
  final double ppn;
  final bool isPpnActive;
  final int cashRoundingUnit;
  final DateTime cachedAt;
  const CachedPartnerSetting({
    required this.partnerId,
    required this.name,
    required this.isQrActive,
    required this.isCashierActive,
    required this.isOpenbill,
    required this.ppn,
    required this.isPpnActive,
    required this.cashRoundingUnit,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['partner_id'] = Variable<int>(partnerId);
    map['name'] = Variable<String>(name);
    map['is_qr_active'] = Variable<bool>(isQrActive);
    map['is_cashier_active'] = Variable<bool>(isCashierActive);
    map['is_openbill'] = Variable<bool>(isOpenbill);
    map['ppn'] = Variable<double>(ppn);
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    map['cash_rounding_unit'] = Variable<int>(cashRoundingUnit);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPartnerSettingsCompanion toCompanion(bool nullToAbsent) {
    return CachedPartnerSettingsCompanion(
      partnerId: Value(partnerId),
      name: Value(name),
      isQrActive: Value(isQrActive),
      isCashierActive: Value(isCashierActive),
      isOpenbill: Value(isOpenbill),
      ppn: Value(ppn),
      isPpnActive: Value(isPpnActive),
      cashRoundingUnit: Value(cashRoundingUnit),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPartnerSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPartnerSetting(
      partnerId: serializer.fromJson<int>(json['partnerId']),
      name: serializer.fromJson<String>(json['name']),
      isQrActive: serializer.fromJson<bool>(json['isQrActive']),
      isCashierActive: serializer.fromJson<bool>(json['isCashierActive']),
      isOpenbill: serializer.fromJson<bool>(json['isOpenbill']),
      ppn: serializer.fromJson<double>(json['ppn']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      cashRoundingUnit: serializer.fromJson<int>(json['cashRoundingUnit']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'partnerId': serializer.toJson<int>(partnerId),
      'name': serializer.toJson<String>(name),
      'isQrActive': serializer.toJson<bool>(isQrActive),
      'isCashierActive': serializer.toJson<bool>(isCashierActive),
      'isOpenbill': serializer.toJson<bool>(isOpenbill),
      'ppn': serializer.toJson<double>(ppn),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'cashRoundingUnit': serializer.toJson<int>(cashRoundingUnit),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPartnerSetting copyWith({
    int? partnerId,
    String? name,
    bool? isQrActive,
    bool? isCashierActive,
    bool? isOpenbill,
    double? ppn,
    bool? isPpnActive,
    int? cashRoundingUnit,
    DateTime? cachedAt,
  }) => CachedPartnerSetting(
    partnerId: partnerId ?? this.partnerId,
    name: name ?? this.name,
    isQrActive: isQrActive ?? this.isQrActive,
    isCashierActive: isCashierActive ?? this.isCashierActive,
    isOpenbill: isOpenbill ?? this.isOpenbill,
    ppn: ppn ?? this.ppn,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    cashRoundingUnit: cashRoundingUnit ?? this.cashRoundingUnit,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPartnerSetting copyWithCompanion(CachedPartnerSettingsCompanion data) {
    return CachedPartnerSetting(
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      name: data.name.present ? data.name.value : this.name,
      isQrActive: data.isQrActive.present
          ? data.isQrActive.value
          : this.isQrActive,
      isCashierActive: data.isCashierActive.present
          ? data.isCashierActive.value
          : this.isCashierActive,
      isOpenbill: data.isOpenbill.present
          ? data.isOpenbill.value
          : this.isOpenbill,
      ppn: data.ppn.present ? data.ppn.value : this.ppn,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      cashRoundingUnit: data.cashRoundingUnit.present
          ? data.cashRoundingUnit.value
          : this.cashRoundingUnit,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPartnerSetting(')
          ..write('partnerId: $partnerId, ')
          ..write('name: $name, ')
          ..write('isQrActive: $isQrActive, ')
          ..write('isCashierActive: $isCashierActive, ')
          ..write('isOpenbill: $isOpenbill, ')
          ..write('ppn: $ppn, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('cashRoundingUnit: $cashRoundingUnit, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    partnerId,
    name,
    isQrActive,
    isCashierActive,
    isOpenbill,
    ppn,
    isPpnActive,
    cashRoundingUnit,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPartnerSetting &&
          other.partnerId == this.partnerId &&
          other.name == this.name &&
          other.isQrActive == this.isQrActive &&
          other.isCashierActive == this.isCashierActive &&
          other.isOpenbill == this.isOpenbill &&
          other.ppn == this.ppn &&
          other.isPpnActive == this.isPpnActive &&
          other.cashRoundingUnit == this.cashRoundingUnit &&
          other.cachedAt == this.cachedAt);
}

class CachedPartnerSettingsCompanion
    extends UpdateCompanion<CachedPartnerSetting> {
  final Value<int> partnerId;
  final Value<String> name;
  final Value<bool> isQrActive;
  final Value<bool> isCashierActive;
  final Value<bool> isOpenbill;
  final Value<double> ppn;
  final Value<bool> isPpnActive;
  final Value<int> cashRoundingUnit;
  final Value<DateTime> cachedAt;
  const CachedPartnerSettingsCompanion({
    this.partnerId = const Value.absent(),
    this.name = const Value.absent(),
    this.isQrActive = const Value.absent(),
    this.isCashierActive = const Value.absent(),
    this.isOpenbill = const Value.absent(),
    this.ppn = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.cashRoundingUnit = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedPartnerSettingsCompanion.insert({
    this.partnerId = const Value.absent(),
    required String name,
    this.isQrActive = const Value.absent(),
    this.isCashierActive = const Value.absent(),
    this.isOpenbill = const Value.absent(),
    this.ppn = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.cashRoundingUnit = const Value.absent(),
    required DateTime cachedAt,
  }) : name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedPartnerSetting> custom({
    Expression<int>? partnerId,
    Expression<String>? name,
    Expression<bool>? isQrActive,
    Expression<bool>? isCashierActive,
    Expression<bool>? isOpenbill,
    Expression<double>? ppn,
    Expression<bool>? isPpnActive,
    Expression<int>? cashRoundingUnit,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (partnerId != null) 'partner_id': partnerId,
      if (name != null) 'name': name,
      if (isQrActive != null) 'is_qr_active': isQrActive,
      if (isCashierActive != null) 'is_cashier_active': isCashierActive,
      if (isOpenbill != null) 'is_openbill': isOpenbill,
      if (ppn != null) 'ppn': ppn,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (cashRoundingUnit != null) 'cash_rounding_unit': cashRoundingUnit,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedPartnerSettingsCompanion copyWith({
    Value<int>? partnerId,
    Value<String>? name,
    Value<bool>? isQrActive,
    Value<bool>? isCashierActive,
    Value<bool>? isOpenbill,
    Value<double>? ppn,
    Value<bool>? isPpnActive,
    Value<int>? cashRoundingUnit,
    Value<DateTime>? cachedAt,
  }) {
    return CachedPartnerSettingsCompanion(
      partnerId: partnerId ?? this.partnerId,
      name: name ?? this.name,
      isQrActive: isQrActive ?? this.isQrActive,
      isCashierActive: isCashierActive ?? this.isCashierActive,
      isOpenbill: isOpenbill ?? this.isOpenbill,
      ppn: ppn ?? this.ppn,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      cashRoundingUnit: cashRoundingUnit ?? this.cashRoundingUnit,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (partnerId.present) {
      map['partner_id'] = Variable<int>(partnerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isQrActive.present) {
      map['is_qr_active'] = Variable<bool>(isQrActive.value);
    }
    if (isCashierActive.present) {
      map['is_cashier_active'] = Variable<bool>(isCashierActive.value);
    }
    if (isOpenbill.present) {
      map['is_openbill'] = Variable<bool>(isOpenbill.value);
    }
    if (ppn.present) {
      map['ppn'] = Variable<double>(ppn.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (cashRoundingUnit.present) {
      map['cash_rounding_unit'] = Variable<int>(cashRoundingUnit.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPartnerSettingsCompanion(')
          ..write('partnerId: $partnerId, ')
          ..write('name: $name, ')
          ..write('isQrActive: $isQrActive, ')
          ..write('isCashierActive: $isCashierActive, ')
          ..write('isOpenbill: $isOpenbill, ')
          ..write('ppn: $ppn, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('cashRoundingUnit: $cashRoundingUnit, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $BookingOrdersTable extends BookingOrders
    with TableInfo<$BookingOrdersTable, BookingOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingOrderCodeMeta = const VerificationMeta(
    'bookingOrderCode',
  );
  @override
  late final GeneratedColumn<String> bookingOrderCode = GeneratedColumn<String>(
    'booking_order_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partnerIdMeta = const VerificationMeta(
    'partnerId',
  );
  @override
  late final GeneratedColumn<int> partnerId = GeneratedColumn<int>(
    'partner_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partnerNameMeta = const VerificationMeta(
    'partnerName',
  );
  @override
  late final GeneratedColumn<String> partnerName = GeneratedColumn<String>(
    'partner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<int> tableId = GeneratedColumn<int>(
    'table_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableNoMeta = const VerificationMeta(
    'tableNo',
  );
  @override
  late final GeneratedColumn<String> tableNo = GeneratedColumn<String>(
    'table_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeOrderIdMeta = const VerificationMeta(
    'employeeOrderId',
  );
  @override
  late final GeneratedColumn<int> employeeOrderId = GeneratedColumn<int>(
    'employee_order_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderByMeta = const VerificationMeta(
    'orderBy',
  );
  @override
  late final GeneratedColumn<String> orderBy = GeneratedColumn<String>(
    'order_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('DRAFT'),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openbillFlagMeta = const VerificationMeta(
    'openbillFlag',
  );
  @override
  late final GeneratedColumn<bool> openbillFlag = GeneratedColumn<bool>(
    'openbill_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("openbill_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _discountIdMeta = const VerificationMeta(
    'discountId',
  );
  @override
  late final GeneratedColumn<int> discountId = GeneratedColumn<int>(
    'discount_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalOrderValueMeta = const VerificationMeta(
    'totalOrderValue',
  );
  @override
  late final GeneratedColumn<double> totalOrderValue = GeneratedColumn<double>(
    'total_order_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ppnMeta = const VerificationMeta('ppn');
  @override
  late final GeneratedColumn<double> ppn = GeneratedColumn<double>(
    'ppn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPpnActiveMeta = const VerificationMeta(
    'isPpnActive',
  );
  @override
  late final GeneratedColumn<bool> isPpnActive = GeneratedColumn<bool>(
    'is_ppn_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ppn_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customerOrderNoteMeta = const VerificationMeta(
    'customerOrderNote',
  );
  @override
  late final GeneratedColumn<String> customerOrderNote =
      GeneratedColumn<String>(
        'customer_order_note',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _employeeOrderNoteMeta = const VerificationMeta(
    'employeeOrderNote',
  );
  @override
  late final GeneratedColumn<String> employeeOrderNote =
      GeneratedColumn<String>(
        'employee_order_note',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashierProcessIdMeta = const VerificationMeta(
    'cashierProcessId',
  );
  @override
  late final GeneratedColumn<int> cashierProcessId = GeneratedColumn<int>(
    'cashier_process_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kitchenProcessIdMeta = const VerificationMeta(
    'kitchenProcessId',
  );
  @override
  late final GeneratedColumn<int> kitchenProcessId = GeneratedColumn<int>(
    'kitchen_process_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentIdMeta = const VerificationMeta(
    'paymentId',
  );
  @override
  late final GeneratedColumn<int> paymentId = GeneratedColumn<int>(
    'payment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentFlagMeta = const VerificationMeta(
    'paymentFlag',
  );
  @override
  late final GeneratedColumn<bool> paymentFlag = GeneratedColumn<bool>(
    'payment_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("payment_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wifiSnapshotJsonMeta = const VerificationMeta(
    'wifiSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> wifiSnapshotJson = GeneratedColumn<String>(
    'wifi_snapshot_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentRequestJsonMeta =
      const VerificationMeta('paymentRequestJson');
  @override
  late final GeneratedColumn<String> paymentRequestJson =
      GeneratedColumn<String>(
        'payment_request_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestPaymentJsonMeta = const VerificationMeta(
    'latestPaymentJson',
  );
  @override
  late final GeneratedColumn<String> latestPaymentJson =
      GeneratedColumn<String>(
        'latest_payment_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncDirtyMeta = const VerificationMeta(
    'syncDirty',
  );
  @override
  late final GeneratedColumn<bool> syncDirty = GeneratedColumn<bool>(
    'sync_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncIntentMeta = const VerificationMeta(
    'syncIntent',
  );
  @override
  late final GeneratedColumn<String> syncIntent = GeneratedColumn<String>(
    'sync_intent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localFilePathsJsonMeta =
      const VerificationMeta('localFilePathsJson');
  @override
  late final GeneratedColumn<String> localFilePathsJson =
      GeneratedColumn<String>(
        'local_file_paths_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paidAmountLocalMeta = const VerificationMeta(
    'paidAmountLocal',
  );
  @override
  late final GeneratedColumn<double> paidAmountLocal = GeneratedColumn<double>(
    'paid_amount_local',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeAmountLocalMeta = const VerificationMeta(
    'changeAmountLocal',
  );
  @override
  late final GeneratedColumn<double> changeAmountLocal =
      GeneratedColumn<double>(
        'change_amount_local',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashRoundingAmountMeta =
      const VerificationMeta('cashRoundingAmount');
  @override
  late final GeneratedColumn<double> cashRoundingAmount =
      GeneratedColumn<double>(
        'cash_rounding_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cashRoundingUnitMeta = const VerificationMeta(
    'cashRoundingUnit',
  );
  @override
  late final GeneratedColumn<int> cashRoundingUnit = GeneratedColumn<int>(
    'cash_rounding_unit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestPaymentServerIdMeta =
      const VerificationMeta('latestPaymentServerId');
  @override
  late final GeneratedColumn<int> latestPaymentServerId = GeneratedColumn<int>(
    'latest_payment_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientUuid,
    serverId,
    bookingOrderCode,
    partnerId,
    partnerName,
    tableId,
    tableNo,
    customerId,
    employeeOrderId,
    orderBy,
    customerName,
    orderStatus,
    paymentMethod,
    openbillFlag,
    discountId,
    discountValue,
    totalOrderValue,
    ppn,
    isPpnActive,
    customerOrderNote,
    employeeOrderNote,
    cashierProcessId,
    kitchenProcessId,
    paymentId,
    paymentFlag,
    wifiSnapshotJson,
    paymentRequestJson,
    latestPaymentJson,
    syncVersion,
    syncDirty,
    syncIntent,
    syncError,
    localFilePathsJson,
    paidAmountLocal,
    changeAmountLocal,
    cashRoundingAmount,
    cashRoundingUnit,
    latestPaymentServerId,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'booking_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookingOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('booking_order_code')) {
      context.handle(
        _bookingOrderCodeMeta,
        bookingOrderCode.isAcceptableOrUnknown(
          data['booking_order_code']!,
          _bookingOrderCodeMeta,
        ),
      );
    }
    if (data.containsKey('partner_id')) {
      context.handle(
        _partnerIdMeta,
        partnerId.isAcceptableOrUnknown(data['partner_id']!, _partnerIdMeta),
      );
    }
    if (data.containsKey('partner_name')) {
      context.handle(
        _partnerNameMeta,
        partnerName.isAcceptableOrUnknown(
          data['partner_name']!,
          _partnerNameMeta,
        ),
      );
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('table_no')) {
      context.handle(
        _tableNoMeta,
        tableNo.isAcceptableOrUnknown(data['table_no']!, _tableNoMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('employee_order_id')) {
      context.handle(
        _employeeOrderIdMeta,
        employeeOrderId.isAcceptableOrUnknown(
          data['employee_order_id']!,
          _employeeOrderIdMeta,
        ),
      );
    }
    if (data.containsKey('order_by')) {
      context.handle(
        _orderByMeta,
        orderBy.isAcceptableOrUnknown(data['order_by']!, _orderByMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('openbill_flag')) {
      context.handle(
        _openbillFlagMeta,
        openbillFlag.isAcceptableOrUnknown(
          data['openbill_flag']!,
          _openbillFlagMeta,
        ),
      );
    }
    if (data.containsKey('discount_id')) {
      context.handle(
        _discountIdMeta,
        discountId.isAcceptableOrUnknown(data['discount_id']!, _discountIdMeta),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('total_order_value')) {
      context.handle(
        _totalOrderValueMeta,
        totalOrderValue.isAcceptableOrUnknown(
          data['total_order_value']!,
          _totalOrderValueMeta,
        ),
      );
    }
    if (data.containsKey('ppn')) {
      context.handle(
        _ppnMeta,
        ppn.isAcceptableOrUnknown(data['ppn']!, _ppnMeta),
      );
    }
    if (data.containsKey('is_ppn_active')) {
      context.handle(
        _isPpnActiveMeta,
        isPpnActive.isAcceptableOrUnknown(
          data['is_ppn_active']!,
          _isPpnActiveMeta,
        ),
      );
    }
    if (data.containsKey('customer_order_note')) {
      context.handle(
        _customerOrderNoteMeta,
        customerOrderNote.isAcceptableOrUnknown(
          data['customer_order_note']!,
          _customerOrderNoteMeta,
        ),
      );
    }
    if (data.containsKey('employee_order_note')) {
      context.handle(
        _employeeOrderNoteMeta,
        employeeOrderNote.isAcceptableOrUnknown(
          data['employee_order_note']!,
          _employeeOrderNoteMeta,
        ),
      );
    }
    if (data.containsKey('cashier_process_id')) {
      context.handle(
        _cashierProcessIdMeta,
        cashierProcessId.isAcceptableOrUnknown(
          data['cashier_process_id']!,
          _cashierProcessIdMeta,
        ),
      );
    }
    if (data.containsKey('kitchen_process_id')) {
      context.handle(
        _kitchenProcessIdMeta,
        kitchenProcessId.isAcceptableOrUnknown(
          data['kitchen_process_id']!,
          _kitchenProcessIdMeta,
        ),
      );
    }
    if (data.containsKey('payment_id')) {
      context.handle(
        _paymentIdMeta,
        paymentId.isAcceptableOrUnknown(data['payment_id']!, _paymentIdMeta),
      );
    }
    if (data.containsKey('payment_flag')) {
      context.handle(
        _paymentFlagMeta,
        paymentFlag.isAcceptableOrUnknown(
          data['payment_flag']!,
          _paymentFlagMeta,
        ),
      );
    }
    if (data.containsKey('wifi_snapshot_json')) {
      context.handle(
        _wifiSnapshotJsonMeta,
        wifiSnapshotJson.isAcceptableOrUnknown(
          data['wifi_snapshot_json']!,
          _wifiSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('payment_request_json')) {
      context.handle(
        _paymentRequestJsonMeta,
        paymentRequestJson.isAcceptableOrUnknown(
          data['payment_request_json']!,
          _paymentRequestJsonMeta,
        ),
      );
    }
    if (data.containsKey('latest_payment_json')) {
      context.handle(
        _latestPaymentJsonMeta,
        latestPaymentJson.isAcceptableOrUnknown(
          data['latest_payment_json']!,
          _latestPaymentJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_dirty')) {
      context.handle(
        _syncDirtyMeta,
        syncDirty.isAcceptableOrUnknown(data['sync_dirty']!, _syncDirtyMeta),
      );
    }
    if (data.containsKey('sync_intent')) {
      context.handle(
        _syncIntentMeta,
        syncIntent.isAcceptableOrUnknown(data['sync_intent']!, _syncIntentMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_file_paths_json')) {
      context.handle(
        _localFilePathsJsonMeta,
        localFilePathsJson.isAcceptableOrUnknown(
          data['local_file_paths_json']!,
          _localFilePathsJsonMeta,
        ),
      );
    }
    if (data.containsKey('paid_amount_local')) {
      context.handle(
        _paidAmountLocalMeta,
        paidAmountLocal.isAcceptableOrUnknown(
          data['paid_amount_local']!,
          _paidAmountLocalMeta,
        ),
      );
    }
    if (data.containsKey('change_amount_local')) {
      context.handle(
        _changeAmountLocalMeta,
        changeAmountLocal.isAcceptableOrUnknown(
          data['change_amount_local']!,
          _changeAmountLocalMeta,
        ),
      );
    }
    if (data.containsKey('cash_rounding_amount')) {
      context.handle(
        _cashRoundingAmountMeta,
        cashRoundingAmount.isAcceptableOrUnknown(
          data['cash_rounding_amount']!,
          _cashRoundingAmountMeta,
        ),
      );
    }
    if (data.containsKey('cash_rounding_unit')) {
      context.handle(
        _cashRoundingUnitMeta,
        cashRoundingUnit.isAcceptableOrUnknown(
          data['cash_rounding_unit']!,
          _cashRoundingUnitMeta,
        ),
      );
    }
    if (data.containsKey('latest_payment_server_id')) {
      context.handle(
        _latestPaymentServerIdMeta,
        latestPaymentServerId.isAcceptableOrUnknown(
          data['latest_payment_server_id']!,
          _latestPaymentServerIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  BookingOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookingOrder(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      bookingOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_code'],
      ),
      partnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partner_id'],
      ),
      partnerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partner_name'],
      ),
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}table_id'],
      ),
      tableNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      ),
      employeeOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employee_order_id'],
      ),
      orderBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_by'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      openbillFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}openbill_flag'],
      )!,
      discountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_id'],
      ),
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      )!,
      totalOrderValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_order_value'],
      )!,
      ppn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn'],
      ),
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      customerOrderNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_order_note'],
      ),
      employeeOrderNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_order_note'],
      ),
      cashierProcessId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cashier_process_id'],
      ),
      kitchenProcessId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kitchen_process_id'],
      ),
      paymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_id'],
      ),
      paymentFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}payment_flag'],
      )!,
      wifiSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wifi_snapshot_json'],
      ),
      paymentRequestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_request_json'],
      ),
      latestPaymentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_payment_json'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      syncDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_dirty'],
      )!,
      syncIntent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_intent'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localFilePathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_paths_json'],
      ),
      paidAmountLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount_local'],
      ),
      changeAmountLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change_amount_local'],
      ),
      cashRoundingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_rounding_amount'],
      ),
      cashRoundingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_rounding_unit'],
      ),
      latestPaymentServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_payment_server_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $BookingOrdersTable createAlias(String alias) {
    return $BookingOrdersTable(attachedDatabase, alias);
  }
}

class BookingOrder extends DataClass implements Insertable<BookingOrder> {
  final String clientUuid;
  final int? serverId;
  final String? bookingOrderCode;
  final int? partnerId;
  final String? partnerName;
  final int? tableId;
  final String? tableNo;
  final int? customerId;
  final int? employeeOrderId;
  final String? orderBy;
  final String customerName;
  final String orderStatus;
  final String? paymentMethod;
  final bool openbillFlag;
  final int? discountId;
  final double discountValue;
  final double totalOrderValue;
  final double? ppn;
  final bool isPpnActive;
  final String? customerOrderNote;
  final String? employeeOrderNote;
  final int? cashierProcessId;
  final int? kitchenProcessId;
  final int? paymentId;
  final bool paymentFlag;
  final String? wifiSnapshotJson;
  final String? paymentRequestJson;
  final String? latestPaymentJson;
  final int syncVersion;
  final bool syncDirty;
  final String? syncIntent;
  final String? syncError;
  final String? localFilePathsJson;
  final double? paidAmountLocal;
  final double? changeAmountLocal;
  final double? cashRoundingAmount;
  final int? cashRoundingUnit;
  final int? latestPaymentServerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  const BookingOrder({
    required this.clientUuid,
    this.serverId,
    this.bookingOrderCode,
    this.partnerId,
    this.partnerName,
    this.tableId,
    this.tableNo,
    this.customerId,
    this.employeeOrderId,
    this.orderBy,
    required this.customerName,
    required this.orderStatus,
    this.paymentMethod,
    required this.openbillFlag,
    this.discountId,
    required this.discountValue,
    required this.totalOrderValue,
    this.ppn,
    required this.isPpnActive,
    this.customerOrderNote,
    this.employeeOrderNote,
    this.cashierProcessId,
    this.kitchenProcessId,
    this.paymentId,
    required this.paymentFlag,
    this.wifiSnapshotJson,
    this.paymentRequestJson,
    this.latestPaymentJson,
    required this.syncVersion,
    required this.syncDirty,
    this.syncIntent,
    this.syncError,
    this.localFilePathsJson,
    this.paidAmountLocal,
    this.changeAmountLocal,
    this.cashRoundingAmount,
    this.cashRoundingUnit,
    this.latestPaymentServerId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || bookingOrderCode != null) {
      map['booking_order_code'] = Variable<String>(bookingOrderCode);
    }
    if (!nullToAbsent || partnerId != null) {
      map['partner_id'] = Variable<int>(partnerId);
    }
    if (!nullToAbsent || partnerName != null) {
      map['partner_name'] = Variable<String>(partnerName);
    }
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<int>(tableId);
    }
    if (!nullToAbsent || tableNo != null) {
      map['table_no'] = Variable<String>(tableNo);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || employeeOrderId != null) {
      map['employee_order_id'] = Variable<int>(employeeOrderId);
    }
    if (!nullToAbsent || orderBy != null) {
      map['order_by'] = Variable<String>(orderBy);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['order_status'] = Variable<String>(orderStatus);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['openbill_flag'] = Variable<bool>(openbillFlag);
    if (!nullToAbsent || discountId != null) {
      map['discount_id'] = Variable<int>(discountId);
    }
    map['discount_value'] = Variable<double>(discountValue);
    map['total_order_value'] = Variable<double>(totalOrderValue);
    if (!nullToAbsent || ppn != null) {
      map['ppn'] = Variable<double>(ppn);
    }
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    if (!nullToAbsent || customerOrderNote != null) {
      map['customer_order_note'] = Variable<String>(customerOrderNote);
    }
    if (!nullToAbsent || employeeOrderNote != null) {
      map['employee_order_note'] = Variable<String>(employeeOrderNote);
    }
    if (!nullToAbsent || cashierProcessId != null) {
      map['cashier_process_id'] = Variable<int>(cashierProcessId);
    }
    if (!nullToAbsent || kitchenProcessId != null) {
      map['kitchen_process_id'] = Variable<int>(kitchenProcessId);
    }
    if (!nullToAbsent || paymentId != null) {
      map['payment_id'] = Variable<int>(paymentId);
    }
    map['payment_flag'] = Variable<bool>(paymentFlag);
    if (!nullToAbsent || wifiSnapshotJson != null) {
      map['wifi_snapshot_json'] = Variable<String>(wifiSnapshotJson);
    }
    if (!nullToAbsent || paymentRequestJson != null) {
      map['payment_request_json'] = Variable<String>(paymentRequestJson);
    }
    if (!nullToAbsent || latestPaymentJson != null) {
      map['latest_payment_json'] = Variable<String>(latestPaymentJson);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    map['sync_dirty'] = Variable<bool>(syncDirty);
    if (!nullToAbsent || syncIntent != null) {
      map['sync_intent'] = Variable<String>(syncIntent);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    if (!nullToAbsent || localFilePathsJson != null) {
      map['local_file_paths_json'] = Variable<String>(localFilePathsJson);
    }
    if (!nullToAbsent || paidAmountLocal != null) {
      map['paid_amount_local'] = Variable<double>(paidAmountLocal);
    }
    if (!nullToAbsent || changeAmountLocal != null) {
      map['change_amount_local'] = Variable<double>(changeAmountLocal);
    }
    if (!nullToAbsent || cashRoundingAmount != null) {
      map['cash_rounding_amount'] = Variable<double>(cashRoundingAmount);
    }
    if (!nullToAbsent || cashRoundingUnit != null) {
      map['cash_rounding_unit'] = Variable<int>(cashRoundingUnit);
    }
    if (!nullToAbsent || latestPaymentServerId != null) {
      map['latest_payment_server_id'] = Variable<int>(latestPaymentServerId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  BookingOrdersCompanion toCompanion(bool nullToAbsent) {
    return BookingOrdersCompanion(
      clientUuid: Value(clientUuid),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      bookingOrderCode: bookingOrderCode == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingOrderCode),
      partnerId: partnerId == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerId),
      partnerName: partnerName == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerName),
      tableId: tableId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableId),
      tableNo: tableNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNo),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      employeeOrderId: employeeOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeOrderId),
      orderBy: orderBy == null && nullToAbsent
          ? const Value.absent()
          : Value(orderBy),
      customerName: Value(customerName),
      orderStatus: Value(orderStatus),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      openbillFlag: Value(openbillFlag),
      discountId: discountId == null && nullToAbsent
          ? const Value.absent()
          : Value(discountId),
      discountValue: Value(discountValue),
      totalOrderValue: Value(totalOrderValue),
      ppn: ppn == null && nullToAbsent ? const Value.absent() : Value(ppn),
      isPpnActive: Value(isPpnActive),
      customerOrderNote: customerOrderNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customerOrderNote),
      employeeOrderNote: employeeOrderNote == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeOrderNote),
      cashierProcessId: cashierProcessId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierProcessId),
      kitchenProcessId: kitchenProcessId == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenProcessId),
      paymentId: paymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentId),
      paymentFlag: Value(paymentFlag),
      wifiSnapshotJson: wifiSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(wifiSnapshotJson),
      paymentRequestJson: paymentRequestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentRequestJson),
      latestPaymentJson: latestPaymentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestPaymentJson),
      syncVersion: Value(syncVersion),
      syncDirty: Value(syncDirty),
      syncIntent: syncIntent == null && nullToAbsent
          ? const Value.absent()
          : Value(syncIntent),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localFilePathsJson: localFilePathsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePathsJson),
      paidAmountLocal: paidAmountLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAmountLocal),
      changeAmountLocal: changeAmountLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(changeAmountLocal),
      cashRoundingAmount: cashRoundingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(cashRoundingAmount),
      cashRoundingUnit: cashRoundingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(cashRoundingUnit),
      latestPaymentServerId: latestPaymentServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(latestPaymentServerId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory BookingOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookingOrder(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      bookingOrderCode: serializer.fromJson<String?>(json['bookingOrderCode']),
      partnerId: serializer.fromJson<int?>(json['partnerId']),
      partnerName: serializer.fromJson<String?>(json['partnerName']),
      tableId: serializer.fromJson<int?>(json['tableId']),
      tableNo: serializer.fromJson<String?>(json['tableNo']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      employeeOrderId: serializer.fromJson<int?>(json['employeeOrderId']),
      orderBy: serializer.fromJson<String?>(json['orderBy']),
      customerName: serializer.fromJson<String>(json['customerName']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      openbillFlag: serializer.fromJson<bool>(json['openbillFlag']),
      discountId: serializer.fromJson<int?>(json['discountId']),
      discountValue: serializer.fromJson<double>(json['discountValue']),
      totalOrderValue: serializer.fromJson<double>(json['totalOrderValue']),
      ppn: serializer.fromJson<double?>(json['ppn']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      customerOrderNote: serializer.fromJson<String?>(
        json['customerOrderNote'],
      ),
      employeeOrderNote: serializer.fromJson<String?>(
        json['employeeOrderNote'],
      ),
      cashierProcessId: serializer.fromJson<int?>(json['cashierProcessId']),
      kitchenProcessId: serializer.fromJson<int?>(json['kitchenProcessId']),
      paymentId: serializer.fromJson<int?>(json['paymentId']),
      paymentFlag: serializer.fromJson<bool>(json['paymentFlag']),
      wifiSnapshotJson: serializer.fromJson<String?>(json['wifiSnapshotJson']),
      paymentRequestJson: serializer.fromJson<String?>(
        json['paymentRequestJson'],
      ),
      latestPaymentJson: serializer.fromJson<String?>(
        json['latestPaymentJson'],
      ),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      syncDirty: serializer.fromJson<bool>(json['syncDirty']),
      syncIntent: serializer.fromJson<String?>(json['syncIntent']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localFilePathsJson: serializer.fromJson<String?>(
        json['localFilePathsJson'],
      ),
      paidAmountLocal: serializer.fromJson<double?>(json['paidAmountLocal']),
      changeAmountLocal: serializer.fromJson<double?>(
        json['changeAmountLocal'],
      ),
      cashRoundingAmount: serializer.fromJson<double?>(
        json['cashRoundingAmount'],
      ),
      cashRoundingUnit: serializer.fromJson<int?>(json['cashRoundingUnit']),
      latestPaymentServerId: serializer.fromJson<int?>(
        json['latestPaymentServerId'],
      ),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'serverId': serializer.toJson<int?>(serverId),
      'bookingOrderCode': serializer.toJson<String?>(bookingOrderCode),
      'partnerId': serializer.toJson<int?>(partnerId),
      'partnerName': serializer.toJson<String?>(partnerName),
      'tableId': serializer.toJson<int?>(tableId),
      'tableNo': serializer.toJson<String?>(tableNo),
      'customerId': serializer.toJson<int?>(customerId),
      'employeeOrderId': serializer.toJson<int?>(employeeOrderId),
      'orderBy': serializer.toJson<String?>(orderBy),
      'customerName': serializer.toJson<String>(customerName),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'openbillFlag': serializer.toJson<bool>(openbillFlag),
      'discountId': serializer.toJson<int?>(discountId),
      'discountValue': serializer.toJson<double>(discountValue),
      'totalOrderValue': serializer.toJson<double>(totalOrderValue),
      'ppn': serializer.toJson<double?>(ppn),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'customerOrderNote': serializer.toJson<String?>(customerOrderNote),
      'employeeOrderNote': serializer.toJson<String?>(employeeOrderNote),
      'cashierProcessId': serializer.toJson<int?>(cashierProcessId),
      'kitchenProcessId': serializer.toJson<int?>(kitchenProcessId),
      'paymentId': serializer.toJson<int?>(paymentId),
      'paymentFlag': serializer.toJson<bool>(paymentFlag),
      'wifiSnapshotJson': serializer.toJson<String?>(wifiSnapshotJson),
      'paymentRequestJson': serializer.toJson<String?>(paymentRequestJson),
      'latestPaymentJson': serializer.toJson<String?>(latestPaymentJson),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'syncDirty': serializer.toJson<bool>(syncDirty),
      'syncIntent': serializer.toJson<String?>(syncIntent),
      'syncError': serializer.toJson<String?>(syncError),
      'localFilePathsJson': serializer.toJson<String?>(localFilePathsJson),
      'paidAmountLocal': serializer.toJson<double?>(paidAmountLocal),
      'changeAmountLocal': serializer.toJson<double?>(changeAmountLocal),
      'cashRoundingAmount': serializer.toJson<double?>(cashRoundingAmount),
      'cashRoundingUnit': serializer.toJson<int?>(cashRoundingUnit),
      'latestPaymentServerId': serializer.toJson<int?>(latestPaymentServerId),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  BookingOrder copyWith({
    String? clientUuid,
    Value<int?> serverId = const Value.absent(),
    Value<String?> bookingOrderCode = const Value.absent(),
    Value<int?> partnerId = const Value.absent(),
    Value<String?> partnerName = const Value.absent(),
    Value<int?> tableId = const Value.absent(),
    Value<String?> tableNo = const Value.absent(),
    Value<int?> customerId = const Value.absent(),
    Value<int?> employeeOrderId = const Value.absent(),
    Value<String?> orderBy = const Value.absent(),
    String? customerName,
    String? orderStatus,
    Value<String?> paymentMethod = const Value.absent(),
    bool? openbillFlag,
    Value<int?> discountId = const Value.absent(),
    double? discountValue,
    double? totalOrderValue,
    Value<double?> ppn = const Value.absent(),
    bool? isPpnActive,
    Value<String?> customerOrderNote = const Value.absent(),
    Value<String?> employeeOrderNote = const Value.absent(),
    Value<int?> cashierProcessId = const Value.absent(),
    Value<int?> kitchenProcessId = const Value.absent(),
    Value<int?> paymentId = const Value.absent(),
    bool? paymentFlag,
    Value<String?> wifiSnapshotJson = const Value.absent(),
    Value<String?> paymentRequestJson = const Value.absent(),
    Value<String?> latestPaymentJson = const Value.absent(),
    int? syncVersion,
    bool? syncDirty,
    Value<String?> syncIntent = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    Value<String?> localFilePathsJson = const Value.absent(),
    Value<double?> paidAmountLocal = const Value.absent(),
    Value<double?> changeAmountLocal = const Value.absent(),
    Value<double?> cashRoundingAmount = const Value.absent(),
    Value<int?> cashRoundingUnit = const Value.absent(),
    Value<int?> latestPaymentServerId = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => BookingOrder(
    clientUuid: clientUuid ?? this.clientUuid,
    serverId: serverId.present ? serverId.value : this.serverId,
    bookingOrderCode: bookingOrderCode.present
        ? bookingOrderCode.value
        : this.bookingOrderCode,
    partnerId: partnerId.present ? partnerId.value : this.partnerId,
    partnerName: partnerName.present ? partnerName.value : this.partnerName,
    tableId: tableId.present ? tableId.value : this.tableId,
    tableNo: tableNo.present ? tableNo.value : this.tableNo,
    customerId: customerId.present ? customerId.value : this.customerId,
    employeeOrderId: employeeOrderId.present
        ? employeeOrderId.value
        : this.employeeOrderId,
    orderBy: orderBy.present ? orderBy.value : this.orderBy,
    customerName: customerName ?? this.customerName,
    orderStatus: orderStatus ?? this.orderStatus,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    openbillFlag: openbillFlag ?? this.openbillFlag,
    discountId: discountId.present ? discountId.value : this.discountId,
    discountValue: discountValue ?? this.discountValue,
    totalOrderValue: totalOrderValue ?? this.totalOrderValue,
    ppn: ppn.present ? ppn.value : this.ppn,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    customerOrderNote: customerOrderNote.present
        ? customerOrderNote.value
        : this.customerOrderNote,
    employeeOrderNote: employeeOrderNote.present
        ? employeeOrderNote.value
        : this.employeeOrderNote,
    cashierProcessId: cashierProcessId.present
        ? cashierProcessId.value
        : this.cashierProcessId,
    kitchenProcessId: kitchenProcessId.present
        ? kitchenProcessId.value
        : this.kitchenProcessId,
    paymentId: paymentId.present ? paymentId.value : this.paymentId,
    paymentFlag: paymentFlag ?? this.paymentFlag,
    wifiSnapshotJson: wifiSnapshotJson.present
        ? wifiSnapshotJson.value
        : this.wifiSnapshotJson,
    paymentRequestJson: paymentRequestJson.present
        ? paymentRequestJson.value
        : this.paymentRequestJson,
    latestPaymentJson: latestPaymentJson.present
        ? latestPaymentJson.value
        : this.latestPaymentJson,
    syncVersion: syncVersion ?? this.syncVersion,
    syncDirty: syncDirty ?? this.syncDirty,
    syncIntent: syncIntent.present ? syncIntent.value : this.syncIntent,
    syncError: syncError.present ? syncError.value : this.syncError,
    localFilePathsJson: localFilePathsJson.present
        ? localFilePathsJson.value
        : this.localFilePathsJson,
    paidAmountLocal: paidAmountLocal.present
        ? paidAmountLocal.value
        : this.paidAmountLocal,
    changeAmountLocal: changeAmountLocal.present
        ? changeAmountLocal.value
        : this.changeAmountLocal,
    cashRoundingAmount: cashRoundingAmount.present
        ? cashRoundingAmount.value
        : this.cashRoundingAmount,
    cashRoundingUnit: cashRoundingUnit.present
        ? cashRoundingUnit.value
        : this.cashRoundingUnit,
    latestPaymentServerId: latestPaymentServerId.present
        ? latestPaymentServerId.value
        : this.latestPaymentServerId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  BookingOrder copyWithCompanion(BookingOrdersCompanion data) {
    return BookingOrder(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderCode: data.bookingOrderCode.present
          ? data.bookingOrderCode.value
          : this.bookingOrderCode,
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      partnerName: data.partnerName.present
          ? data.partnerName.value
          : this.partnerName,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      tableNo: data.tableNo.present ? data.tableNo.value : this.tableNo,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      employeeOrderId: data.employeeOrderId.present
          ? data.employeeOrderId.value
          : this.employeeOrderId,
      orderBy: data.orderBy.present ? data.orderBy.value : this.orderBy,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      openbillFlag: data.openbillFlag.present
          ? data.openbillFlag.value
          : this.openbillFlag,
      discountId: data.discountId.present
          ? data.discountId.value
          : this.discountId,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      totalOrderValue: data.totalOrderValue.present
          ? data.totalOrderValue.value
          : this.totalOrderValue,
      ppn: data.ppn.present ? data.ppn.value : this.ppn,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      customerOrderNote: data.customerOrderNote.present
          ? data.customerOrderNote.value
          : this.customerOrderNote,
      employeeOrderNote: data.employeeOrderNote.present
          ? data.employeeOrderNote.value
          : this.employeeOrderNote,
      cashierProcessId: data.cashierProcessId.present
          ? data.cashierProcessId.value
          : this.cashierProcessId,
      kitchenProcessId: data.kitchenProcessId.present
          ? data.kitchenProcessId.value
          : this.kitchenProcessId,
      paymentId: data.paymentId.present ? data.paymentId.value : this.paymentId,
      paymentFlag: data.paymentFlag.present
          ? data.paymentFlag.value
          : this.paymentFlag,
      wifiSnapshotJson: data.wifiSnapshotJson.present
          ? data.wifiSnapshotJson.value
          : this.wifiSnapshotJson,
      paymentRequestJson: data.paymentRequestJson.present
          ? data.paymentRequestJson.value
          : this.paymentRequestJson,
      latestPaymentJson: data.latestPaymentJson.present
          ? data.latestPaymentJson.value
          : this.latestPaymentJson,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      syncDirty: data.syncDirty.present ? data.syncDirty.value : this.syncDirty,
      syncIntent: data.syncIntent.present
          ? data.syncIntent.value
          : this.syncIntent,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localFilePathsJson: data.localFilePathsJson.present
          ? data.localFilePathsJson.value
          : this.localFilePathsJson,
      paidAmountLocal: data.paidAmountLocal.present
          ? data.paidAmountLocal.value
          : this.paidAmountLocal,
      changeAmountLocal: data.changeAmountLocal.present
          ? data.changeAmountLocal.value
          : this.changeAmountLocal,
      cashRoundingAmount: data.cashRoundingAmount.present
          ? data.cashRoundingAmount.value
          : this.cashRoundingAmount,
      cashRoundingUnit: data.cashRoundingUnit.present
          ? data.cashRoundingUnit.value
          : this.cashRoundingUnit,
      latestPaymentServerId: data.latestPaymentServerId.present
          ? data.latestPaymentServerId.value
          : this.latestPaymentServerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookingOrder(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('partnerName: $partnerName, ')
          ..write('tableId: $tableId, ')
          ..write('tableNo: $tableNo, ')
          ..write('customerId: $customerId, ')
          ..write('employeeOrderId: $employeeOrderId, ')
          ..write('orderBy: $orderBy, ')
          ..write('customerName: $customerName, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('openbillFlag: $openbillFlag, ')
          ..write('discountId: $discountId, ')
          ..write('discountValue: $discountValue, ')
          ..write('totalOrderValue: $totalOrderValue, ')
          ..write('ppn: $ppn, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('customerOrderNote: $customerOrderNote, ')
          ..write('employeeOrderNote: $employeeOrderNote, ')
          ..write('cashierProcessId: $cashierProcessId, ')
          ..write('kitchenProcessId: $kitchenProcessId, ')
          ..write('paymentId: $paymentId, ')
          ..write('paymentFlag: $paymentFlag, ')
          ..write('wifiSnapshotJson: $wifiSnapshotJson, ')
          ..write('paymentRequestJson: $paymentRequestJson, ')
          ..write('latestPaymentJson: $latestPaymentJson, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('syncIntent: $syncIntent, ')
          ..write('syncError: $syncError, ')
          ..write('localFilePathsJson: $localFilePathsJson, ')
          ..write('paidAmountLocal: $paidAmountLocal, ')
          ..write('changeAmountLocal: $changeAmountLocal, ')
          ..write('cashRoundingAmount: $cashRoundingAmount, ')
          ..write('cashRoundingUnit: $cashRoundingUnit, ')
          ..write('latestPaymentServerId: $latestPaymentServerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    clientUuid,
    serverId,
    bookingOrderCode,
    partnerId,
    partnerName,
    tableId,
    tableNo,
    customerId,
    employeeOrderId,
    orderBy,
    customerName,
    orderStatus,
    paymentMethod,
    openbillFlag,
    discountId,
    discountValue,
    totalOrderValue,
    ppn,
    isPpnActive,
    customerOrderNote,
    employeeOrderNote,
    cashierProcessId,
    kitchenProcessId,
    paymentId,
    paymentFlag,
    wifiSnapshotJson,
    paymentRequestJson,
    latestPaymentJson,
    syncVersion,
    syncDirty,
    syncIntent,
    syncError,
    localFilePathsJson,
    paidAmountLocal,
    changeAmountLocal,
    cashRoundingAmount,
    cashRoundingUnit,
    latestPaymentServerId,
    createdAt,
    updatedAt,
    deletedAt,
    syncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookingOrder &&
          other.clientUuid == this.clientUuid &&
          other.serverId == this.serverId &&
          other.bookingOrderCode == this.bookingOrderCode &&
          other.partnerId == this.partnerId &&
          other.partnerName == this.partnerName &&
          other.tableId == this.tableId &&
          other.tableNo == this.tableNo &&
          other.customerId == this.customerId &&
          other.employeeOrderId == this.employeeOrderId &&
          other.orderBy == this.orderBy &&
          other.customerName == this.customerName &&
          other.orderStatus == this.orderStatus &&
          other.paymentMethod == this.paymentMethod &&
          other.openbillFlag == this.openbillFlag &&
          other.discountId == this.discountId &&
          other.discountValue == this.discountValue &&
          other.totalOrderValue == this.totalOrderValue &&
          other.ppn == this.ppn &&
          other.isPpnActive == this.isPpnActive &&
          other.customerOrderNote == this.customerOrderNote &&
          other.employeeOrderNote == this.employeeOrderNote &&
          other.cashierProcessId == this.cashierProcessId &&
          other.kitchenProcessId == this.kitchenProcessId &&
          other.paymentId == this.paymentId &&
          other.paymentFlag == this.paymentFlag &&
          other.wifiSnapshotJson == this.wifiSnapshotJson &&
          other.paymentRequestJson == this.paymentRequestJson &&
          other.latestPaymentJson == this.latestPaymentJson &&
          other.syncVersion == this.syncVersion &&
          other.syncDirty == this.syncDirty &&
          other.syncIntent == this.syncIntent &&
          other.syncError == this.syncError &&
          other.localFilePathsJson == this.localFilePathsJson &&
          other.paidAmountLocal == this.paidAmountLocal &&
          other.changeAmountLocal == this.changeAmountLocal &&
          other.cashRoundingAmount == this.cashRoundingAmount &&
          other.cashRoundingUnit == this.cashRoundingUnit &&
          other.latestPaymentServerId == this.latestPaymentServerId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncedAt == this.syncedAt);
}

class BookingOrdersCompanion extends UpdateCompanion<BookingOrder> {
  final Value<String> clientUuid;
  final Value<int?> serverId;
  final Value<String?> bookingOrderCode;
  final Value<int?> partnerId;
  final Value<String?> partnerName;
  final Value<int?> tableId;
  final Value<String?> tableNo;
  final Value<int?> customerId;
  final Value<int?> employeeOrderId;
  final Value<String?> orderBy;
  final Value<String> customerName;
  final Value<String> orderStatus;
  final Value<String?> paymentMethod;
  final Value<bool> openbillFlag;
  final Value<int?> discountId;
  final Value<double> discountValue;
  final Value<double> totalOrderValue;
  final Value<double?> ppn;
  final Value<bool> isPpnActive;
  final Value<String?> customerOrderNote;
  final Value<String?> employeeOrderNote;
  final Value<int?> cashierProcessId;
  final Value<int?> kitchenProcessId;
  final Value<int?> paymentId;
  final Value<bool> paymentFlag;
  final Value<String?> wifiSnapshotJson;
  final Value<String?> paymentRequestJson;
  final Value<String?> latestPaymentJson;
  final Value<int> syncVersion;
  final Value<bool> syncDirty;
  final Value<String?> syncIntent;
  final Value<String?> syncError;
  final Value<String?> localFilePathsJson;
  final Value<double?> paidAmountLocal;
  final Value<double?> changeAmountLocal;
  final Value<double?> cashRoundingAmount;
  final Value<int?> cashRoundingUnit;
  final Value<int?> latestPaymentServerId;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const BookingOrdersCompanion({
    this.clientUuid = const Value.absent(),
    this.serverId = const Value.absent(),
    this.bookingOrderCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.partnerName = const Value.absent(),
    this.tableId = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeOrderId = const Value.absent(),
    this.orderBy = const Value.absent(),
    this.customerName = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.openbillFlag = const Value.absent(),
    this.discountId = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.totalOrderValue = const Value.absent(),
    this.ppn = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.customerOrderNote = const Value.absent(),
    this.employeeOrderNote = const Value.absent(),
    this.cashierProcessId = const Value.absent(),
    this.kitchenProcessId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.paymentFlag = const Value.absent(),
    this.wifiSnapshotJson = const Value.absent(),
    this.paymentRequestJson = const Value.absent(),
    this.latestPaymentJson = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.syncIntent = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localFilePathsJson = const Value.absent(),
    this.paidAmountLocal = const Value.absent(),
    this.changeAmountLocal = const Value.absent(),
    this.cashRoundingAmount = const Value.absent(),
    this.cashRoundingUnit = const Value.absent(),
    this.latestPaymentServerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookingOrdersCompanion.insert({
    required String clientUuid,
    this.serverId = const Value.absent(),
    this.bookingOrderCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.partnerName = const Value.absent(),
    this.tableId = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeOrderId = const Value.absent(),
    this.orderBy = const Value.absent(),
    required String customerName,
    this.orderStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.openbillFlag = const Value.absent(),
    this.discountId = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.totalOrderValue = const Value.absent(),
    this.ppn = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.customerOrderNote = const Value.absent(),
    this.employeeOrderNote = const Value.absent(),
    this.cashierProcessId = const Value.absent(),
    this.kitchenProcessId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.paymentFlag = const Value.absent(),
    this.wifiSnapshotJson = const Value.absent(),
    this.paymentRequestJson = const Value.absent(),
    this.latestPaymentJson = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.syncIntent = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localFilePathsJson = const Value.absent(),
    this.paidAmountLocal = const Value.absent(),
    this.changeAmountLocal = const Value.absent(),
    this.cashRoundingAmount = const Value.absent(),
    this.cashRoundingUnit = const Value.absent(),
    this.latestPaymentServerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       customerName = Value(customerName);
  static Insertable<BookingOrder> custom({
    Expression<String>? clientUuid,
    Expression<int>? serverId,
    Expression<String>? bookingOrderCode,
    Expression<int>? partnerId,
    Expression<String>? partnerName,
    Expression<int>? tableId,
    Expression<String>? tableNo,
    Expression<int>? customerId,
    Expression<int>? employeeOrderId,
    Expression<String>? orderBy,
    Expression<String>? customerName,
    Expression<String>? orderStatus,
    Expression<String>? paymentMethod,
    Expression<bool>? openbillFlag,
    Expression<int>? discountId,
    Expression<double>? discountValue,
    Expression<double>? totalOrderValue,
    Expression<double>? ppn,
    Expression<bool>? isPpnActive,
    Expression<String>? customerOrderNote,
    Expression<String>? employeeOrderNote,
    Expression<int>? cashierProcessId,
    Expression<int>? kitchenProcessId,
    Expression<int>? paymentId,
    Expression<bool>? paymentFlag,
    Expression<String>? wifiSnapshotJson,
    Expression<String>? paymentRequestJson,
    Expression<String>? latestPaymentJson,
    Expression<int>? syncVersion,
    Expression<bool>? syncDirty,
    Expression<String>? syncIntent,
    Expression<String>? syncError,
    Expression<String>? localFilePathsJson,
    Expression<double>? paidAmountLocal,
    Expression<double>? changeAmountLocal,
    Expression<double>? cashRoundingAmount,
    Expression<int>? cashRoundingUnit,
    Expression<int>? latestPaymentServerId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderCode != null) 'booking_order_code': bookingOrderCode,
      if (partnerId != null) 'partner_id': partnerId,
      if (partnerName != null) 'partner_name': partnerName,
      if (tableId != null) 'table_id': tableId,
      if (tableNo != null) 'table_no': tableNo,
      if (customerId != null) 'customer_id': customerId,
      if (employeeOrderId != null) 'employee_order_id': employeeOrderId,
      if (orderBy != null) 'order_by': orderBy,
      if (customerName != null) 'customer_name': customerName,
      if (orderStatus != null) 'order_status': orderStatus,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (openbillFlag != null) 'openbill_flag': openbillFlag,
      if (discountId != null) 'discount_id': discountId,
      if (discountValue != null) 'discount_value': discountValue,
      if (totalOrderValue != null) 'total_order_value': totalOrderValue,
      if (ppn != null) 'ppn': ppn,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (customerOrderNote != null) 'customer_order_note': customerOrderNote,
      if (employeeOrderNote != null) 'employee_order_note': employeeOrderNote,
      if (cashierProcessId != null) 'cashier_process_id': cashierProcessId,
      if (kitchenProcessId != null) 'kitchen_process_id': kitchenProcessId,
      if (paymentId != null) 'payment_id': paymentId,
      if (paymentFlag != null) 'payment_flag': paymentFlag,
      if (wifiSnapshotJson != null) 'wifi_snapshot_json': wifiSnapshotJson,
      if (paymentRequestJson != null)
        'payment_request_json': paymentRequestJson,
      if (latestPaymentJson != null) 'latest_payment_json': latestPaymentJson,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (syncDirty != null) 'sync_dirty': syncDirty,
      if (syncIntent != null) 'sync_intent': syncIntent,
      if (syncError != null) 'sync_error': syncError,
      if (localFilePathsJson != null)
        'local_file_paths_json': localFilePathsJson,
      if (paidAmountLocal != null) 'paid_amount_local': paidAmountLocal,
      if (changeAmountLocal != null) 'change_amount_local': changeAmountLocal,
      if (cashRoundingAmount != null)
        'cash_rounding_amount': cashRoundingAmount,
      if (cashRoundingUnit != null) 'cash_rounding_unit': cashRoundingUnit,
      if (latestPaymentServerId != null)
        'latest_payment_server_id': latestPaymentServerId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookingOrdersCompanion copyWith({
    Value<String>? clientUuid,
    Value<int?>? serverId,
    Value<String?>? bookingOrderCode,
    Value<int?>? partnerId,
    Value<String?>? partnerName,
    Value<int?>? tableId,
    Value<String?>? tableNo,
    Value<int?>? customerId,
    Value<int?>? employeeOrderId,
    Value<String?>? orderBy,
    Value<String>? customerName,
    Value<String>? orderStatus,
    Value<String?>? paymentMethod,
    Value<bool>? openbillFlag,
    Value<int?>? discountId,
    Value<double>? discountValue,
    Value<double>? totalOrderValue,
    Value<double?>? ppn,
    Value<bool>? isPpnActive,
    Value<String?>? customerOrderNote,
    Value<String?>? employeeOrderNote,
    Value<int?>? cashierProcessId,
    Value<int?>? kitchenProcessId,
    Value<int?>? paymentId,
    Value<bool>? paymentFlag,
    Value<String?>? wifiSnapshotJson,
    Value<String?>? paymentRequestJson,
    Value<String?>? latestPaymentJson,
    Value<int>? syncVersion,
    Value<bool>? syncDirty,
    Value<String?>? syncIntent,
    Value<String?>? syncError,
    Value<String?>? localFilePathsJson,
    Value<double?>? paidAmountLocal,
    Value<double?>? changeAmountLocal,
    Value<double?>? cashRoundingAmount,
    Value<int?>? cashRoundingUnit,
    Value<int?>? latestPaymentServerId,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return BookingOrdersCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      serverId: serverId ?? this.serverId,
      bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      tableId: tableId ?? this.tableId,
      tableNo: tableNo ?? this.tableNo,
      customerId: customerId ?? this.customerId,
      employeeOrderId: employeeOrderId ?? this.employeeOrderId,
      orderBy: orderBy ?? this.orderBy,
      customerName: customerName ?? this.customerName,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      openbillFlag: openbillFlag ?? this.openbillFlag,
      discountId: discountId ?? this.discountId,
      discountValue: discountValue ?? this.discountValue,
      totalOrderValue: totalOrderValue ?? this.totalOrderValue,
      ppn: ppn ?? this.ppn,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      customerOrderNote: customerOrderNote ?? this.customerOrderNote,
      employeeOrderNote: employeeOrderNote ?? this.employeeOrderNote,
      cashierProcessId: cashierProcessId ?? this.cashierProcessId,
      kitchenProcessId: kitchenProcessId ?? this.kitchenProcessId,
      paymentId: paymentId ?? this.paymentId,
      paymentFlag: paymentFlag ?? this.paymentFlag,
      wifiSnapshotJson: wifiSnapshotJson ?? this.wifiSnapshotJson,
      paymentRequestJson: paymentRequestJson ?? this.paymentRequestJson,
      latestPaymentJson: latestPaymentJson ?? this.latestPaymentJson,
      syncVersion: syncVersion ?? this.syncVersion,
      syncDirty: syncDirty ?? this.syncDirty,
      syncIntent: syncIntent ?? this.syncIntent,
      syncError: syncError ?? this.syncError,
      localFilePathsJson: localFilePathsJson ?? this.localFilePathsJson,
      paidAmountLocal: paidAmountLocal ?? this.paidAmountLocal,
      changeAmountLocal: changeAmountLocal ?? this.changeAmountLocal,
      cashRoundingAmount: cashRoundingAmount ?? this.cashRoundingAmount,
      cashRoundingUnit: cashRoundingUnit ?? this.cashRoundingUnit,
      latestPaymentServerId:
          latestPaymentServerId ?? this.latestPaymentServerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderCode.present) {
      map['booking_order_code'] = Variable<String>(bookingOrderCode.value);
    }
    if (partnerId.present) {
      map['partner_id'] = Variable<int>(partnerId.value);
    }
    if (partnerName.present) {
      map['partner_name'] = Variable<String>(partnerName.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<int>(tableId.value);
    }
    if (tableNo.present) {
      map['table_no'] = Variable<String>(tableNo.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (employeeOrderId.present) {
      map['employee_order_id'] = Variable<int>(employeeOrderId.value);
    }
    if (orderBy.present) {
      map['order_by'] = Variable<String>(orderBy.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (openbillFlag.present) {
      map['openbill_flag'] = Variable<bool>(openbillFlag.value);
    }
    if (discountId.present) {
      map['discount_id'] = Variable<int>(discountId.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (totalOrderValue.present) {
      map['total_order_value'] = Variable<double>(totalOrderValue.value);
    }
    if (ppn.present) {
      map['ppn'] = Variable<double>(ppn.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (customerOrderNote.present) {
      map['customer_order_note'] = Variable<String>(customerOrderNote.value);
    }
    if (employeeOrderNote.present) {
      map['employee_order_note'] = Variable<String>(employeeOrderNote.value);
    }
    if (cashierProcessId.present) {
      map['cashier_process_id'] = Variable<int>(cashierProcessId.value);
    }
    if (kitchenProcessId.present) {
      map['kitchen_process_id'] = Variable<int>(kitchenProcessId.value);
    }
    if (paymentId.present) {
      map['payment_id'] = Variable<int>(paymentId.value);
    }
    if (paymentFlag.present) {
      map['payment_flag'] = Variable<bool>(paymentFlag.value);
    }
    if (wifiSnapshotJson.present) {
      map['wifi_snapshot_json'] = Variable<String>(wifiSnapshotJson.value);
    }
    if (paymentRequestJson.present) {
      map['payment_request_json'] = Variable<String>(paymentRequestJson.value);
    }
    if (latestPaymentJson.present) {
      map['latest_payment_json'] = Variable<String>(latestPaymentJson.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (syncDirty.present) {
      map['sync_dirty'] = Variable<bool>(syncDirty.value);
    }
    if (syncIntent.present) {
      map['sync_intent'] = Variable<String>(syncIntent.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localFilePathsJson.present) {
      map['local_file_paths_json'] = Variable<String>(localFilePathsJson.value);
    }
    if (paidAmountLocal.present) {
      map['paid_amount_local'] = Variable<double>(paidAmountLocal.value);
    }
    if (changeAmountLocal.present) {
      map['change_amount_local'] = Variable<double>(changeAmountLocal.value);
    }
    if (cashRoundingAmount.present) {
      map['cash_rounding_amount'] = Variable<double>(cashRoundingAmount.value);
    }
    if (cashRoundingUnit.present) {
      map['cash_rounding_unit'] = Variable<int>(cashRoundingUnit.value);
    }
    if (latestPaymentServerId.present) {
      map['latest_payment_server_id'] = Variable<int>(
        latestPaymentServerId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingOrdersCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('partnerName: $partnerName, ')
          ..write('tableId: $tableId, ')
          ..write('tableNo: $tableNo, ')
          ..write('customerId: $customerId, ')
          ..write('employeeOrderId: $employeeOrderId, ')
          ..write('orderBy: $orderBy, ')
          ..write('customerName: $customerName, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('openbillFlag: $openbillFlag, ')
          ..write('discountId: $discountId, ')
          ..write('discountValue: $discountValue, ')
          ..write('totalOrderValue: $totalOrderValue, ')
          ..write('ppn: $ppn, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('customerOrderNote: $customerOrderNote, ')
          ..write('employeeOrderNote: $employeeOrderNote, ')
          ..write('cashierProcessId: $cashierProcessId, ')
          ..write('kitchenProcessId: $kitchenProcessId, ')
          ..write('paymentId: $paymentId, ')
          ..write('paymentFlag: $paymentFlag, ')
          ..write('wifiSnapshotJson: $wifiSnapshotJson, ')
          ..write('paymentRequestJson: $paymentRequestJson, ')
          ..write('latestPaymentJson: $latestPaymentJson, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('syncIntent: $syncIntent, ')
          ..write('syncError: $syncError, ')
          ..write('localFilePathsJson: $localFilePathsJson, ')
          ..write('paidAmountLocal: $paidAmountLocal, ')
          ..write('changeAmountLocal: $changeAmountLocal, ')
          ..write('cashRoundingAmount: $cashRoundingAmount, ')
          ..write('cashRoundingUnit: $cashRoundingUnit, ')
          ..write('latestPaymentServerId: $latestPaymentServerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderDetailsTable extends OrderDetails
    with TableInfo<$OrderDetailsTable, OrderDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientDetailUuidMeta = const VerificationMeta(
    'clientDetailUuid',
  );
  @override
  late final GeneratedColumn<String> clientDetailUuid = GeneratedColumn<String>(
    'client_detail_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingOrderClientUuidMeta =
      const VerificationMeta('bookingOrderClientUuid');
  @override
  late final GeneratedColumn<String> bookingOrderClientUuid =
      GeneratedColumn<String>(
        'booking_order_client_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bookingOrderServerIdMeta =
      const VerificationMeta('bookingOrderServerId');
  @override
  late final GeneratedColumn<int> bookingOrderServerId = GeneratedColumn<int>(
    'booking_order_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partnerProductIdMeta = const VerificationMeta(
    'partnerProductId',
  );
  @override
  late final GeneratedColumn<int> partnerProductId = GeneratedColumn<int>(
    'partner_product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _basePriceMeta = const VerificationMeta(
    'basePrice',
  );
  @override
  late final GeneratedColumn<double> basePrice = GeneratedColumn<double>(
    'base_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cogsMeta = const VerificationMeta('cogs');
  @override
  late final GeneratedColumn<double> cogs = GeneratedColumn<double>(
    'cogs',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsPriceMeta = const VerificationMeta(
    'optionsPrice',
  );
  @override
  late final GeneratedColumn<double> optionsPrice = GeneratedColumn<double>(
    'options_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerNoteMeta = const VerificationMeta(
    'customerNote',
  );
  @override
  late final GeneratedColumn<String> customerNote = GeneratedColumn<String>(
    'customer_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promoIdMeta = const VerificationMeta(
    'promoId',
  );
  @override
  late final GeneratedColumn<int> promoId = GeneratedColumn<int>(
    'promo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promoAmountMeta = const VerificationMeta(
    'promoAmount',
  );
  @override
  late final GeneratedColumn<double> promoAmount = GeneratedColumn<double>(
    'promo_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promoTypeMeta = const VerificationMeta(
    'promoType',
  );
  @override
  late final GeneratedColumn<String> promoType = GeneratedColumn<String>(
    'promo_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierProcessIdMeta = const VerificationMeta(
    'cashierProcessId',
  );
  @override
  late final GeneratedColumn<int> cashierProcessId = GeneratedColumn<int>(
    'cashier_process_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kitchenProcessIdMeta = const VerificationMeta(
    'kitchenProcessId',
  );
  @override
  late final GeneratedColumn<int> kitchenProcessId = GeneratedColumn<int>(
    'kitchen_process_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncDirtyMeta = const VerificationMeta(
    'syncDirty',
  );
  @override
  late final GeneratedColumn<bool> syncDirty = GeneratedColumn<bool>(
    'sync_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientDetailUuid,
    serverId,
    bookingOrderClientUuid,
    bookingOrderServerId,
    productCode,
    productName,
    partnerProductId,
    quantity,
    basePrice,
    cogs,
    optionsPrice,
    customerNote,
    promoId,
    promoAmount,
    promoType,
    status,
    cashierProcessId,
    kitchenProcessId,
    syncVersion,
    syncDirty,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_detail_uuid')) {
      context.handle(
        _clientDetailUuidMeta,
        clientDetailUuid.isAcceptableOrUnknown(
          data['client_detail_uuid']!,
          _clientDetailUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientDetailUuidMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('booking_order_client_uuid')) {
      context.handle(
        _bookingOrderClientUuidMeta,
        bookingOrderClientUuid.isAcceptableOrUnknown(
          data['booking_order_client_uuid']!,
          _bookingOrderClientUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookingOrderClientUuidMeta);
    }
    if (data.containsKey('booking_order_server_id')) {
      context.handle(
        _bookingOrderServerIdMeta,
        bookingOrderServerId.isAcceptableOrUnknown(
          data['booking_order_server_id']!,
          _bookingOrderServerIdMeta,
        ),
      );
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('partner_product_id')) {
      context.handle(
        _partnerProductIdMeta,
        partnerProductId.isAcceptableOrUnknown(
          data['partner_product_id']!,
          _partnerProductIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partnerProductIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
      );
    }
    if (data.containsKey('cogs')) {
      context.handle(
        _cogsMeta,
        cogs.isAcceptableOrUnknown(data['cogs']!, _cogsMeta),
      );
    }
    if (data.containsKey('options_price')) {
      context.handle(
        _optionsPriceMeta,
        optionsPrice.isAcceptableOrUnknown(
          data['options_price']!,
          _optionsPriceMeta,
        ),
      );
    }
    if (data.containsKey('customer_note')) {
      context.handle(
        _customerNoteMeta,
        customerNote.isAcceptableOrUnknown(
          data['customer_note']!,
          _customerNoteMeta,
        ),
      );
    }
    if (data.containsKey('promo_id')) {
      context.handle(
        _promoIdMeta,
        promoId.isAcceptableOrUnknown(data['promo_id']!, _promoIdMeta),
      );
    }
    if (data.containsKey('promo_amount')) {
      context.handle(
        _promoAmountMeta,
        promoAmount.isAcceptableOrUnknown(
          data['promo_amount']!,
          _promoAmountMeta,
        ),
      );
    }
    if (data.containsKey('promo_type')) {
      context.handle(
        _promoTypeMeta,
        promoType.isAcceptableOrUnknown(data['promo_type']!, _promoTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('cashier_process_id')) {
      context.handle(
        _cashierProcessIdMeta,
        cashierProcessId.isAcceptableOrUnknown(
          data['cashier_process_id']!,
          _cashierProcessIdMeta,
        ),
      );
    }
    if (data.containsKey('kitchen_process_id')) {
      context.handle(
        _kitchenProcessIdMeta,
        kitchenProcessId.isAcceptableOrUnknown(
          data['kitchen_process_id']!,
          _kitchenProcessIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_dirty')) {
      context.handle(
        _syncDirtyMeta,
        syncDirty.isAcceptableOrUnknown(data['sync_dirty']!, _syncDirtyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientDetailUuid};
  @override
  OrderDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderDetail(
      clientDetailUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_detail_uuid'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      bookingOrderClientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_client_uuid'],
      )!,
      bookingOrderServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}booking_order_server_id'],
      ),
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      partnerProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partner_product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_price'],
      )!,
      cogs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cogs'],
      ),
      optionsPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}options_price'],
      )!,
      customerNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_note'],
      ),
      promoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}promo_id'],
      ),
      promoAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}promo_amount'],
      ),
      promoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promo_type'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      cashierProcessId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cashier_process_id'],
      ),
      kitchenProcessId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kitchen_process_id'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      syncDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_dirty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $OrderDetailsTable createAlias(String alias) {
    return $OrderDetailsTable(attachedDatabase, alias);
  }
}

class OrderDetail extends DataClass implements Insertable<OrderDetail> {
  final String clientDetailUuid;
  final int? serverId;
  final String bookingOrderClientUuid;
  final int? bookingOrderServerId;
  final String? productCode;
  final String? productName;
  final int partnerProductId;
  final int quantity;
  final double basePrice;
  final double? cogs;
  final double optionsPrice;
  final String? customerNote;
  final int? promoId;
  final double? promoAmount;
  final String? promoType;
  final String? status;
  final int? cashierProcessId;
  final int? kitchenProcessId;
  final int syncVersion;
  final bool syncDirty;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const OrderDetail({
    required this.clientDetailUuid,
    this.serverId,
    required this.bookingOrderClientUuid,
    this.bookingOrderServerId,
    this.productCode,
    this.productName,
    required this.partnerProductId,
    required this.quantity,
    required this.basePrice,
    this.cogs,
    required this.optionsPrice,
    this.customerNote,
    this.promoId,
    this.promoAmount,
    this.promoType,
    this.status,
    this.cashierProcessId,
    this.kitchenProcessId,
    required this.syncVersion,
    required this.syncDirty,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_detail_uuid'] = Variable<String>(clientDetailUuid);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['booking_order_client_uuid'] = Variable<String>(bookingOrderClientUuid);
    if (!nullToAbsent || bookingOrderServerId != null) {
      map['booking_order_server_id'] = Variable<int>(bookingOrderServerId);
    }
    if (!nullToAbsent || productCode != null) {
      map['product_code'] = Variable<String>(productCode);
    }
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    map['partner_product_id'] = Variable<int>(partnerProductId);
    map['quantity'] = Variable<int>(quantity);
    map['base_price'] = Variable<double>(basePrice);
    if (!nullToAbsent || cogs != null) {
      map['cogs'] = Variable<double>(cogs);
    }
    map['options_price'] = Variable<double>(optionsPrice);
    if (!nullToAbsent || customerNote != null) {
      map['customer_note'] = Variable<String>(customerNote);
    }
    if (!nullToAbsent || promoId != null) {
      map['promo_id'] = Variable<int>(promoId);
    }
    if (!nullToAbsent || promoAmount != null) {
      map['promo_amount'] = Variable<double>(promoAmount);
    }
    if (!nullToAbsent || promoType != null) {
      map['promo_type'] = Variable<String>(promoType);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || cashierProcessId != null) {
      map['cashier_process_id'] = Variable<int>(cashierProcessId);
    }
    if (!nullToAbsent || kitchenProcessId != null) {
      map['kitchen_process_id'] = Variable<int>(kitchenProcessId);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    map['sync_dirty'] = Variable<bool>(syncDirty);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  OrderDetailsCompanion toCompanion(bool nullToAbsent) {
    return OrderDetailsCompanion(
      clientDetailUuid: Value(clientDetailUuid),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      bookingOrderClientUuid: Value(bookingOrderClientUuid),
      bookingOrderServerId: bookingOrderServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingOrderServerId),
      productCode: productCode == null && nullToAbsent
          ? const Value.absent()
          : Value(productCode),
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      partnerProductId: Value(partnerProductId),
      quantity: Value(quantity),
      basePrice: Value(basePrice),
      cogs: cogs == null && nullToAbsent ? const Value.absent() : Value(cogs),
      optionsPrice: Value(optionsPrice),
      customerNote: customerNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customerNote),
      promoId: promoId == null && nullToAbsent
          ? const Value.absent()
          : Value(promoId),
      promoAmount: promoAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(promoAmount),
      promoType: promoType == null && nullToAbsent
          ? const Value.absent()
          : Value(promoType),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      cashierProcessId: cashierProcessId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierProcessId),
      kitchenProcessId: kitchenProcessId == null && nullToAbsent
          ? const Value.absent()
          : Value(kitchenProcessId),
      syncVersion: Value(syncVersion),
      syncDirty: Value(syncDirty),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory OrderDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderDetail(
      clientDetailUuid: serializer.fromJson<String>(json['clientDetailUuid']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      bookingOrderClientUuid: serializer.fromJson<String>(
        json['bookingOrderClientUuid'],
      ),
      bookingOrderServerId: serializer.fromJson<int?>(
        json['bookingOrderServerId'],
      ),
      productCode: serializer.fromJson<String?>(json['productCode']),
      productName: serializer.fromJson<String?>(json['productName']),
      partnerProductId: serializer.fromJson<int>(json['partnerProductId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      basePrice: serializer.fromJson<double>(json['basePrice']),
      cogs: serializer.fromJson<double?>(json['cogs']),
      optionsPrice: serializer.fromJson<double>(json['optionsPrice']),
      customerNote: serializer.fromJson<String?>(json['customerNote']),
      promoId: serializer.fromJson<int?>(json['promoId']),
      promoAmount: serializer.fromJson<double?>(json['promoAmount']),
      promoType: serializer.fromJson<String?>(json['promoType']),
      status: serializer.fromJson<String?>(json['status']),
      cashierProcessId: serializer.fromJson<int?>(json['cashierProcessId']),
      kitchenProcessId: serializer.fromJson<int?>(json['kitchenProcessId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      syncDirty: serializer.fromJson<bool>(json['syncDirty']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientDetailUuid': serializer.toJson<String>(clientDetailUuid),
      'serverId': serializer.toJson<int?>(serverId),
      'bookingOrderClientUuid': serializer.toJson<String>(
        bookingOrderClientUuid,
      ),
      'bookingOrderServerId': serializer.toJson<int?>(bookingOrderServerId),
      'productCode': serializer.toJson<String?>(productCode),
      'productName': serializer.toJson<String?>(productName),
      'partnerProductId': serializer.toJson<int>(partnerProductId),
      'quantity': serializer.toJson<int>(quantity),
      'basePrice': serializer.toJson<double>(basePrice),
      'cogs': serializer.toJson<double?>(cogs),
      'optionsPrice': serializer.toJson<double>(optionsPrice),
      'customerNote': serializer.toJson<String?>(customerNote),
      'promoId': serializer.toJson<int?>(promoId),
      'promoAmount': serializer.toJson<double?>(promoAmount),
      'promoType': serializer.toJson<String?>(promoType),
      'status': serializer.toJson<String?>(status),
      'cashierProcessId': serializer.toJson<int?>(cashierProcessId),
      'kitchenProcessId': serializer.toJson<int?>(kitchenProcessId),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'syncDirty': serializer.toJson<bool>(syncDirty),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  OrderDetail copyWith({
    String? clientDetailUuid,
    Value<int?> serverId = const Value.absent(),
    String? bookingOrderClientUuid,
    Value<int?> bookingOrderServerId = const Value.absent(),
    Value<String?> productCode = const Value.absent(),
    Value<String?> productName = const Value.absent(),
    int? partnerProductId,
    int? quantity,
    double? basePrice,
    Value<double?> cogs = const Value.absent(),
    double? optionsPrice,
    Value<String?> customerNote = const Value.absent(),
    Value<int?> promoId = const Value.absent(),
    Value<double?> promoAmount = const Value.absent(),
    Value<String?> promoType = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<int?> cashierProcessId = const Value.absent(),
    Value<int?> kitchenProcessId = const Value.absent(),
    int? syncVersion,
    bool? syncDirty,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => OrderDetail(
    clientDetailUuid: clientDetailUuid ?? this.clientDetailUuid,
    serverId: serverId.present ? serverId.value : this.serverId,
    bookingOrderClientUuid:
        bookingOrderClientUuid ?? this.bookingOrderClientUuid,
    bookingOrderServerId: bookingOrderServerId.present
        ? bookingOrderServerId.value
        : this.bookingOrderServerId,
    productCode: productCode.present ? productCode.value : this.productCode,
    productName: productName.present ? productName.value : this.productName,
    partnerProductId: partnerProductId ?? this.partnerProductId,
    quantity: quantity ?? this.quantity,
    basePrice: basePrice ?? this.basePrice,
    cogs: cogs.present ? cogs.value : this.cogs,
    optionsPrice: optionsPrice ?? this.optionsPrice,
    customerNote: customerNote.present ? customerNote.value : this.customerNote,
    promoId: promoId.present ? promoId.value : this.promoId,
    promoAmount: promoAmount.present ? promoAmount.value : this.promoAmount,
    promoType: promoType.present ? promoType.value : this.promoType,
    status: status.present ? status.value : this.status,
    cashierProcessId: cashierProcessId.present
        ? cashierProcessId.value
        : this.cashierProcessId,
    kitchenProcessId: kitchenProcessId.present
        ? kitchenProcessId.value
        : this.kitchenProcessId,
    syncVersion: syncVersion ?? this.syncVersion,
    syncDirty: syncDirty ?? this.syncDirty,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  OrderDetail copyWithCompanion(OrderDetailsCompanion data) {
    return OrderDetail(
      clientDetailUuid: data.clientDetailUuid.present
          ? data.clientDetailUuid.value
          : this.clientDetailUuid,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderClientUuid: data.bookingOrderClientUuid.present
          ? data.bookingOrderClientUuid.value
          : this.bookingOrderClientUuid,
      bookingOrderServerId: data.bookingOrderServerId.present
          ? data.bookingOrderServerId.value
          : this.bookingOrderServerId,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      partnerProductId: data.partnerProductId.present
          ? data.partnerProductId.value
          : this.partnerProductId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      cogs: data.cogs.present ? data.cogs.value : this.cogs,
      optionsPrice: data.optionsPrice.present
          ? data.optionsPrice.value
          : this.optionsPrice,
      customerNote: data.customerNote.present
          ? data.customerNote.value
          : this.customerNote,
      promoId: data.promoId.present ? data.promoId.value : this.promoId,
      promoAmount: data.promoAmount.present
          ? data.promoAmount.value
          : this.promoAmount,
      promoType: data.promoType.present ? data.promoType.value : this.promoType,
      status: data.status.present ? data.status.value : this.status,
      cashierProcessId: data.cashierProcessId.present
          ? data.cashierProcessId.value
          : this.cashierProcessId,
      kitchenProcessId: data.kitchenProcessId.present
          ? data.kitchenProcessId.value
          : this.kitchenProcessId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      syncDirty: data.syncDirty.present ? data.syncDirty.value : this.syncDirty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderDetail(')
          ..write('clientDetailUuid: $clientDetailUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderClientUuid: $bookingOrderClientUuid, ')
          ..write('bookingOrderServerId: $bookingOrderServerId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('partnerProductId: $partnerProductId, ')
          ..write('quantity: $quantity, ')
          ..write('basePrice: $basePrice, ')
          ..write('cogs: $cogs, ')
          ..write('optionsPrice: $optionsPrice, ')
          ..write('customerNote: $customerNote, ')
          ..write('promoId: $promoId, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('promoType: $promoType, ')
          ..write('status: $status, ')
          ..write('cashierProcessId: $cashierProcessId, ')
          ..write('kitchenProcessId: $kitchenProcessId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    clientDetailUuid,
    serverId,
    bookingOrderClientUuid,
    bookingOrderServerId,
    productCode,
    productName,
    partnerProductId,
    quantity,
    basePrice,
    cogs,
    optionsPrice,
    customerNote,
    promoId,
    promoAmount,
    promoType,
    status,
    cashierProcessId,
    kitchenProcessId,
    syncVersion,
    syncDirty,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderDetail &&
          other.clientDetailUuid == this.clientDetailUuid &&
          other.serverId == this.serverId &&
          other.bookingOrderClientUuid == this.bookingOrderClientUuid &&
          other.bookingOrderServerId == this.bookingOrderServerId &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.partnerProductId == this.partnerProductId &&
          other.quantity == this.quantity &&
          other.basePrice == this.basePrice &&
          other.cogs == this.cogs &&
          other.optionsPrice == this.optionsPrice &&
          other.customerNote == this.customerNote &&
          other.promoId == this.promoId &&
          other.promoAmount == this.promoAmount &&
          other.promoType == this.promoType &&
          other.status == this.status &&
          other.cashierProcessId == this.cashierProcessId &&
          other.kitchenProcessId == this.kitchenProcessId &&
          other.syncVersion == this.syncVersion &&
          other.syncDirty == this.syncDirty &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderDetailsCompanion extends UpdateCompanion<OrderDetail> {
  final Value<String> clientDetailUuid;
  final Value<int?> serverId;
  final Value<String> bookingOrderClientUuid;
  final Value<int?> bookingOrderServerId;
  final Value<String?> productCode;
  final Value<String?> productName;
  final Value<int> partnerProductId;
  final Value<int> quantity;
  final Value<double> basePrice;
  final Value<double?> cogs;
  final Value<double> optionsPrice;
  final Value<String?> customerNote;
  final Value<int?> promoId;
  final Value<double?> promoAmount;
  final Value<String?> promoType;
  final Value<String?> status;
  final Value<int?> cashierProcessId;
  final Value<int?> kitchenProcessId;
  final Value<int> syncVersion;
  final Value<bool> syncDirty;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const OrderDetailsCompanion({
    this.clientDetailUuid = const Value.absent(),
    this.serverId = const Value.absent(),
    this.bookingOrderClientUuid = const Value.absent(),
    this.bookingOrderServerId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.partnerProductId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.cogs = const Value.absent(),
    this.optionsPrice = const Value.absent(),
    this.customerNote = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.promoType = const Value.absent(),
    this.status = const Value.absent(),
    this.cashierProcessId = const Value.absent(),
    this.kitchenProcessId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderDetailsCompanion.insert({
    required String clientDetailUuid,
    this.serverId = const Value.absent(),
    required String bookingOrderClientUuid,
    this.bookingOrderServerId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    required int partnerProductId,
    this.quantity = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.cogs = const Value.absent(),
    this.optionsPrice = const Value.absent(),
    this.customerNote = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.promoType = const Value.absent(),
    this.status = const Value.absent(),
    this.cashierProcessId = const Value.absent(),
    this.kitchenProcessId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientDetailUuid = Value(clientDetailUuid),
       bookingOrderClientUuid = Value(bookingOrderClientUuid),
       partnerProductId = Value(partnerProductId);
  static Insertable<OrderDetail> custom({
    Expression<String>? clientDetailUuid,
    Expression<int>? serverId,
    Expression<String>? bookingOrderClientUuid,
    Expression<int>? bookingOrderServerId,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<int>? partnerProductId,
    Expression<int>? quantity,
    Expression<double>? basePrice,
    Expression<double>? cogs,
    Expression<double>? optionsPrice,
    Expression<String>? customerNote,
    Expression<int>? promoId,
    Expression<double>? promoAmount,
    Expression<String>? promoType,
    Expression<String>? status,
    Expression<int>? cashierProcessId,
    Expression<int>? kitchenProcessId,
    Expression<int>? syncVersion,
    Expression<bool>? syncDirty,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientDetailUuid != null) 'client_detail_uuid': clientDetailUuid,
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderClientUuid != null)
        'booking_order_client_uuid': bookingOrderClientUuid,
      if (bookingOrderServerId != null)
        'booking_order_server_id': bookingOrderServerId,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (partnerProductId != null) 'partner_product_id': partnerProductId,
      if (quantity != null) 'quantity': quantity,
      if (basePrice != null) 'base_price': basePrice,
      if (cogs != null) 'cogs': cogs,
      if (optionsPrice != null) 'options_price': optionsPrice,
      if (customerNote != null) 'customer_note': customerNote,
      if (promoId != null) 'promo_id': promoId,
      if (promoAmount != null) 'promo_amount': promoAmount,
      if (promoType != null) 'promo_type': promoType,
      if (status != null) 'status': status,
      if (cashierProcessId != null) 'cashier_process_id': cashierProcessId,
      if (kitchenProcessId != null) 'kitchen_process_id': kitchenProcessId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (syncDirty != null) 'sync_dirty': syncDirty,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderDetailsCompanion copyWith({
    Value<String>? clientDetailUuid,
    Value<int?>? serverId,
    Value<String>? bookingOrderClientUuid,
    Value<int?>? bookingOrderServerId,
    Value<String?>? productCode,
    Value<String?>? productName,
    Value<int>? partnerProductId,
    Value<int>? quantity,
    Value<double>? basePrice,
    Value<double?>? cogs,
    Value<double>? optionsPrice,
    Value<String?>? customerNote,
    Value<int?>? promoId,
    Value<double?>? promoAmount,
    Value<String?>? promoType,
    Value<String?>? status,
    Value<int?>? cashierProcessId,
    Value<int?>? kitchenProcessId,
    Value<int>? syncVersion,
    Value<bool>? syncDirty,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrderDetailsCompanion(
      clientDetailUuid: clientDetailUuid ?? this.clientDetailUuid,
      serverId: serverId ?? this.serverId,
      bookingOrderClientUuid:
          bookingOrderClientUuid ?? this.bookingOrderClientUuid,
      bookingOrderServerId: bookingOrderServerId ?? this.bookingOrderServerId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      partnerProductId: partnerProductId ?? this.partnerProductId,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice ?? this.basePrice,
      cogs: cogs ?? this.cogs,
      optionsPrice: optionsPrice ?? this.optionsPrice,
      customerNote: customerNote ?? this.customerNote,
      promoId: promoId ?? this.promoId,
      promoAmount: promoAmount ?? this.promoAmount,
      promoType: promoType ?? this.promoType,
      status: status ?? this.status,
      cashierProcessId: cashierProcessId ?? this.cashierProcessId,
      kitchenProcessId: kitchenProcessId ?? this.kitchenProcessId,
      syncVersion: syncVersion ?? this.syncVersion,
      syncDirty: syncDirty ?? this.syncDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientDetailUuid.present) {
      map['client_detail_uuid'] = Variable<String>(clientDetailUuid.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderClientUuid.present) {
      map['booking_order_client_uuid'] = Variable<String>(
        bookingOrderClientUuid.value,
      );
    }
    if (bookingOrderServerId.present) {
      map['booking_order_server_id'] = Variable<int>(
        bookingOrderServerId.value,
      );
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (partnerProductId.present) {
      map['partner_product_id'] = Variable<int>(partnerProductId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<double>(basePrice.value);
    }
    if (cogs.present) {
      map['cogs'] = Variable<double>(cogs.value);
    }
    if (optionsPrice.present) {
      map['options_price'] = Variable<double>(optionsPrice.value);
    }
    if (customerNote.present) {
      map['customer_note'] = Variable<String>(customerNote.value);
    }
    if (promoId.present) {
      map['promo_id'] = Variable<int>(promoId.value);
    }
    if (promoAmount.present) {
      map['promo_amount'] = Variable<double>(promoAmount.value);
    }
    if (promoType.present) {
      map['promo_type'] = Variable<String>(promoType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cashierProcessId.present) {
      map['cashier_process_id'] = Variable<int>(cashierProcessId.value);
    }
    if (kitchenProcessId.present) {
      map['kitchen_process_id'] = Variable<int>(kitchenProcessId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (syncDirty.present) {
      map['sync_dirty'] = Variable<bool>(syncDirty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderDetailsCompanion(')
          ..write('clientDetailUuid: $clientDetailUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderClientUuid: $bookingOrderClientUuid, ')
          ..write('bookingOrderServerId: $bookingOrderServerId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('partnerProductId: $partnerProductId, ')
          ..write('quantity: $quantity, ')
          ..write('basePrice: $basePrice, ')
          ..write('cogs: $cogs, ')
          ..write('optionsPrice: $optionsPrice, ')
          ..write('customerNote: $customerNote, ')
          ..write('promoId: $promoId, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('promoType: $promoType, ')
          ..write('status: $status, ')
          ..write('cashierProcessId: $cashierProcessId, ')
          ..write('kitchenProcessId: $kitchenProcessId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderDetailOptionsTable extends OrderDetailOptions
    with TableInfo<$OrderDetailOptionsTable, OrderDetailOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderDetailOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOptionUuidMeta = const VerificationMeta(
    'clientOptionUuid',
  );
  @override
  late final GeneratedColumn<String> clientOptionUuid = GeneratedColumn<String>(
    'client_option_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderDetailClientUuidMeta =
      const VerificationMeta('orderDetailClientUuid');
  @override
  late final GeneratedColumn<String> orderDetailClientUuid =
      GeneratedColumn<String>(
        'order_detail_client_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _orderDetailServerIdMeta =
      const VerificationMeta('orderDetailServerId');
  @override
  late final GeneratedColumn<int> orderDetailServerId = GeneratedColumn<int>(
    'order_detail_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionIdMeta = const VerificationMeta(
    'optionId',
  );
  @override
  late final GeneratedColumn<int> optionId = GeneratedColumn<int>(
    'option_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentNameMeta = const VerificationMeta(
    'parentName',
  );
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
    'parent_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partnerProductOptionNameMeta =
      const VerificationMeta('partnerProductOptionName');
  @override
  late final GeneratedColumn<String> partnerProductOptionName =
      GeneratedColumn<String>(
        'partner_product_option_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientOptionUuid,
    serverId,
    orderDetailClientUuid,
    orderDetailServerId,
    optionId,
    parentName,
    partnerProductOptionName,
    price,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_detail_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderDetailOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_option_uuid')) {
      context.handle(
        _clientOptionUuidMeta,
        clientOptionUuid.isAcceptableOrUnknown(
          data['client_option_uuid']!,
          _clientOptionUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOptionUuidMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('order_detail_client_uuid')) {
      context.handle(
        _orderDetailClientUuidMeta,
        orderDetailClientUuid.isAcceptableOrUnknown(
          data['order_detail_client_uuid']!,
          _orderDetailClientUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderDetailClientUuidMeta);
    }
    if (data.containsKey('order_detail_server_id')) {
      context.handle(
        _orderDetailServerIdMeta,
        orderDetailServerId.isAcceptableOrUnknown(
          data['order_detail_server_id']!,
          _orderDetailServerIdMeta,
        ),
      );
    }
    if (data.containsKey('option_id')) {
      context.handle(
        _optionIdMeta,
        optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_optionIdMeta);
    }
    if (data.containsKey('parent_name')) {
      context.handle(
        _parentNameMeta,
        parentName.isAcceptableOrUnknown(data['parent_name']!, _parentNameMeta),
      );
    }
    if (data.containsKey('partner_product_option_name')) {
      context.handle(
        _partnerProductOptionNameMeta,
        partnerProductOptionName.isAcceptableOrUnknown(
          data['partner_product_option_name']!,
          _partnerProductOptionNameMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOptionUuid};
  @override
  OrderDetailOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderDetailOption(
      clientOptionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_option_uuid'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      orderDetailClientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_detail_client_uuid'],
      )!,
      orderDetailServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_detail_server_id'],
      ),
      optionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}option_id'],
      )!,
      parentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_name'],
      ),
      partnerProductOptionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partner_product_option_name'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $OrderDetailOptionsTable createAlias(String alias) {
    return $OrderDetailOptionsTable(attachedDatabase, alias);
  }
}

class OrderDetailOption extends DataClass
    implements Insertable<OrderDetailOption> {
  final String clientOptionUuid;
  final int? serverId;
  final String orderDetailClientUuid;
  final int? orderDetailServerId;
  final int optionId;
  final String? parentName;
  final String? partnerProductOptionName;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const OrderDetailOption({
    required this.clientOptionUuid,
    this.serverId,
    required this.orderDetailClientUuid,
    this.orderDetailServerId,
    required this.optionId,
    this.parentName,
    this.partnerProductOptionName,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_option_uuid'] = Variable<String>(clientOptionUuid);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['order_detail_client_uuid'] = Variable<String>(orderDetailClientUuid);
    if (!nullToAbsent || orderDetailServerId != null) {
      map['order_detail_server_id'] = Variable<int>(orderDetailServerId);
    }
    map['option_id'] = Variable<int>(optionId);
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    if (!nullToAbsent || partnerProductOptionName != null) {
      map['partner_product_option_name'] = Variable<String>(
        partnerProductOptionName,
      );
    }
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  OrderDetailOptionsCompanion toCompanion(bool nullToAbsent) {
    return OrderDetailOptionsCompanion(
      clientOptionUuid: Value(clientOptionUuid),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      orderDetailClientUuid: Value(orderDetailClientUuid),
      orderDetailServerId: orderDetailServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderDetailServerId),
      optionId: Value(optionId),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      partnerProductOptionName: partnerProductOptionName == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerProductOptionName),
      price: Value(price),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory OrderDetailOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderDetailOption(
      clientOptionUuid: serializer.fromJson<String>(json['clientOptionUuid']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      orderDetailClientUuid: serializer.fromJson<String>(
        json['orderDetailClientUuid'],
      ),
      orderDetailServerId: serializer.fromJson<int?>(
        json['orderDetailServerId'],
      ),
      optionId: serializer.fromJson<int>(json['optionId']),
      parentName: serializer.fromJson<String?>(json['parentName']),
      partnerProductOptionName: serializer.fromJson<String?>(
        json['partnerProductOptionName'],
      ),
      price: serializer.fromJson<double>(json['price']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOptionUuid': serializer.toJson<String>(clientOptionUuid),
      'serverId': serializer.toJson<int?>(serverId),
      'orderDetailClientUuid': serializer.toJson<String>(orderDetailClientUuid),
      'orderDetailServerId': serializer.toJson<int?>(orderDetailServerId),
      'optionId': serializer.toJson<int>(optionId),
      'parentName': serializer.toJson<String?>(parentName),
      'partnerProductOptionName': serializer.toJson<String?>(
        partnerProductOptionName,
      ),
      'price': serializer.toJson<double>(price),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  OrderDetailOption copyWith({
    String? clientOptionUuid,
    Value<int?> serverId = const Value.absent(),
    String? orderDetailClientUuid,
    Value<int?> orderDetailServerId = const Value.absent(),
    int? optionId,
    Value<String?> parentName = const Value.absent(),
    Value<String?> partnerProductOptionName = const Value.absent(),
    double? price,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => OrderDetailOption(
    clientOptionUuid: clientOptionUuid ?? this.clientOptionUuid,
    serverId: serverId.present ? serverId.value : this.serverId,
    orderDetailClientUuid: orderDetailClientUuid ?? this.orderDetailClientUuid,
    orderDetailServerId: orderDetailServerId.present
        ? orderDetailServerId.value
        : this.orderDetailServerId,
    optionId: optionId ?? this.optionId,
    parentName: parentName.present ? parentName.value : this.parentName,
    partnerProductOptionName: partnerProductOptionName.present
        ? partnerProductOptionName.value
        : this.partnerProductOptionName,
    price: price ?? this.price,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  OrderDetailOption copyWithCompanion(OrderDetailOptionsCompanion data) {
    return OrderDetailOption(
      clientOptionUuid: data.clientOptionUuid.present
          ? data.clientOptionUuid.value
          : this.clientOptionUuid,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      orderDetailClientUuid: data.orderDetailClientUuid.present
          ? data.orderDetailClientUuid.value
          : this.orderDetailClientUuid,
      orderDetailServerId: data.orderDetailServerId.present
          ? data.orderDetailServerId.value
          : this.orderDetailServerId,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
      parentName: data.parentName.present
          ? data.parentName.value
          : this.parentName,
      partnerProductOptionName: data.partnerProductOptionName.present
          ? data.partnerProductOptionName.value
          : this.partnerProductOptionName,
      price: data.price.present ? data.price.value : this.price,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderDetailOption(')
          ..write('clientOptionUuid: $clientOptionUuid, ')
          ..write('serverId: $serverId, ')
          ..write('orderDetailClientUuid: $orderDetailClientUuid, ')
          ..write('orderDetailServerId: $orderDetailServerId, ')
          ..write('optionId: $optionId, ')
          ..write('parentName: $parentName, ')
          ..write('partnerProductOptionName: $partnerProductOptionName, ')
          ..write('price: $price, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientOptionUuid,
    serverId,
    orderDetailClientUuid,
    orderDetailServerId,
    optionId,
    parentName,
    partnerProductOptionName,
    price,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderDetailOption &&
          other.clientOptionUuid == this.clientOptionUuid &&
          other.serverId == this.serverId &&
          other.orderDetailClientUuid == this.orderDetailClientUuid &&
          other.orderDetailServerId == this.orderDetailServerId &&
          other.optionId == this.optionId &&
          other.parentName == this.parentName &&
          other.partnerProductOptionName == this.partnerProductOptionName &&
          other.price == this.price &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderDetailOptionsCompanion extends UpdateCompanion<OrderDetailOption> {
  final Value<String> clientOptionUuid;
  final Value<int?> serverId;
  final Value<String> orderDetailClientUuid;
  final Value<int?> orderDetailServerId;
  final Value<int> optionId;
  final Value<String?> parentName;
  final Value<String?> partnerProductOptionName;
  final Value<double> price;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const OrderDetailOptionsCompanion({
    this.clientOptionUuid = const Value.absent(),
    this.serverId = const Value.absent(),
    this.orderDetailClientUuid = const Value.absent(),
    this.orderDetailServerId = const Value.absent(),
    this.optionId = const Value.absent(),
    this.parentName = const Value.absent(),
    this.partnerProductOptionName = const Value.absent(),
    this.price = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderDetailOptionsCompanion.insert({
    required String clientOptionUuid,
    this.serverId = const Value.absent(),
    required String orderDetailClientUuid,
    this.orderDetailServerId = const Value.absent(),
    required int optionId,
    this.parentName = const Value.absent(),
    this.partnerProductOptionName = const Value.absent(),
    this.price = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientOptionUuid = Value(clientOptionUuid),
       orderDetailClientUuid = Value(orderDetailClientUuid),
       optionId = Value(optionId);
  static Insertable<OrderDetailOption> custom({
    Expression<String>? clientOptionUuid,
    Expression<int>? serverId,
    Expression<String>? orderDetailClientUuid,
    Expression<int>? orderDetailServerId,
    Expression<int>? optionId,
    Expression<String>? parentName,
    Expression<String>? partnerProductOptionName,
    Expression<double>? price,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOptionUuid != null) 'client_option_uuid': clientOptionUuid,
      if (serverId != null) 'server_id': serverId,
      if (orderDetailClientUuid != null)
        'order_detail_client_uuid': orderDetailClientUuid,
      if (orderDetailServerId != null)
        'order_detail_server_id': orderDetailServerId,
      if (optionId != null) 'option_id': optionId,
      if (parentName != null) 'parent_name': parentName,
      if (partnerProductOptionName != null)
        'partner_product_option_name': partnerProductOptionName,
      if (price != null) 'price': price,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderDetailOptionsCompanion copyWith({
    Value<String>? clientOptionUuid,
    Value<int?>? serverId,
    Value<String>? orderDetailClientUuid,
    Value<int?>? orderDetailServerId,
    Value<int>? optionId,
    Value<String?>? parentName,
    Value<String?>? partnerProductOptionName,
    Value<double>? price,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrderDetailOptionsCompanion(
      clientOptionUuid: clientOptionUuid ?? this.clientOptionUuid,
      serverId: serverId ?? this.serverId,
      orderDetailClientUuid:
          orderDetailClientUuid ?? this.orderDetailClientUuid,
      orderDetailServerId: orderDetailServerId ?? this.orderDetailServerId,
      optionId: optionId ?? this.optionId,
      parentName: parentName ?? this.parentName,
      partnerProductOptionName:
          partnerProductOptionName ?? this.partnerProductOptionName,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOptionUuid.present) {
      map['client_option_uuid'] = Variable<String>(clientOptionUuid.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (orderDetailClientUuid.present) {
      map['order_detail_client_uuid'] = Variable<String>(
        orderDetailClientUuid.value,
      );
    }
    if (orderDetailServerId.present) {
      map['order_detail_server_id'] = Variable<int>(orderDetailServerId.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<int>(optionId.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (partnerProductOptionName.present) {
      map['partner_product_option_name'] = Variable<String>(
        partnerProductOptionName.value,
      );
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderDetailOptionsCompanion(')
          ..write('clientOptionUuid: $clientOptionUuid, ')
          ..write('serverId: $serverId, ')
          ..write('orderDetailClientUuid: $orderDetailClientUuid, ')
          ..write('orderDetailServerId: $orderDetailServerId, ')
          ..write('optionId: $optionId, ')
          ..write('parentName: $parentName, ')
          ..write('partnerProductOptionName: $partnerProductOptionName, ')
          ..write('price: $price, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderPaymentsTable extends OrderPayments
    with TableInfo<$OrderPaymentsTable, OrderPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientPaymentUuidMeta = const VerificationMeta(
    'clientPaymentUuid',
  );
  @override
  late final GeneratedColumn<String> clientPaymentUuid =
      GeneratedColumn<String>(
        'client_payment_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingOrderClientUuidMeta =
      const VerificationMeta('bookingOrderClientUuid');
  @override
  late final GeneratedColumn<String> bookingOrderClientUuid =
      GeneratedColumn<String>(
        'booking_order_client_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bookingOrderServerIdMeta =
      const VerificationMeta('bookingOrderServerId');
  @override
  late final GeneratedColumn<int> bookingOrderServerId = GeneratedColumn<int>(
    'booking_order_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
    'employee_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentTypeMeta = const VerificationMeta(
    'paymentType',
  );
  @override
  late final GeneratedColumn<String> paymentType = GeneratedColumn<String>(
    'payment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _changeAmountMeta = const VerificationMeta(
    'changeAmount',
  );
  @override
  late final GeneratedColumn<double> changeAmount = GeneratedColumn<double>(
    'change_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ppnMeta = const VerificationMeta('ppn');
  @override
  late final GeneratedColumn<double> ppn = GeneratedColumn<double>(
    'ppn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountBeforePpnMeta = const VerificationMeta(
    'amountBeforePpn',
  );
  @override
  late final GeneratedColumn<double> amountBeforePpn = GeneratedColumn<double>(
    'amount_before_ppn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roundingAmountMeta = const VerificationMeta(
    'roundingAmount',
  );
  @override
  late final GeneratedColumn<double> roundingAmount = GeneratedColumn<double>(
    'rounding_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerManualPaymentIdMeta =
      const VerificationMeta('ownerManualPaymentId');
  @override
  late final GeneratedColumn<int> ownerManualPaymentId = GeneratedColumn<int>(
    'owner_manual_payment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualProviderNameMeta =
      const VerificationMeta('manualProviderName');
  @override
  late final GeneratedColumn<String> manualProviderName =
      GeneratedColumn<String>(
        'manual_provider_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _manualProviderAccountNameMeta =
      const VerificationMeta('manualProviderAccountName');
  @override
  late final GeneratedColumn<String> manualProviderAccountName =
      GeneratedColumn<String>(
        'manual_provider_account_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _manualProviderAccountNoMeta =
      const VerificationMeta('manualProviderAccountNo');
  @override
  late final GeneratedColumn<String> manualProviderAccountNo =
      GeneratedColumn<String>(
        'manual_provider_account_no',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncDirtyMeta = const VerificationMeta(
    'syncDirty',
  );
  @override
  late final GeneratedColumn<bool> syncDirty = GeneratedColumn<bool>(
    'sync_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localFilePathsJsonMeta =
      const VerificationMeta('localFilePathsJson');
  @override
  late final GeneratedColumn<String> localFilePathsJson =
      GeneratedColumn<String>(
        'local_file_paths_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientPaymentUuid,
    serverId,
    bookingOrderClientUuid,
    bookingOrderServerId,
    employeeId,
    customerId,
    customerName,
    paymentType,
    paidAmount,
    changeAmount,
    paymentStatus,
    note,
    ppn,
    amountBeforePpn,
    roundingAmount,
    ownerManualPaymentId,
    manualProviderName,
    manualProviderAccountName,
    manualProviderAccountNo,
    syncDirty,
    localFilePathsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_payment_uuid')) {
      context.handle(
        _clientPaymentUuidMeta,
        clientPaymentUuid.isAcceptableOrUnknown(
          data['client_payment_uuid']!,
          _clientPaymentUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPaymentUuidMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('booking_order_client_uuid')) {
      context.handle(
        _bookingOrderClientUuidMeta,
        bookingOrderClientUuid.isAcceptableOrUnknown(
          data['booking_order_client_uuid']!,
          _bookingOrderClientUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookingOrderClientUuidMeta);
    }
    if (data.containsKey('booking_order_server_id')) {
      context.handle(
        _bookingOrderServerIdMeta,
        bookingOrderServerId.isAcceptableOrUnknown(
          data['booking_order_server_id']!,
          _bookingOrderServerIdMeta,
        ),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('payment_type')) {
      context.handle(
        _paymentTypeMeta,
        paymentType.isAcceptableOrUnknown(
          data['payment_type']!,
          _paymentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentTypeMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('change_amount')) {
      context.handle(
        _changeAmountMeta,
        changeAmount.isAcceptableOrUnknown(
          data['change_amount']!,
          _changeAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('ppn')) {
      context.handle(
        _ppnMeta,
        ppn.isAcceptableOrUnknown(data['ppn']!, _ppnMeta),
      );
    }
    if (data.containsKey('amount_before_ppn')) {
      context.handle(
        _amountBeforePpnMeta,
        amountBeforePpn.isAcceptableOrUnknown(
          data['amount_before_ppn']!,
          _amountBeforePpnMeta,
        ),
      );
    }
    if (data.containsKey('rounding_amount')) {
      context.handle(
        _roundingAmountMeta,
        roundingAmount.isAcceptableOrUnknown(
          data['rounding_amount']!,
          _roundingAmountMeta,
        ),
      );
    }
    if (data.containsKey('owner_manual_payment_id')) {
      context.handle(
        _ownerManualPaymentIdMeta,
        ownerManualPaymentId.isAcceptableOrUnknown(
          data['owner_manual_payment_id']!,
          _ownerManualPaymentIdMeta,
        ),
      );
    }
    if (data.containsKey('manual_provider_name')) {
      context.handle(
        _manualProviderNameMeta,
        manualProviderName.isAcceptableOrUnknown(
          data['manual_provider_name']!,
          _manualProviderNameMeta,
        ),
      );
    }
    if (data.containsKey('manual_provider_account_name')) {
      context.handle(
        _manualProviderAccountNameMeta,
        manualProviderAccountName.isAcceptableOrUnknown(
          data['manual_provider_account_name']!,
          _manualProviderAccountNameMeta,
        ),
      );
    }
    if (data.containsKey('manual_provider_account_no')) {
      context.handle(
        _manualProviderAccountNoMeta,
        manualProviderAccountNo.isAcceptableOrUnknown(
          data['manual_provider_account_no']!,
          _manualProviderAccountNoMeta,
        ),
      );
    }
    if (data.containsKey('sync_dirty')) {
      context.handle(
        _syncDirtyMeta,
        syncDirty.isAcceptableOrUnknown(data['sync_dirty']!, _syncDirtyMeta),
      );
    }
    if (data.containsKey('local_file_paths_json')) {
      context.handle(
        _localFilePathsJsonMeta,
        localFilePathsJson.isAcceptableOrUnknown(
          data['local_file_paths_json']!,
          _localFilePathsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientPaymentUuid};
  @override
  OrderPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderPayment(
      clientPaymentUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_payment_uuid'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      bookingOrderClientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_client_uuid'],
      )!,
      bookingOrderServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}booking_order_server_id'],
      ),
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employee_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      paymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_type'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      changeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change_amount'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      ppn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn'],
      ),
      amountBeforePpn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_before_ppn'],
      ),
      roundingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rounding_amount'],
      ),
      ownerManualPaymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}owner_manual_payment_id'],
      ),
      manualProviderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_provider_name'],
      ),
      manualProviderAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_provider_account_name'],
      ),
      manualProviderAccountNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_provider_account_no'],
      ),
      syncDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_dirty'],
      )!,
      localFilePathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_paths_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $OrderPaymentsTable createAlias(String alias) {
    return $OrderPaymentsTable(attachedDatabase, alias);
  }
}

class OrderPayment extends DataClass implements Insertable<OrderPayment> {
  final String clientPaymentUuid;
  final int? serverId;
  final String bookingOrderClientUuid;
  final int? bookingOrderServerId;
  final int? employeeId;
  final int? customerId;
  final String? customerName;
  final String paymentType;
  final double paidAmount;
  final double changeAmount;
  final String paymentStatus;
  final String? note;
  final double? ppn;
  final double? amountBeforePpn;
  final double? roundingAmount;
  final int? ownerManualPaymentId;
  final String? manualProviderName;
  final String? manualProviderAccountName;
  final String? manualProviderAccountNo;
  final bool syncDirty;
  final String? localFilePathsJson;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const OrderPayment({
    required this.clientPaymentUuid,
    this.serverId,
    required this.bookingOrderClientUuid,
    this.bookingOrderServerId,
    this.employeeId,
    this.customerId,
    this.customerName,
    required this.paymentType,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentStatus,
    this.note,
    this.ppn,
    this.amountBeforePpn,
    this.roundingAmount,
    this.ownerManualPaymentId,
    this.manualProviderName,
    this.manualProviderAccountName,
    this.manualProviderAccountNo,
    required this.syncDirty,
    this.localFilePathsJson,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_payment_uuid'] = Variable<String>(clientPaymentUuid);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['booking_order_client_uuid'] = Variable<String>(bookingOrderClientUuid);
    if (!nullToAbsent || bookingOrderServerId != null) {
      map['booking_order_server_id'] = Variable<int>(bookingOrderServerId);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['payment_type'] = Variable<String>(paymentType);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['change_amount'] = Variable<double>(changeAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || ppn != null) {
      map['ppn'] = Variable<double>(ppn);
    }
    if (!nullToAbsent || amountBeforePpn != null) {
      map['amount_before_ppn'] = Variable<double>(amountBeforePpn);
    }
    if (!nullToAbsent || roundingAmount != null) {
      map['rounding_amount'] = Variable<double>(roundingAmount);
    }
    if (!nullToAbsent || ownerManualPaymentId != null) {
      map['owner_manual_payment_id'] = Variable<int>(ownerManualPaymentId);
    }
    if (!nullToAbsent || manualProviderName != null) {
      map['manual_provider_name'] = Variable<String>(manualProviderName);
    }
    if (!nullToAbsent || manualProviderAccountName != null) {
      map['manual_provider_account_name'] = Variable<String>(
        manualProviderAccountName,
      );
    }
    if (!nullToAbsent || manualProviderAccountNo != null) {
      map['manual_provider_account_no'] = Variable<String>(
        manualProviderAccountNo,
      );
    }
    map['sync_dirty'] = Variable<bool>(syncDirty);
    if (!nullToAbsent || localFilePathsJson != null) {
      map['local_file_paths_json'] = Variable<String>(localFilePathsJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  OrderPaymentsCompanion toCompanion(bool nullToAbsent) {
    return OrderPaymentsCompanion(
      clientPaymentUuid: Value(clientPaymentUuid),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      bookingOrderClientUuid: Value(bookingOrderClientUuid),
      bookingOrderServerId: bookingOrderServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingOrderServerId),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      paymentType: Value(paymentType),
      paidAmount: Value(paidAmount),
      changeAmount: Value(changeAmount),
      paymentStatus: Value(paymentStatus),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      ppn: ppn == null && nullToAbsent ? const Value.absent() : Value(ppn),
      amountBeforePpn: amountBeforePpn == null && nullToAbsent
          ? const Value.absent()
          : Value(amountBeforePpn),
      roundingAmount: roundingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(roundingAmount),
      ownerManualPaymentId: ownerManualPaymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerManualPaymentId),
      manualProviderName: manualProviderName == null && nullToAbsent
          ? const Value.absent()
          : Value(manualProviderName),
      manualProviderAccountName:
          manualProviderAccountName == null && nullToAbsent
          ? const Value.absent()
          : Value(manualProviderAccountName),
      manualProviderAccountNo: manualProviderAccountNo == null && nullToAbsent
          ? const Value.absent()
          : Value(manualProviderAccountNo),
      syncDirty: Value(syncDirty),
      localFilePathsJson: localFilePathsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePathsJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory OrderPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderPayment(
      clientPaymentUuid: serializer.fromJson<String>(json['clientPaymentUuid']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      bookingOrderClientUuid: serializer.fromJson<String>(
        json['bookingOrderClientUuid'],
      ),
      bookingOrderServerId: serializer.fromJson<int?>(
        json['bookingOrderServerId'],
      ),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      paymentType: serializer.fromJson<String>(json['paymentType']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      changeAmount: serializer.fromJson<double>(json['changeAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      note: serializer.fromJson<String?>(json['note']),
      ppn: serializer.fromJson<double?>(json['ppn']),
      amountBeforePpn: serializer.fromJson<double?>(json['amountBeforePpn']),
      roundingAmount: serializer.fromJson<double?>(json['roundingAmount']),
      ownerManualPaymentId: serializer.fromJson<int?>(
        json['ownerManualPaymentId'],
      ),
      manualProviderName: serializer.fromJson<String?>(
        json['manualProviderName'],
      ),
      manualProviderAccountName: serializer.fromJson<String?>(
        json['manualProviderAccountName'],
      ),
      manualProviderAccountNo: serializer.fromJson<String?>(
        json['manualProviderAccountNo'],
      ),
      syncDirty: serializer.fromJson<bool>(json['syncDirty']),
      localFilePathsJson: serializer.fromJson<String?>(
        json['localFilePathsJson'],
      ),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientPaymentUuid': serializer.toJson<String>(clientPaymentUuid),
      'serverId': serializer.toJson<int?>(serverId),
      'bookingOrderClientUuid': serializer.toJson<String>(
        bookingOrderClientUuid,
      ),
      'bookingOrderServerId': serializer.toJson<int?>(bookingOrderServerId),
      'employeeId': serializer.toJson<int?>(employeeId),
      'customerId': serializer.toJson<int?>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'paymentType': serializer.toJson<String>(paymentType),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'changeAmount': serializer.toJson<double>(changeAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'note': serializer.toJson<String?>(note),
      'ppn': serializer.toJson<double?>(ppn),
      'amountBeforePpn': serializer.toJson<double?>(amountBeforePpn),
      'roundingAmount': serializer.toJson<double?>(roundingAmount),
      'ownerManualPaymentId': serializer.toJson<int?>(ownerManualPaymentId),
      'manualProviderName': serializer.toJson<String?>(manualProviderName),
      'manualProviderAccountName': serializer.toJson<String?>(
        manualProviderAccountName,
      ),
      'manualProviderAccountNo': serializer.toJson<String?>(
        manualProviderAccountNo,
      ),
      'syncDirty': serializer.toJson<bool>(syncDirty),
      'localFilePathsJson': serializer.toJson<String?>(localFilePathsJson),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  OrderPayment copyWith({
    String? clientPaymentUuid,
    Value<int?> serverId = const Value.absent(),
    String? bookingOrderClientUuid,
    Value<int?> bookingOrderServerId = const Value.absent(),
    Value<int?> employeeId = const Value.absent(),
    Value<int?> customerId = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    String? paymentType,
    double? paidAmount,
    double? changeAmount,
    String? paymentStatus,
    Value<String?> note = const Value.absent(),
    Value<double?> ppn = const Value.absent(),
    Value<double?> amountBeforePpn = const Value.absent(),
    Value<double?> roundingAmount = const Value.absent(),
    Value<int?> ownerManualPaymentId = const Value.absent(),
    Value<String?> manualProviderName = const Value.absent(),
    Value<String?> manualProviderAccountName = const Value.absent(),
    Value<String?> manualProviderAccountNo = const Value.absent(),
    bool? syncDirty,
    Value<String?> localFilePathsJson = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => OrderPayment(
    clientPaymentUuid: clientPaymentUuid ?? this.clientPaymentUuid,
    serverId: serverId.present ? serverId.value : this.serverId,
    bookingOrderClientUuid:
        bookingOrderClientUuid ?? this.bookingOrderClientUuid,
    bookingOrderServerId: bookingOrderServerId.present
        ? bookingOrderServerId.value
        : this.bookingOrderServerId,
    employeeId: employeeId.present ? employeeId.value : this.employeeId,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName.present ? customerName.value : this.customerName,
    paymentType: paymentType ?? this.paymentType,
    paidAmount: paidAmount ?? this.paidAmount,
    changeAmount: changeAmount ?? this.changeAmount,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    note: note.present ? note.value : this.note,
    ppn: ppn.present ? ppn.value : this.ppn,
    amountBeforePpn: amountBeforePpn.present
        ? amountBeforePpn.value
        : this.amountBeforePpn,
    roundingAmount: roundingAmount.present
        ? roundingAmount.value
        : this.roundingAmount,
    ownerManualPaymentId: ownerManualPaymentId.present
        ? ownerManualPaymentId.value
        : this.ownerManualPaymentId,
    manualProviderName: manualProviderName.present
        ? manualProviderName.value
        : this.manualProviderName,
    manualProviderAccountName: manualProviderAccountName.present
        ? manualProviderAccountName.value
        : this.manualProviderAccountName,
    manualProviderAccountNo: manualProviderAccountNo.present
        ? manualProviderAccountNo.value
        : this.manualProviderAccountNo,
    syncDirty: syncDirty ?? this.syncDirty,
    localFilePathsJson: localFilePathsJson.present
        ? localFilePathsJson.value
        : this.localFilePathsJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  OrderPayment copyWithCompanion(OrderPaymentsCompanion data) {
    return OrderPayment(
      clientPaymentUuid: data.clientPaymentUuid.present
          ? data.clientPaymentUuid.value
          : this.clientPaymentUuid,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderClientUuid: data.bookingOrderClientUuid.present
          ? data.bookingOrderClientUuid.value
          : this.bookingOrderClientUuid,
      bookingOrderServerId: data.bookingOrderServerId.present
          ? data.bookingOrderServerId.value
          : this.bookingOrderServerId,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      paymentType: data.paymentType.present
          ? data.paymentType.value
          : this.paymentType,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      note: data.note.present ? data.note.value : this.note,
      ppn: data.ppn.present ? data.ppn.value : this.ppn,
      amountBeforePpn: data.amountBeforePpn.present
          ? data.amountBeforePpn.value
          : this.amountBeforePpn,
      roundingAmount: data.roundingAmount.present
          ? data.roundingAmount.value
          : this.roundingAmount,
      ownerManualPaymentId: data.ownerManualPaymentId.present
          ? data.ownerManualPaymentId.value
          : this.ownerManualPaymentId,
      manualProviderName: data.manualProviderName.present
          ? data.manualProviderName.value
          : this.manualProviderName,
      manualProviderAccountName: data.manualProviderAccountName.present
          ? data.manualProviderAccountName.value
          : this.manualProviderAccountName,
      manualProviderAccountNo: data.manualProviderAccountNo.present
          ? data.manualProviderAccountNo.value
          : this.manualProviderAccountNo,
      syncDirty: data.syncDirty.present ? data.syncDirty.value : this.syncDirty,
      localFilePathsJson: data.localFilePathsJson.present
          ? data.localFilePathsJson.value
          : this.localFilePathsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderPayment(')
          ..write('clientPaymentUuid: $clientPaymentUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderClientUuid: $bookingOrderClientUuid, ')
          ..write('bookingOrderServerId: $bookingOrderServerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('paymentType: $paymentType, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('note: $note, ')
          ..write('ppn: $ppn, ')
          ..write('amountBeforePpn: $amountBeforePpn, ')
          ..write('roundingAmount: $roundingAmount, ')
          ..write('ownerManualPaymentId: $ownerManualPaymentId, ')
          ..write('manualProviderName: $manualProviderName, ')
          ..write('manualProviderAccountName: $manualProviderAccountName, ')
          ..write('manualProviderAccountNo: $manualProviderAccountNo, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('localFilePathsJson: $localFilePathsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    clientPaymentUuid,
    serverId,
    bookingOrderClientUuid,
    bookingOrderServerId,
    employeeId,
    customerId,
    customerName,
    paymentType,
    paidAmount,
    changeAmount,
    paymentStatus,
    note,
    ppn,
    amountBeforePpn,
    roundingAmount,
    ownerManualPaymentId,
    manualProviderName,
    manualProviderAccountName,
    manualProviderAccountNo,
    syncDirty,
    localFilePathsJson,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderPayment &&
          other.clientPaymentUuid == this.clientPaymentUuid &&
          other.serverId == this.serverId &&
          other.bookingOrderClientUuid == this.bookingOrderClientUuid &&
          other.bookingOrderServerId == this.bookingOrderServerId &&
          other.employeeId == this.employeeId &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.paymentType == this.paymentType &&
          other.paidAmount == this.paidAmount &&
          other.changeAmount == this.changeAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.note == this.note &&
          other.ppn == this.ppn &&
          other.amountBeforePpn == this.amountBeforePpn &&
          other.roundingAmount == this.roundingAmount &&
          other.ownerManualPaymentId == this.ownerManualPaymentId &&
          other.manualProviderName == this.manualProviderName &&
          other.manualProviderAccountName == this.manualProviderAccountName &&
          other.manualProviderAccountNo == this.manualProviderAccountNo &&
          other.syncDirty == this.syncDirty &&
          other.localFilePathsJson == this.localFilePathsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderPaymentsCompanion extends UpdateCompanion<OrderPayment> {
  final Value<String> clientPaymentUuid;
  final Value<int?> serverId;
  final Value<String> bookingOrderClientUuid;
  final Value<int?> bookingOrderServerId;
  final Value<int?> employeeId;
  final Value<int?> customerId;
  final Value<String?> customerName;
  final Value<String> paymentType;
  final Value<double> paidAmount;
  final Value<double> changeAmount;
  final Value<String> paymentStatus;
  final Value<String?> note;
  final Value<double?> ppn;
  final Value<double?> amountBeforePpn;
  final Value<double?> roundingAmount;
  final Value<int?> ownerManualPaymentId;
  final Value<String?> manualProviderName;
  final Value<String?> manualProviderAccountName;
  final Value<String?> manualProviderAccountNo;
  final Value<bool> syncDirty;
  final Value<String?> localFilePathsJson;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const OrderPaymentsCompanion({
    this.clientPaymentUuid = const Value.absent(),
    this.serverId = const Value.absent(),
    this.bookingOrderClientUuid = const Value.absent(),
    this.bookingOrderServerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentType = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.ppn = const Value.absent(),
    this.amountBeforePpn = const Value.absent(),
    this.roundingAmount = const Value.absent(),
    this.ownerManualPaymentId = const Value.absent(),
    this.manualProviderName = const Value.absent(),
    this.manualProviderAccountName = const Value.absent(),
    this.manualProviderAccountNo = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.localFilePathsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderPaymentsCompanion.insert({
    required String clientPaymentUuid,
    this.serverId = const Value.absent(),
    required String bookingOrderClientUuid,
    this.bookingOrderServerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    required String paymentType,
    this.paidAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.ppn = const Value.absent(),
    this.amountBeforePpn = const Value.absent(),
    this.roundingAmount = const Value.absent(),
    this.ownerManualPaymentId = const Value.absent(),
    this.manualProviderName = const Value.absent(),
    this.manualProviderAccountName = const Value.absent(),
    this.manualProviderAccountNo = const Value.absent(),
    this.syncDirty = const Value.absent(),
    this.localFilePathsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientPaymentUuid = Value(clientPaymentUuid),
       bookingOrderClientUuid = Value(bookingOrderClientUuid),
       paymentType = Value(paymentType);
  static Insertable<OrderPayment> custom({
    Expression<String>? clientPaymentUuid,
    Expression<int>? serverId,
    Expression<String>? bookingOrderClientUuid,
    Expression<int>? bookingOrderServerId,
    Expression<int>? employeeId,
    Expression<int>? customerId,
    Expression<String>? customerName,
    Expression<String>? paymentType,
    Expression<double>? paidAmount,
    Expression<double>? changeAmount,
    Expression<String>? paymentStatus,
    Expression<String>? note,
    Expression<double>? ppn,
    Expression<double>? amountBeforePpn,
    Expression<double>? roundingAmount,
    Expression<int>? ownerManualPaymentId,
    Expression<String>? manualProviderName,
    Expression<String>? manualProviderAccountName,
    Expression<String>? manualProviderAccountNo,
    Expression<bool>? syncDirty,
    Expression<String>? localFilePathsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientPaymentUuid != null) 'client_payment_uuid': clientPaymentUuid,
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderClientUuid != null)
        'booking_order_client_uuid': bookingOrderClientUuid,
      if (bookingOrderServerId != null)
        'booking_order_server_id': bookingOrderServerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (paymentType != null) 'payment_type': paymentType,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (note != null) 'note': note,
      if (ppn != null) 'ppn': ppn,
      if (amountBeforePpn != null) 'amount_before_ppn': amountBeforePpn,
      if (roundingAmount != null) 'rounding_amount': roundingAmount,
      if (ownerManualPaymentId != null)
        'owner_manual_payment_id': ownerManualPaymentId,
      if (manualProviderName != null)
        'manual_provider_name': manualProviderName,
      if (manualProviderAccountName != null)
        'manual_provider_account_name': manualProviderAccountName,
      if (manualProviderAccountNo != null)
        'manual_provider_account_no': manualProviderAccountNo,
      if (syncDirty != null) 'sync_dirty': syncDirty,
      if (localFilePathsJson != null)
        'local_file_paths_json': localFilePathsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderPaymentsCompanion copyWith({
    Value<String>? clientPaymentUuid,
    Value<int?>? serverId,
    Value<String>? bookingOrderClientUuid,
    Value<int?>? bookingOrderServerId,
    Value<int?>? employeeId,
    Value<int?>? customerId,
    Value<String?>? customerName,
    Value<String>? paymentType,
    Value<double>? paidAmount,
    Value<double>? changeAmount,
    Value<String>? paymentStatus,
    Value<String?>? note,
    Value<double?>? ppn,
    Value<double?>? amountBeforePpn,
    Value<double?>? roundingAmount,
    Value<int?>? ownerManualPaymentId,
    Value<String?>? manualProviderName,
    Value<String?>? manualProviderAccountName,
    Value<String?>? manualProviderAccountNo,
    Value<bool>? syncDirty,
    Value<String?>? localFilePathsJson,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrderPaymentsCompanion(
      clientPaymentUuid: clientPaymentUuid ?? this.clientPaymentUuid,
      serverId: serverId ?? this.serverId,
      bookingOrderClientUuid:
          bookingOrderClientUuid ?? this.bookingOrderClientUuid,
      bookingOrderServerId: bookingOrderServerId ?? this.bookingOrderServerId,
      employeeId: employeeId ?? this.employeeId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentType: paymentType ?? this.paymentType,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      note: note ?? this.note,
      ppn: ppn ?? this.ppn,
      amountBeforePpn: amountBeforePpn ?? this.amountBeforePpn,
      roundingAmount: roundingAmount ?? this.roundingAmount,
      ownerManualPaymentId: ownerManualPaymentId ?? this.ownerManualPaymentId,
      manualProviderName: manualProviderName ?? this.manualProviderName,
      manualProviderAccountName:
          manualProviderAccountName ?? this.manualProviderAccountName,
      manualProviderAccountNo:
          manualProviderAccountNo ?? this.manualProviderAccountNo,
      syncDirty: syncDirty ?? this.syncDirty,
      localFilePathsJson: localFilePathsJson ?? this.localFilePathsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientPaymentUuid.present) {
      map['client_payment_uuid'] = Variable<String>(clientPaymentUuid.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderClientUuid.present) {
      map['booking_order_client_uuid'] = Variable<String>(
        bookingOrderClientUuid.value,
      );
    }
    if (bookingOrderServerId.present) {
      map['booking_order_server_id'] = Variable<int>(
        bookingOrderServerId.value,
      );
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (paymentType.present) {
      map['payment_type'] = Variable<String>(paymentType.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<double>(changeAmount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (ppn.present) {
      map['ppn'] = Variable<double>(ppn.value);
    }
    if (amountBeforePpn.present) {
      map['amount_before_ppn'] = Variable<double>(amountBeforePpn.value);
    }
    if (roundingAmount.present) {
      map['rounding_amount'] = Variable<double>(roundingAmount.value);
    }
    if (ownerManualPaymentId.present) {
      map['owner_manual_payment_id'] = Variable<int>(
        ownerManualPaymentId.value,
      );
    }
    if (manualProviderName.present) {
      map['manual_provider_name'] = Variable<String>(manualProviderName.value);
    }
    if (manualProviderAccountName.present) {
      map['manual_provider_account_name'] = Variable<String>(
        manualProviderAccountName.value,
      );
    }
    if (manualProviderAccountNo.present) {
      map['manual_provider_account_no'] = Variable<String>(
        manualProviderAccountNo.value,
      );
    }
    if (syncDirty.present) {
      map['sync_dirty'] = Variable<bool>(syncDirty.value);
    }
    if (localFilePathsJson.present) {
      map['local_file_paths_json'] = Variable<String>(localFilePathsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderPaymentsCompanion(')
          ..write('clientPaymentUuid: $clientPaymentUuid, ')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderClientUuid: $bookingOrderClientUuid, ')
          ..write('bookingOrderServerId: $bookingOrderServerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('paymentType: $paymentType, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('note: $note, ')
          ..write('ppn: $ppn, ')
          ..write('amountBeforePpn: $amountBeforePpn, ')
          ..write('roundingAmount: $roundingAmount, ')
          ..write('ownerManualPaymentId: $ownerManualPaymentId, ')
          ..write('manualProviderName: $manualProviderName, ')
          ..write('manualProviderAccountName: $manualProviderAccountName, ')
          ..write('manualProviderAccountNo: $manualProviderAccountNo, ')
          ..write('syncDirty: $syncDirty, ')
          ..write('localFilePathsJson: $localFilePathsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSnapshotJsonMeta = const VerificationMeta(
    'localSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> localSnapshotJson =
      GeneratedColumn<String>(
        'local_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSnapshotJsonMeta =
      const VerificationMeta('serverSnapshotJson');
  @override
  late final GeneratedColumn<String> serverSnapshotJson =
      GeneratedColumn<String>(
        'server_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _suggestedResolutionMeta =
      const VerificationMeta('suggestedResolution');
  @override
  late final GeneratedColumn<String> suggestedResolution =
      GeneratedColumn<String>(
        'suggested_resolution',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isResolvedMeta = const VerificationMeta(
    'isResolved',
  );
  @override
  late final GeneratedColumn<bool> isResolved = GeneratedColumn<bool>(
    'is_resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _resolutionChoiceMeta = const VerificationMeta(
    'resolutionChoice',
  );
  @override
  late final GeneratedColumn<String> resolutionChoice = GeneratedColumn<String>(
    'resolution_choice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    serverId,
    clientUuid,
    reason,
    localSnapshotJson,
    serverSnapshotJson,
    suggestedResolution,
    isResolved,
    resolutionChoice,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflict> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('local_snapshot_json')) {
      context.handle(
        _localSnapshotJsonMeta,
        localSnapshotJson.isAcceptableOrUnknown(
          data['local_snapshot_json']!,
          _localSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('server_snapshot_json')) {
      context.handle(
        _serverSnapshotJsonMeta,
        serverSnapshotJson.isAcceptableOrUnknown(
          data['server_snapshot_json']!,
          _serverSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('suggested_resolution')) {
      context.handle(
        _suggestedResolutionMeta,
        suggestedResolution.isAcceptableOrUnknown(
          data['suggested_resolution']!,
          _suggestedResolutionMeta,
        ),
      );
    }
    if (data.containsKey('is_resolved')) {
      context.handle(
        _isResolvedMeta,
        isResolved.isAcceptableOrUnknown(data['is_resolved']!, _isResolvedMeta),
      );
    }
    if (data.containsKey('resolution_choice')) {
      context.handle(
        _resolutionChoiceMeta,
        resolutionChoice.isAcceptableOrUnknown(
          data['resolution_choice']!,
          _resolutionChoiceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      localSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_snapshot_json'],
      ),
      serverSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_snapshot_json'],
      ),
      suggestedResolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_resolution'],
      ),
      isResolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_resolved'],
      )!,
      resolutionChoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_choice'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final int id;
  final String entityTable;
  final int? serverId;
  final String? clientUuid;
  final String reason;
  final String? localSnapshotJson;
  final String? serverSnapshotJson;
  final String? suggestedResolution;
  final bool isResolved;
  final String? resolutionChoice;
  final DateTime createdAt;
  const SyncConflict({
    required this.id,
    required this.entityTable,
    this.serverId,
    this.clientUuid,
    required this.reason,
    this.localSnapshotJson,
    this.serverSnapshotJson,
    this.suggestedResolution,
    required this.isResolved,
    this.resolutionChoice,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || clientUuid != null) {
      map['client_uuid'] = Variable<String>(clientUuid);
    }
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || localSnapshotJson != null) {
      map['local_snapshot_json'] = Variable<String>(localSnapshotJson);
    }
    if (!nullToAbsent || serverSnapshotJson != null) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson);
    }
    if (!nullToAbsent || suggestedResolution != null) {
      map['suggested_resolution'] = Variable<String>(suggestedResolution);
    }
    map['is_resolved'] = Variable<bool>(isResolved);
    if (!nullToAbsent || resolutionChoice != null) {
      map['resolution_choice'] = Variable<String>(resolutionChoice);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientUuid: clientUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(clientUuid),
      reason: Value(reason),
      localSnapshotJson: localSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(localSnapshotJson),
      serverSnapshotJson: serverSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSnapshotJson),
      suggestedResolution: suggestedResolution == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedResolution),
      isResolved: Value(isResolved),
      resolutionChoice: resolutionChoice == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionChoice),
      createdAt: Value(createdAt),
    );
  }

  factory SyncConflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      clientUuid: serializer.fromJson<String?>(json['clientUuid']),
      reason: serializer.fromJson<String>(json['reason']),
      localSnapshotJson: serializer.fromJson<String?>(
        json['localSnapshotJson'],
      ),
      serverSnapshotJson: serializer.fromJson<String?>(
        json['serverSnapshotJson'],
      ),
      suggestedResolution: serializer.fromJson<String?>(
        json['suggestedResolution'],
      ),
      isResolved: serializer.fromJson<bool>(json['isResolved']),
      resolutionChoice: serializer.fromJson<String?>(json['resolutionChoice']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'serverId': serializer.toJson<int?>(serverId),
      'clientUuid': serializer.toJson<String?>(clientUuid),
      'reason': serializer.toJson<String>(reason),
      'localSnapshotJson': serializer.toJson<String?>(localSnapshotJson),
      'serverSnapshotJson': serializer.toJson<String?>(serverSnapshotJson),
      'suggestedResolution': serializer.toJson<String?>(suggestedResolution),
      'isResolved': serializer.toJson<bool>(isResolved),
      'resolutionChoice': serializer.toJson<String?>(resolutionChoice),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncConflict copyWith({
    int? id,
    String? entityTable,
    Value<int?> serverId = const Value.absent(),
    Value<String?> clientUuid = const Value.absent(),
    String? reason,
    Value<String?> localSnapshotJson = const Value.absent(),
    Value<String?> serverSnapshotJson = const Value.absent(),
    Value<String?> suggestedResolution = const Value.absent(),
    bool? isResolved,
    Value<String?> resolutionChoice = const Value.absent(),
    DateTime? createdAt,
  }) => SyncConflict(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientUuid: clientUuid.present ? clientUuid.value : this.clientUuid,
    reason: reason ?? this.reason,
    localSnapshotJson: localSnapshotJson.present
        ? localSnapshotJson.value
        : this.localSnapshotJson,
    serverSnapshotJson: serverSnapshotJson.present
        ? serverSnapshotJson.value
        : this.serverSnapshotJson,
    suggestedResolution: suggestedResolution.present
        ? suggestedResolution.value
        : this.suggestedResolution,
    isResolved: isResolved ?? this.isResolved,
    resolutionChoice: resolutionChoice.present
        ? resolutionChoice.value
        : this.resolutionChoice,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      reason: data.reason.present ? data.reason.value : this.reason,
      localSnapshotJson: data.localSnapshotJson.present
          ? data.localSnapshotJson.value
          : this.localSnapshotJson,
      serverSnapshotJson: data.serverSnapshotJson.present
          ? data.serverSnapshotJson.value
          : this.serverSnapshotJson,
      suggestedResolution: data.suggestedResolution.present
          ? data.suggestedResolution.value
          : this.suggestedResolution,
      isResolved: data.isResolved.present
          ? data.isResolved.value
          : this.isResolved,
      resolutionChoice: data.resolutionChoice.present
          ? data.resolutionChoice.value
          : this.resolutionChoice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('serverId: $serverId, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('reason: $reason, ')
          ..write('localSnapshotJson: $localSnapshotJson, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('suggestedResolution: $suggestedResolution, ')
          ..write('isResolved: $isResolved, ')
          ..write('resolutionChoice: $resolutionChoice, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityTable,
    serverId,
    clientUuid,
    reason,
    localSnapshotJson,
    serverSnapshotJson,
    suggestedResolution,
    isResolved,
    resolutionChoice,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.serverId == this.serverId &&
          other.clientUuid == this.clientUuid &&
          other.reason == this.reason &&
          other.localSnapshotJson == this.localSnapshotJson &&
          other.serverSnapshotJson == this.serverSnapshotJson &&
          other.suggestedResolution == this.suggestedResolution &&
          other.isResolved == this.isResolved &&
          other.resolutionChoice == this.resolutionChoice &&
          other.createdAt == this.createdAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<int?> serverId;
  final Value<String?> clientUuid;
  final Value<String> reason;
  final Value<String?> localSnapshotJson;
  final Value<String?> serverSnapshotJson;
  final Value<String?> suggestedResolution;
  final Value<bool> isResolved;
  final Value<String?> resolutionChoice;
  final Value<DateTime> createdAt;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.reason = const Value.absent(),
    this.localSnapshotJson = const Value.absent(),
    this.serverSnapshotJson = const Value.absent(),
    this.suggestedResolution = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.resolutionChoice = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    this.serverId = const Value.absent(),
    this.clientUuid = const Value.absent(),
    required String reason,
    this.localSnapshotJson = const Value.absent(),
    this.serverSnapshotJson = const Value.absent(),
    this.suggestedResolution = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.resolutionChoice = const Value.absent(),
    required DateTime createdAt,
  }) : entityTable = Value(entityTable),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<SyncConflict> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<int>? serverId,
    Expression<String>? clientUuid,
    Expression<String>? reason,
    Expression<String>? localSnapshotJson,
    Expression<String>? serverSnapshotJson,
    Expression<String>? suggestedResolution,
    Expression<bool>? isResolved,
    Expression<String>? resolutionChoice,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (serverId != null) 'server_id': serverId,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (reason != null) 'reason': reason,
      if (localSnapshotJson != null) 'local_snapshot_json': localSnapshotJson,
      if (serverSnapshotJson != null)
        'server_snapshot_json': serverSnapshotJson,
      if (suggestedResolution != null)
        'suggested_resolution': suggestedResolution,
      if (isResolved != null) 'is_resolved': isResolved,
      if (resolutionChoice != null) 'resolution_choice': resolutionChoice,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityTable,
    Value<int?>? serverId,
    Value<String?>? clientUuid,
    Value<String>? reason,
    Value<String?>? localSnapshotJson,
    Value<String?>? serverSnapshotJson,
    Value<String?>? suggestedResolution,
    Value<bool>? isResolved,
    Value<String?>? resolutionChoice,
    Value<DateTime>? createdAt,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      serverId: serverId ?? this.serverId,
      clientUuid: clientUuid ?? this.clientUuid,
      reason: reason ?? this.reason,
      localSnapshotJson: localSnapshotJson ?? this.localSnapshotJson,
      serverSnapshotJson: serverSnapshotJson ?? this.serverSnapshotJson,
      suggestedResolution: suggestedResolution ?? this.suggestedResolution,
      isResolved: isResolved ?? this.isResolved,
      resolutionChoice: resolutionChoice ?? this.resolutionChoice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (localSnapshotJson.present) {
      map['local_snapshot_json'] = Variable<String>(localSnapshotJson.value);
    }
    if (serverSnapshotJson.present) {
      map['server_snapshot_json'] = Variable<String>(serverSnapshotJson.value);
    }
    if (suggestedResolution.present) {
      map['suggested_resolution'] = Variable<String>(suggestedResolution.value);
    }
    if (isResolved.present) {
      map['is_resolved'] = Variable<bool>(isResolved.value);
    }
    if (resolutionChoice.present) {
      map['resolution_choice'] = Variable<String>(resolutionChoice.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('serverId: $serverId, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('reason: $reason, ')
          ..write('localSnapshotJson: $localSnapshotJson, ')
          ..write('serverSnapshotJson: $serverSnapshotJson, ')
          ..write('suggestedResolution: $suggestedResolution, ')
          ..write('isResolved: $isResolved, ')
          ..write('resolutionChoice: $resolutionChoice, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({String? key, String? value}) =>
      SyncMetaData(key: key ?? this.key, value: value ?? this.value);
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CashierDb extends GeneratedDatabase {
  _$CashierDb(QueryExecutor e) : super(e);
  $CashierDbManager get managers => $CashierDbManager(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $CachedOptionGroupsTable cachedOptionGroups =
      $CachedOptionGroupsTable(this);
  late final $CachedOptionItemsTable cachedOptionItems =
      $CachedOptionItemsTable(this);
  late final $CachedTablesTable cachedTables = $CachedTablesTable(this);
  late final $CachedPaymentMethodsTable cachedPaymentMethods =
      $CachedPaymentMethodsTable(this);
  late final $CachedPartnerSettingsTable cachedPartnerSettings =
      $CachedPartnerSettingsTable(this);
  late final $BookingOrdersTable bookingOrders = $BookingOrdersTable(this);
  late final $OrderDetailsTable orderDetails = $OrderDetailsTable(this);
  late final $OrderDetailOptionsTable orderDetailOptions =
      $OrderDetailOptionsTable(this);
  late final $OrderPaymentsTable orderPayments = $OrderPaymentsTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedCategories,
    cachedProducts,
    cachedOptionGroups,
    cachedOptionItems,
    cachedTables,
    cachedPaymentMethods,
    cachedPartnerSettings,
    bookingOrders,
    orderDetails,
    orderDetailOptions,
    orderPayments,
    syncConflicts,
    syncMeta,
  ];
}

typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<int> id,
      required int serverId,
      required String name,
      Value<int> order,
      required String rawJson,
      required DateTime cachedAt,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> name,
      Value<int> order,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$CashierDb, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$CashierDb, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<_$CashierDb, $CachedCategoriesTable, CachedCategory>,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$CashierDb db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedCategoriesCompanion(
                id: id,
                serverId: serverId,
                name: name,
                order: order,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String name,
                Value<int> order = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
              }) => CachedCategoriesCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                order: order,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$CashierDb, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$CachedProductsTableCreateCompanionBuilder =
    CachedProductsCompanion Function({
      Value<int> id,
      required int serverId,
      required String name,
      required int categoryId,
      required double price,
      Value<String> stockType,
      Value<int> quantityAvailable,
      Value<bool> alwaysAvailable,
      Value<bool> isActive,
      Value<int?> promoId,
      Value<String?> promoType,
      Value<double?> promoValue,
      Value<String?> imagePath,
      Value<String?> description,
      required String rawJson,
      Value<DateTime?> updatedAtServer,
      required DateTime cachedAt,
    });
typedef $$CachedProductsTableUpdateCompanionBuilder =
    CachedProductsCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> name,
      Value<int> categoryId,
      Value<double> price,
      Value<String> stockType,
      Value<int> quantityAvailable,
      Value<bool> alwaysAvailable,
      Value<bool> isActive,
      Value<int?> promoId,
      Value<String?> promoType,
      Value<double?> promoValue,
      Value<String?> imagePath,
      Value<String?> description,
      Value<String> rawJson,
      Value<DateTime?> updatedAtServer,
      Value<DateTime> cachedAt,
    });

class $$CachedProductsTableFilterComposer
    extends Composer<_$CashierDb, $CachedProductsTable> {
  $$CachedProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockType => $composableBuilder(
    column: $table.stockType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promoId => $composableBuilder(
    column: $table.promoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promoType => $composableBuilder(
    column: $table.promoType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get promoValue => $composableBuilder(
    column: $table.promoValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProductsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedProductsTable> {
  $$CachedProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockType => $composableBuilder(
    column: $table.stockType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promoId => $composableBuilder(
    column: $table.promoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promoType => $composableBuilder(
    column: $table.promoType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get promoValue => $composableBuilder(
    column: $table.promoValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProductsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedProductsTable> {
  $$CachedProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get stockType =>
      $composableBuilder(column: $table.stockType, builder: (column) => column);

  GeneratedColumn<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get promoId =>
      $composableBuilder(column: $table.promoId, builder: (column) => column);

  GeneratedColumn<String> get promoType =>
      $composableBuilder(column: $table.promoType, builder: (column) => column);

  GeneratedColumn<double> get promoValue => $composableBuilder(
    column: $table.promoValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProductsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedProductsTable,
          CachedProduct,
          $$CachedProductsTableFilterComposer,
          $$CachedProductsTableOrderingComposer,
          $$CachedProductsTableAnnotationComposer,
          $$CachedProductsTableCreateCompanionBuilder,
          $$CachedProductsTableUpdateCompanionBuilder,
          (
            CachedProduct,
            BaseReferences<_$CashierDb, $CachedProductsTable, CachedProduct>,
          ),
          CachedProduct,
          PrefetchHooks Function()
        > {
  $$CachedProductsTableTableManager(_$CashierDb db, $CachedProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> stockType = const Value.absent(),
                Value<int> quantityAvailable = const Value.absent(),
                Value<bool> alwaysAvailable = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<double?> promoValue = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime?> updatedAtServer = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedProductsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                categoryId: categoryId,
                price: price,
                stockType: stockType,
                quantityAvailable: quantityAvailable,
                alwaysAvailable: alwaysAvailable,
                isActive: isActive,
                promoId: promoId,
                promoType: promoType,
                promoValue: promoValue,
                imagePath: imagePath,
                description: description,
                rawJson: rawJson,
                updatedAtServer: updatedAtServer,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String name,
                required int categoryId,
                required double price,
                Value<String> stockType = const Value.absent(),
                Value<int> quantityAvailable = const Value.absent(),
                Value<bool> alwaysAvailable = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<double?> promoValue = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required String rawJson,
                Value<DateTime?> updatedAtServer = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedProductsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                categoryId: categoryId,
                price: price,
                stockType: stockType,
                quantityAvailable: quantityAvailable,
                alwaysAvailable: alwaysAvailable,
                isActive: isActive,
                promoId: promoId,
                promoType: promoType,
                promoValue: promoValue,
                imagePath: imagePath,
                description: description,
                rawJson: rawJson,
                updatedAtServer: updatedAtServer,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedProductsTable,
      CachedProduct,
      $$CachedProductsTableFilterComposer,
      $$CachedProductsTableOrderingComposer,
      $$CachedProductsTableAnnotationComposer,
      $$CachedProductsTableCreateCompanionBuilder,
      $$CachedProductsTableUpdateCompanionBuilder,
      (
        CachedProduct,
        BaseReferences<_$CashierDb, $CachedProductsTable, CachedProduct>,
      ),
      CachedProduct,
      PrefetchHooks Function()
    >;
typedef $$CachedOptionGroupsTableCreateCompanionBuilder =
    CachedOptionGroupsCompanion Function({
      Value<int> id,
      required int serverId,
      required int productServerId,
      required String name,
      Value<int> minSelect,
      Value<int> maxSelect,
      Value<bool> requiredFlag,
      required String rawJson,
      required DateTime cachedAt,
    });
typedef $$CachedOptionGroupsTableUpdateCompanionBuilder =
    CachedOptionGroupsCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<int> productServerId,
      Value<String> name,
      Value<int> minSelect,
      Value<int> maxSelect,
      Value<bool> requiredFlag,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
    });

class $$CachedOptionGroupsTableFilterComposer
    extends Composer<_$CashierDb, $CachedOptionGroupsTable> {
  $$CachedOptionGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiredFlag => $composableBuilder(
    column: $table.requiredFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedOptionGroupsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedOptionGroupsTable> {
  $$CachedOptionGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiredFlag => $composableBuilder(
    column: $table.requiredFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedOptionGroupsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedOptionGroupsTable> {
  $$CachedOptionGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get minSelect =>
      $composableBuilder(column: $table.minSelect, builder: (column) => column);

  GeneratedColumn<int> get maxSelect =>
      $composableBuilder(column: $table.maxSelect, builder: (column) => column);

  GeneratedColumn<bool> get requiredFlag => $composableBuilder(
    column: $table.requiredFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedOptionGroupsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedOptionGroupsTable,
          CachedOptionGroup,
          $$CachedOptionGroupsTableFilterComposer,
          $$CachedOptionGroupsTableOrderingComposer,
          $$CachedOptionGroupsTableAnnotationComposer,
          $$CachedOptionGroupsTableCreateCompanionBuilder,
          $$CachedOptionGroupsTableUpdateCompanionBuilder,
          (
            CachedOptionGroup,
            BaseReferences<
              _$CashierDb,
              $CachedOptionGroupsTable,
              CachedOptionGroup
            >,
          ),
          CachedOptionGroup,
          PrefetchHooks Function()
        > {
  $$CachedOptionGroupsTableTableManager(
    _$CashierDb db,
    $CachedOptionGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedOptionGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedOptionGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedOptionGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<int> productServerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> minSelect = const Value.absent(),
                Value<int> maxSelect = const Value.absent(),
                Value<bool> requiredFlag = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedOptionGroupsCompanion(
                id: id,
                serverId: serverId,
                productServerId: productServerId,
                name: name,
                minSelect: minSelect,
                maxSelect: maxSelect,
                requiredFlag: requiredFlag,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required int productServerId,
                required String name,
                Value<int> minSelect = const Value.absent(),
                Value<int> maxSelect = const Value.absent(),
                Value<bool> requiredFlag = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
              }) => CachedOptionGroupsCompanion.insert(
                id: id,
                serverId: serverId,
                productServerId: productServerId,
                name: name,
                minSelect: minSelect,
                maxSelect: maxSelect,
                requiredFlag: requiredFlag,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedOptionGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedOptionGroupsTable,
      CachedOptionGroup,
      $$CachedOptionGroupsTableFilterComposer,
      $$CachedOptionGroupsTableOrderingComposer,
      $$CachedOptionGroupsTableAnnotationComposer,
      $$CachedOptionGroupsTableCreateCompanionBuilder,
      $$CachedOptionGroupsTableUpdateCompanionBuilder,
      (
        CachedOptionGroup,
        BaseReferences<
          _$CashierDb,
          $CachedOptionGroupsTable,
          CachedOptionGroup
        >,
      ),
      CachedOptionGroup,
      PrefetchHooks Function()
    >;
typedef $$CachedOptionItemsTableCreateCompanionBuilder =
    CachedOptionItemsCompanion Function({
      Value<int> id,
      required int serverId,
      required int groupServerId,
      required int productServerId,
      required String name,
      Value<double> price,
      Value<String> stockType,
      Value<int> quantityAvailable,
      Value<bool> alwaysAvailable,
      required String rawJson,
      required DateTime cachedAt,
    });
typedef $$CachedOptionItemsTableUpdateCompanionBuilder =
    CachedOptionItemsCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<int> groupServerId,
      Value<int> productServerId,
      Value<String> name,
      Value<double> price,
      Value<String> stockType,
      Value<int> quantityAvailable,
      Value<bool> alwaysAvailable,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
    });

class $$CachedOptionItemsTableFilterComposer
    extends Composer<_$CashierDb, $CachedOptionItemsTable> {
  $$CachedOptionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupServerId => $composableBuilder(
    column: $table.groupServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockType => $composableBuilder(
    column: $table.stockType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedOptionItemsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedOptionItemsTable> {
  $$CachedOptionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupServerId => $composableBuilder(
    column: $table.groupServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockType => $composableBuilder(
    column: $table.stockType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedOptionItemsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedOptionItemsTable> {
  $$CachedOptionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get groupServerId => $composableBuilder(
    column: $table.groupServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get stockType =>
      $composableBuilder(column: $table.stockType, builder: (column) => column);

  GeneratedColumn<int> get quantityAvailable => $composableBuilder(
    column: $table.quantityAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alwaysAvailable => $composableBuilder(
    column: $table.alwaysAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedOptionItemsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedOptionItemsTable,
          CachedOptionItem,
          $$CachedOptionItemsTableFilterComposer,
          $$CachedOptionItemsTableOrderingComposer,
          $$CachedOptionItemsTableAnnotationComposer,
          $$CachedOptionItemsTableCreateCompanionBuilder,
          $$CachedOptionItemsTableUpdateCompanionBuilder,
          (
            CachedOptionItem,
            BaseReferences<
              _$CashierDb,
              $CachedOptionItemsTable,
              CachedOptionItem
            >,
          ),
          CachedOptionItem,
          PrefetchHooks Function()
        > {
  $$CachedOptionItemsTableTableManager(
    _$CashierDb db,
    $CachedOptionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedOptionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedOptionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedOptionItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<int> groupServerId = const Value.absent(),
                Value<int> productServerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> stockType = const Value.absent(),
                Value<int> quantityAvailable = const Value.absent(),
                Value<bool> alwaysAvailable = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedOptionItemsCompanion(
                id: id,
                serverId: serverId,
                groupServerId: groupServerId,
                productServerId: productServerId,
                name: name,
                price: price,
                stockType: stockType,
                quantityAvailable: quantityAvailable,
                alwaysAvailable: alwaysAvailable,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required int groupServerId,
                required int productServerId,
                required String name,
                Value<double> price = const Value.absent(),
                Value<String> stockType = const Value.absent(),
                Value<int> quantityAvailable = const Value.absent(),
                Value<bool> alwaysAvailable = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
              }) => CachedOptionItemsCompanion.insert(
                id: id,
                serverId: serverId,
                groupServerId: groupServerId,
                productServerId: productServerId,
                name: name,
                price: price,
                stockType: stockType,
                quantityAvailable: quantityAvailable,
                alwaysAvailable: alwaysAvailable,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedOptionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedOptionItemsTable,
      CachedOptionItem,
      $$CachedOptionItemsTableFilterComposer,
      $$CachedOptionItemsTableOrderingComposer,
      $$CachedOptionItemsTableAnnotationComposer,
      $$CachedOptionItemsTableCreateCompanionBuilder,
      $$CachedOptionItemsTableUpdateCompanionBuilder,
      (
        CachedOptionItem,
        BaseReferences<_$CashierDb, $CachedOptionItemsTable, CachedOptionItem>,
      ),
      CachedOptionItem,
      PrefetchHooks Function()
    >;
typedef $$CachedTablesTableCreateCompanionBuilder =
    CachedTablesCompanion Function({
      Value<int> id,
      required int serverId,
      required String tableNo,
      Value<String?> tableCode,
      Value<String?> tableClass,
      Value<String> status,
      Value<String?> imagePath,
      Value<String?> tableUrl,
      required String rawJson,
      required DateTime cachedAt,
    });
typedef $$CachedTablesTableUpdateCompanionBuilder =
    CachedTablesCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> tableNo,
      Value<String?> tableCode,
      Value<String?> tableClass,
      Value<String> status,
      Value<String?> imagePath,
      Value<String?> tableUrl,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
    });

class $$CachedTablesTableFilterComposer
    extends Composer<_$CashierDb, $CachedTablesTable> {
  $$CachedTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableCode => $composableBuilder(
    column: $table.tableCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableClass => $composableBuilder(
    column: $table.tableClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableUrl => $composableBuilder(
    column: $table.tableUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTablesTableOrderingComposer
    extends Composer<_$CashierDb, $CachedTablesTable> {
  $$CachedTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableCode => $composableBuilder(
    column: $table.tableCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableClass => $composableBuilder(
    column: $table.tableClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableUrl => $composableBuilder(
    column: $table.tableUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTablesTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedTablesTable> {
  $$CachedTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get tableNo =>
      $composableBuilder(column: $table.tableNo, builder: (column) => column);

  GeneratedColumn<String> get tableCode =>
      $composableBuilder(column: $table.tableCode, builder: (column) => column);

  GeneratedColumn<String> get tableClass => $composableBuilder(
    column: $table.tableClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get tableUrl =>
      $composableBuilder(column: $table.tableUrl, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedTablesTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedTablesTable,
          CachedTable,
          $$CachedTablesTableFilterComposer,
          $$CachedTablesTableOrderingComposer,
          $$CachedTablesTableAnnotationComposer,
          $$CachedTablesTableCreateCompanionBuilder,
          $$CachedTablesTableUpdateCompanionBuilder,
          (
            CachedTable,
            BaseReferences<_$CashierDb, $CachedTablesTable, CachedTable>,
          ),
          CachedTable,
          PrefetchHooks Function()
        > {
  $$CachedTablesTableTableManager(_$CashierDb db, $CachedTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> tableNo = const Value.absent(),
                Value<String?> tableCode = const Value.absent(),
                Value<String?> tableClass = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> tableUrl = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedTablesCompanion(
                id: id,
                serverId: serverId,
                tableNo: tableNo,
                tableCode: tableCode,
                tableClass: tableClass,
                status: status,
                imagePath: imagePath,
                tableUrl: tableUrl,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String tableNo,
                Value<String?> tableCode = const Value.absent(),
                Value<String?> tableClass = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> tableUrl = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
              }) => CachedTablesCompanion.insert(
                id: id,
                serverId: serverId,
                tableNo: tableNo,
                tableCode: tableCode,
                tableClass: tableClass,
                status: status,
                imagePath: imagePath,
                tableUrl: tableUrl,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedTablesTable,
      CachedTable,
      $$CachedTablesTableFilterComposer,
      $$CachedTablesTableOrderingComposer,
      $$CachedTablesTableAnnotationComposer,
      $$CachedTablesTableCreateCompanionBuilder,
      $$CachedTablesTableUpdateCompanionBuilder,
      (
        CachedTable,
        BaseReferences<_$CashierDb, $CachedTablesTable, CachedTable>,
      ),
      CachedTable,
      PrefetchHooks Function()
    >;
typedef $$CachedPaymentMethodsTableCreateCompanionBuilder =
    CachedPaymentMethodsCompanion Function({
      Value<int> id,
      required String localKey,
      required String kind,
      Value<int?> serverManualPaymentId,
      required String label,
      Value<String?> providerName,
      Value<String?> providerAccountName,
      Value<String?> providerAccountNo,
      Value<String?> qrisImageUrl,
      Value<String?> qrisImageLocalPath,
      Value<bool> isActive,
      required String rawJson,
      required DateTime cachedAt,
    });
typedef $$CachedPaymentMethodsTableUpdateCompanionBuilder =
    CachedPaymentMethodsCompanion Function({
      Value<int> id,
      Value<String> localKey,
      Value<String> kind,
      Value<int?> serverManualPaymentId,
      Value<String> label,
      Value<String?> providerName,
      Value<String?> providerAccountName,
      Value<String?> providerAccountNo,
      Value<String?> qrisImageUrl,
      Value<String?> qrisImageLocalPath,
      Value<bool> isActive,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
    });

class $$CachedPaymentMethodsTableFilterComposer
    extends Composer<_$CashierDb, $CachedPaymentMethodsTable> {
  $$CachedPaymentMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverManualPaymentId => $composableBuilder(
    column: $table.serverManualPaymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerAccountName => $composableBuilder(
    column: $table.providerAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerAccountNo => $composableBuilder(
    column: $table.providerAccountNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrisImageUrl => $composableBuilder(
    column: $table.qrisImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrisImageLocalPath => $composableBuilder(
    column: $table.qrisImageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPaymentMethodsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedPaymentMethodsTable> {
  $$CachedPaymentMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverManualPaymentId => $composableBuilder(
    column: $table.serverManualPaymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerAccountName => $composableBuilder(
    column: $table.providerAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerAccountNo => $composableBuilder(
    column: $table.providerAccountNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrisImageUrl => $composableBuilder(
    column: $table.qrisImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrisImageLocalPath => $composableBuilder(
    column: $table.qrisImageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPaymentMethodsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedPaymentMethodsTable> {
  $$CachedPaymentMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localKey =>
      $composableBuilder(column: $table.localKey, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get serverManualPaymentId => $composableBuilder(
    column: $table.serverManualPaymentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerAccountName => $composableBuilder(
    column: $table.providerAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerAccountNo => $composableBuilder(
    column: $table.providerAccountNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qrisImageUrl => $composableBuilder(
    column: $table.qrisImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qrisImageLocalPath => $composableBuilder(
    column: $table.qrisImageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedPaymentMethodsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedPaymentMethodsTable,
          CachedPaymentMethod,
          $$CachedPaymentMethodsTableFilterComposer,
          $$CachedPaymentMethodsTableOrderingComposer,
          $$CachedPaymentMethodsTableAnnotationComposer,
          $$CachedPaymentMethodsTableCreateCompanionBuilder,
          $$CachedPaymentMethodsTableUpdateCompanionBuilder,
          (
            CachedPaymentMethod,
            BaseReferences<
              _$CashierDb,
              $CachedPaymentMethodsTable,
              CachedPaymentMethod
            >,
          ),
          CachedPaymentMethod,
          PrefetchHooks Function()
        > {
  $$CachedPaymentMethodsTableTableManager(
    _$CashierDb db,
    $CachedPaymentMethodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPaymentMethodsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPaymentMethodsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> serverManualPaymentId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> providerName = const Value.absent(),
                Value<String?> providerAccountName = const Value.absent(),
                Value<String?> providerAccountNo = const Value.absent(),
                Value<String?> qrisImageUrl = const Value.absent(),
                Value<String?> qrisImageLocalPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedPaymentMethodsCompanion(
                id: id,
                localKey: localKey,
                kind: kind,
                serverManualPaymentId: serverManualPaymentId,
                label: label,
                providerName: providerName,
                providerAccountName: providerAccountName,
                providerAccountNo: providerAccountNo,
                qrisImageUrl: qrisImageUrl,
                qrisImageLocalPath: qrisImageLocalPath,
                isActive: isActive,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localKey,
                required String kind,
                Value<int?> serverManualPaymentId = const Value.absent(),
                required String label,
                Value<String?> providerName = const Value.absent(),
                Value<String?> providerAccountName = const Value.absent(),
                Value<String?> providerAccountNo = const Value.absent(),
                Value<String?> qrisImageUrl = const Value.absent(),
                Value<String?> qrisImageLocalPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
              }) => CachedPaymentMethodsCompanion.insert(
                id: id,
                localKey: localKey,
                kind: kind,
                serverManualPaymentId: serverManualPaymentId,
                label: label,
                providerName: providerName,
                providerAccountName: providerAccountName,
                providerAccountNo: providerAccountNo,
                qrisImageUrl: qrisImageUrl,
                qrisImageLocalPath: qrisImageLocalPath,
                isActive: isActive,
                rawJson: rawJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPaymentMethodsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedPaymentMethodsTable,
      CachedPaymentMethod,
      $$CachedPaymentMethodsTableFilterComposer,
      $$CachedPaymentMethodsTableOrderingComposer,
      $$CachedPaymentMethodsTableAnnotationComposer,
      $$CachedPaymentMethodsTableCreateCompanionBuilder,
      $$CachedPaymentMethodsTableUpdateCompanionBuilder,
      (
        CachedPaymentMethod,
        BaseReferences<
          _$CashierDb,
          $CachedPaymentMethodsTable,
          CachedPaymentMethod
        >,
      ),
      CachedPaymentMethod,
      PrefetchHooks Function()
    >;
typedef $$CachedPartnerSettingsTableCreateCompanionBuilder =
    CachedPartnerSettingsCompanion Function({
      Value<int> partnerId,
      required String name,
      Value<bool> isQrActive,
      Value<bool> isCashierActive,
      Value<bool> isOpenbill,
      Value<double> ppn,
      Value<bool> isPpnActive,
      Value<int> cashRoundingUnit,
      required DateTime cachedAt,
    });
typedef $$CachedPartnerSettingsTableUpdateCompanionBuilder =
    CachedPartnerSettingsCompanion Function({
      Value<int> partnerId,
      Value<String> name,
      Value<bool> isQrActive,
      Value<bool> isCashierActive,
      Value<bool> isOpenbill,
      Value<double> ppn,
      Value<bool> isPpnActive,
      Value<int> cashRoundingUnit,
      Value<DateTime> cachedAt,
    });

class $$CachedPartnerSettingsTableFilterComposer
    extends Composer<_$CashierDb, $CachedPartnerSettingsTable> {
  $$CachedPartnerSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get partnerId => $composableBuilder(
    column: $table.partnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isQrActive => $composableBuilder(
    column: $table.isQrActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCashierActive => $composableBuilder(
    column: $table.isCashierActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOpenbill => $composableBuilder(
    column: $table.isOpenbill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPartnerSettingsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedPartnerSettingsTable> {
  $$CachedPartnerSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get partnerId => $composableBuilder(
    column: $table.partnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isQrActive => $composableBuilder(
    column: $table.isQrActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCashierActive => $composableBuilder(
    column: $table.isCashierActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOpenbill => $composableBuilder(
    column: $table.isOpenbill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPartnerSettingsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedPartnerSettingsTable> {
  $$CachedPartnerSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get partnerId =>
      $composableBuilder(column: $table.partnerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isQrActive => $composableBuilder(
    column: $table.isQrActive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCashierActive => $composableBuilder(
    column: $table.isCashierActive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOpenbill => $composableBuilder(
    column: $table.isOpenbill,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ppn =>
      $composableBuilder(column: $table.ppn, builder: (column) => column);

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedPartnerSettingsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedPartnerSettingsTable,
          CachedPartnerSetting,
          $$CachedPartnerSettingsTableFilterComposer,
          $$CachedPartnerSettingsTableOrderingComposer,
          $$CachedPartnerSettingsTableAnnotationComposer,
          $$CachedPartnerSettingsTableCreateCompanionBuilder,
          $$CachedPartnerSettingsTableUpdateCompanionBuilder,
          (
            CachedPartnerSetting,
            BaseReferences<
              _$CashierDb,
              $CachedPartnerSettingsTable,
              CachedPartnerSetting
            >,
          ),
          CachedPartnerSetting,
          PrefetchHooks Function()
        > {
  $$CachedPartnerSettingsTableTableManager(
    _$CashierDb db,
    $CachedPartnerSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPartnerSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedPartnerSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPartnerSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> partnerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isQrActive = const Value.absent(),
                Value<bool> isCashierActive = const Value.absent(),
                Value<bool> isOpenbill = const Value.absent(),
                Value<double> ppn = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<int> cashRoundingUnit = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedPartnerSettingsCompanion(
                partnerId: partnerId,
                name: name,
                isQrActive: isQrActive,
                isCashierActive: isCashierActive,
                isOpenbill: isOpenbill,
                ppn: ppn,
                isPpnActive: isPpnActive,
                cashRoundingUnit: cashRoundingUnit,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> partnerId = const Value.absent(),
                required String name,
                Value<bool> isQrActive = const Value.absent(),
                Value<bool> isCashierActive = const Value.absent(),
                Value<bool> isOpenbill = const Value.absent(),
                Value<double> ppn = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<int> cashRoundingUnit = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedPartnerSettingsCompanion.insert(
                partnerId: partnerId,
                name: name,
                isQrActive: isQrActive,
                isCashierActive: isCashierActive,
                isOpenbill: isOpenbill,
                ppn: ppn,
                isPpnActive: isPpnActive,
                cashRoundingUnit: cashRoundingUnit,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPartnerSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedPartnerSettingsTable,
      CachedPartnerSetting,
      $$CachedPartnerSettingsTableFilterComposer,
      $$CachedPartnerSettingsTableOrderingComposer,
      $$CachedPartnerSettingsTableAnnotationComposer,
      $$CachedPartnerSettingsTableCreateCompanionBuilder,
      $$CachedPartnerSettingsTableUpdateCompanionBuilder,
      (
        CachedPartnerSetting,
        BaseReferences<
          _$CashierDb,
          $CachedPartnerSettingsTable,
          CachedPartnerSetting
        >,
      ),
      CachedPartnerSetting,
      PrefetchHooks Function()
    >;
typedef $$BookingOrdersTableCreateCompanionBuilder =
    BookingOrdersCompanion Function({
      required String clientUuid,
      Value<int?> serverId,
      Value<String?> bookingOrderCode,
      Value<int?> partnerId,
      Value<String?> partnerName,
      Value<int?> tableId,
      Value<String?> tableNo,
      Value<int?> customerId,
      Value<int?> employeeOrderId,
      Value<String?> orderBy,
      required String customerName,
      Value<String> orderStatus,
      Value<String?> paymentMethod,
      Value<bool> openbillFlag,
      Value<int?> discountId,
      Value<double> discountValue,
      Value<double> totalOrderValue,
      Value<double?> ppn,
      Value<bool> isPpnActive,
      Value<String?> customerOrderNote,
      Value<String?> employeeOrderNote,
      Value<int?> cashierProcessId,
      Value<int?> kitchenProcessId,
      Value<int?> paymentId,
      Value<bool> paymentFlag,
      Value<String?> wifiSnapshotJson,
      Value<String?> paymentRequestJson,
      Value<String?> latestPaymentJson,
      Value<int> syncVersion,
      Value<bool> syncDirty,
      Value<String?> syncIntent,
      Value<String?> syncError,
      Value<String?> localFilePathsJson,
      Value<double?> paidAmountLocal,
      Value<double?> changeAmountLocal,
      Value<double?> cashRoundingAmount,
      Value<int?> cashRoundingUnit,
      Value<int?> latestPaymentServerId,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$BookingOrdersTableUpdateCompanionBuilder =
    BookingOrdersCompanion Function({
      Value<String> clientUuid,
      Value<int?> serverId,
      Value<String?> bookingOrderCode,
      Value<int?> partnerId,
      Value<String?> partnerName,
      Value<int?> tableId,
      Value<String?> tableNo,
      Value<int?> customerId,
      Value<int?> employeeOrderId,
      Value<String?> orderBy,
      Value<String> customerName,
      Value<String> orderStatus,
      Value<String?> paymentMethod,
      Value<bool> openbillFlag,
      Value<int?> discountId,
      Value<double> discountValue,
      Value<double> totalOrderValue,
      Value<double?> ppn,
      Value<bool> isPpnActive,
      Value<String?> customerOrderNote,
      Value<String?> employeeOrderNote,
      Value<int?> cashierProcessId,
      Value<int?> kitchenProcessId,
      Value<int?> paymentId,
      Value<bool> paymentFlag,
      Value<String?> wifiSnapshotJson,
      Value<String?> paymentRequestJson,
      Value<String?> latestPaymentJson,
      Value<int> syncVersion,
      Value<bool> syncDirty,
      Value<String?> syncIntent,
      Value<String?> syncError,
      Value<String?> localFilePathsJson,
      Value<double?> paidAmountLocal,
      Value<double?> changeAmountLocal,
      Value<double?> cashRoundingAmount,
      Value<int?> cashRoundingUnit,
      Value<int?> latestPaymentServerId,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$BookingOrdersTableFilterComposer
    extends Composer<_$CashierDb, $BookingOrdersTable> {
  $$BookingOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partnerId => $composableBuilder(
    column: $table.partnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partnerName => $composableBuilder(
    column: $table.partnerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get employeeOrderId => $composableBuilder(
    column: $table.employeeOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderBy => $composableBuilder(
    column: $table.orderBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get openbillFlag => $composableBuilder(
    column: $table.openbillFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountId => $composableBuilder(
    column: $table.discountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalOrderValue => $composableBuilder(
    column: $table.totalOrderValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerOrderNote => $composableBuilder(
    column: $table.customerOrderNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeOrderNote => $composableBuilder(
    column: $table.employeeOrderNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paymentFlag => $composableBuilder(
    column: $table.paymentFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wifiSnapshotJson => $composableBuilder(
    column: $table.wifiSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentRequestJson => $composableBuilder(
    column: $table.paymentRequestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestPaymentJson => $composableBuilder(
    column: $table.latestPaymentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncIntent => $composableBuilder(
    column: $table.syncIntent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmountLocal => $composableBuilder(
    column: $table.paidAmountLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get changeAmountLocal => $composableBuilder(
    column: $table.changeAmountLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashRoundingAmount => $composableBuilder(
    column: $table.cashRoundingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookingOrdersTableOrderingComposer
    extends Composer<_$CashierDb, $BookingOrdersTable> {
  $$BookingOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partnerId => $composableBuilder(
    column: $table.partnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partnerName => $composableBuilder(
    column: $table.partnerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get employeeOrderId => $composableBuilder(
    column: $table.employeeOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderBy => $composableBuilder(
    column: $table.orderBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get openbillFlag => $composableBuilder(
    column: $table.openbillFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountId => $composableBuilder(
    column: $table.discountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalOrderValue => $composableBuilder(
    column: $table.totalOrderValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerOrderNote => $composableBuilder(
    column: $table.customerOrderNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeOrderNote => $composableBuilder(
    column: $table.employeeOrderNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paymentFlag => $composableBuilder(
    column: $table.paymentFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wifiSnapshotJson => $composableBuilder(
    column: $table.wifiSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentRequestJson => $composableBuilder(
    column: $table.paymentRequestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestPaymentJson => $composableBuilder(
    column: $table.latestPaymentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncIntent => $composableBuilder(
    column: $table.syncIntent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmountLocal => $composableBuilder(
    column: $table.paidAmountLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get changeAmountLocal => $composableBuilder(
    column: $table.changeAmountLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashRoundingAmount => $composableBuilder(
    column: $table.cashRoundingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookingOrdersTableAnnotationComposer
    extends Composer<_$CashierDb, $BookingOrdersTable> {
  $$BookingOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partnerId =>
      $composableBuilder(column: $table.partnerId, builder: (column) => column);

  GeneratedColumn<String> get partnerName => $composableBuilder(
    column: $table.partnerName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get tableNo =>
      $composableBuilder(column: $table.tableNo, builder: (column) => column);

  GeneratedColumn<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get employeeOrderId => $composableBuilder(
    column: $table.employeeOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderBy =>
      $composableBuilder(column: $table.orderBy, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get openbillFlag => $composableBuilder(
    column: $table.openbillFlag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountId => $composableBuilder(
    column: $table.discountId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalOrderValue => $composableBuilder(
    column: $table.totalOrderValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ppn =>
      $composableBuilder(column: $table.ppn, builder: (column) => column);

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerOrderNote => $composableBuilder(
    column: $table.customerOrderNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeOrderNote => $composableBuilder(
    column: $table.employeeOrderNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentId =>
      $composableBuilder(column: $table.paymentId, builder: (column) => column);

  GeneratedColumn<bool> get paymentFlag => $composableBuilder(
    column: $table.paymentFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wifiSnapshotJson => $composableBuilder(
    column: $table.wifiSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentRequestJson => $composableBuilder(
    column: $table.paymentRequestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestPaymentJson => $composableBuilder(
    column: $table.latestPaymentJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncDirty =>
      $composableBuilder(column: $table.syncDirty, builder: (column) => column);

  GeneratedColumn<String> get syncIntent => $composableBuilder(
    column: $table.syncIntent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmountLocal => $composableBuilder(
    column: $table.paidAmountLocal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get changeAmountLocal => $composableBuilder(
    column: $table.changeAmountLocal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashRoundingAmount => $composableBuilder(
    column: $table.cashRoundingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashRoundingUnit => $composableBuilder(
    column: $table.cashRoundingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$BookingOrdersTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $BookingOrdersTable,
          BookingOrder,
          $$BookingOrdersTableFilterComposer,
          $$BookingOrdersTableOrderingComposer,
          $$BookingOrdersTableAnnotationComposer,
          $$BookingOrdersTableCreateCompanionBuilder,
          $$BookingOrdersTableUpdateCompanionBuilder,
          (
            BookingOrder,
            BaseReferences<_$CashierDb, $BookingOrdersTable, BookingOrder>,
          ),
          BookingOrder,
          PrefetchHooks Function()
        > {
  $$BookingOrdersTableTableManager(_$CashierDb db, $BookingOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> bookingOrderCode = const Value.absent(),
                Value<int?> partnerId = const Value.absent(),
                Value<String?> partnerName = const Value.absent(),
                Value<int?> tableId = const Value.absent(),
                Value<String?> tableNo = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<int?> employeeOrderId = const Value.absent(),
                Value<String?> orderBy = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<bool> openbillFlag = const Value.absent(),
                Value<int?> discountId = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> totalOrderValue = const Value.absent(),
                Value<double?> ppn = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<String?> customerOrderNote = const Value.absent(),
                Value<String?> employeeOrderNote = const Value.absent(),
                Value<int?> cashierProcessId = const Value.absent(),
                Value<int?> kitchenProcessId = const Value.absent(),
                Value<int?> paymentId = const Value.absent(),
                Value<bool> paymentFlag = const Value.absent(),
                Value<String?> wifiSnapshotJson = const Value.absent(),
                Value<String?> paymentRequestJson = const Value.absent(),
                Value<String?> latestPaymentJson = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<String?> syncIntent = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<String?> localFilePathsJson = const Value.absent(),
                Value<double?> paidAmountLocal = const Value.absent(),
                Value<double?> changeAmountLocal = const Value.absent(),
                Value<double?> cashRoundingAmount = const Value.absent(),
                Value<int?> cashRoundingUnit = const Value.absent(),
                Value<int?> latestPaymentServerId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingOrdersCompanion(
                clientUuid: clientUuid,
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                partnerId: partnerId,
                partnerName: partnerName,
                tableId: tableId,
                tableNo: tableNo,
                customerId: customerId,
                employeeOrderId: employeeOrderId,
                orderBy: orderBy,
                customerName: customerName,
                orderStatus: orderStatus,
                paymentMethod: paymentMethod,
                openbillFlag: openbillFlag,
                discountId: discountId,
                discountValue: discountValue,
                totalOrderValue: totalOrderValue,
                ppn: ppn,
                isPpnActive: isPpnActive,
                customerOrderNote: customerOrderNote,
                employeeOrderNote: employeeOrderNote,
                cashierProcessId: cashierProcessId,
                kitchenProcessId: kitchenProcessId,
                paymentId: paymentId,
                paymentFlag: paymentFlag,
                wifiSnapshotJson: wifiSnapshotJson,
                paymentRequestJson: paymentRequestJson,
                latestPaymentJson: latestPaymentJson,
                syncVersion: syncVersion,
                syncDirty: syncDirty,
                syncIntent: syncIntent,
                syncError: syncError,
                localFilePathsJson: localFilePathsJson,
                paidAmountLocal: paidAmountLocal,
                changeAmountLocal: changeAmountLocal,
                cashRoundingAmount: cashRoundingAmount,
                cashRoundingUnit: cashRoundingUnit,
                latestPaymentServerId: latestPaymentServerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                Value<int?> serverId = const Value.absent(),
                Value<String?> bookingOrderCode = const Value.absent(),
                Value<int?> partnerId = const Value.absent(),
                Value<String?> partnerName = const Value.absent(),
                Value<int?> tableId = const Value.absent(),
                Value<String?> tableNo = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<int?> employeeOrderId = const Value.absent(),
                Value<String?> orderBy = const Value.absent(),
                required String customerName,
                Value<String> orderStatus = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<bool> openbillFlag = const Value.absent(),
                Value<int?> discountId = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> totalOrderValue = const Value.absent(),
                Value<double?> ppn = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<String?> customerOrderNote = const Value.absent(),
                Value<String?> employeeOrderNote = const Value.absent(),
                Value<int?> cashierProcessId = const Value.absent(),
                Value<int?> kitchenProcessId = const Value.absent(),
                Value<int?> paymentId = const Value.absent(),
                Value<bool> paymentFlag = const Value.absent(),
                Value<String?> wifiSnapshotJson = const Value.absent(),
                Value<String?> paymentRequestJson = const Value.absent(),
                Value<String?> latestPaymentJson = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<String?> syncIntent = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<String?> localFilePathsJson = const Value.absent(),
                Value<double?> paidAmountLocal = const Value.absent(),
                Value<double?> changeAmountLocal = const Value.absent(),
                Value<double?> cashRoundingAmount = const Value.absent(),
                Value<int?> cashRoundingUnit = const Value.absent(),
                Value<int?> latestPaymentServerId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingOrdersCompanion.insert(
                clientUuid: clientUuid,
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                partnerId: partnerId,
                partnerName: partnerName,
                tableId: tableId,
                tableNo: tableNo,
                customerId: customerId,
                employeeOrderId: employeeOrderId,
                orderBy: orderBy,
                customerName: customerName,
                orderStatus: orderStatus,
                paymentMethod: paymentMethod,
                openbillFlag: openbillFlag,
                discountId: discountId,
                discountValue: discountValue,
                totalOrderValue: totalOrderValue,
                ppn: ppn,
                isPpnActive: isPpnActive,
                customerOrderNote: customerOrderNote,
                employeeOrderNote: employeeOrderNote,
                cashierProcessId: cashierProcessId,
                kitchenProcessId: kitchenProcessId,
                paymentId: paymentId,
                paymentFlag: paymentFlag,
                wifiSnapshotJson: wifiSnapshotJson,
                paymentRequestJson: paymentRequestJson,
                latestPaymentJson: latestPaymentJson,
                syncVersion: syncVersion,
                syncDirty: syncDirty,
                syncIntent: syncIntent,
                syncError: syncError,
                localFilePathsJson: localFilePathsJson,
                paidAmountLocal: paidAmountLocal,
                changeAmountLocal: changeAmountLocal,
                cashRoundingAmount: cashRoundingAmount,
                cashRoundingUnit: cashRoundingUnit,
                latestPaymentServerId: latestPaymentServerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $BookingOrdersTable,
      BookingOrder,
      $$BookingOrdersTableFilterComposer,
      $$BookingOrdersTableOrderingComposer,
      $$BookingOrdersTableAnnotationComposer,
      $$BookingOrdersTableCreateCompanionBuilder,
      $$BookingOrdersTableUpdateCompanionBuilder,
      (
        BookingOrder,
        BaseReferences<_$CashierDb, $BookingOrdersTable, BookingOrder>,
      ),
      BookingOrder,
      PrefetchHooks Function()
    >;
typedef $$OrderDetailsTableCreateCompanionBuilder =
    OrderDetailsCompanion Function({
      required String clientDetailUuid,
      Value<int?> serverId,
      required String bookingOrderClientUuid,
      Value<int?> bookingOrderServerId,
      Value<String?> productCode,
      Value<String?> productName,
      required int partnerProductId,
      Value<int> quantity,
      Value<double> basePrice,
      Value<double?> cogs,
      Value<double> optionsPrice,
      Value<String?> customerNote,
      Value<int?> promoId,
      Value<double?> promoAmount,
      Value<String?> promoType,
      Value<String?> status,
      Value<int?> cashierProcessId,
      Value<int?> kitchenProcessId,
      Value<int> syncVersion,
      Value<bool> syncDirty,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$OrderDetailsTableUpdateCompanionBuilder =
    OrderDetailsCompanion Function({
      Value<String> clientDetailUuid,
      Value<int?> serverId,
      Value<String> bookingOrderClientUuid,
      Value<int?> bookingOrderServerId,
      Value<String?> productCode,
      Value<String?> productName,
      Value<int> partnerProductId,
      Value<int> quantity,
      Value<double> basePrice,
      Value<double?> cogs,
      Value<double> optionsPrice,
      Value<String?> customerNote,
      Value<int?> promoId,
      Value<double?> promoAmount,
      Value<String?> promoType,
      Value<String?> status,
      Value<int?> cashierProcessId,
      Value<int?> kitchenProcessId,
      Value<int> syncVersion,
      Value<bool> syncDirty,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$OrderDetailsTableFilterComposer
    extends Composer<_$CashierDb, $OrderDetailsTable> {
  $$OrderDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientDetailUuid => $composableBuilder(
    column: $table.clientDetailUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partnerProductId => $composableBuilder(
    column: $table.partnerProductId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cogs => $composableBuilder(
    column: $table.cogs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promoId => $composableBuilder(
    column: $table.promoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promoType => $composableBuilder(
    column: $table.promoType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderDetailsTableOrderingComposer
    extends Composer<_$CashierDb, $OrderDetailsTable> {
  $$OrderDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientDetailUuid => $composableBuilder(
    column: $table.clientDetailUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partnerProductId => $composableBuilder(
    column: $table.partnerProductId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cogs => $composableBuilder(
    column: $table.cogs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promoId => $composableBuilder(
    column: $table.promoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promoType => $composableBuilder(
    column: $table.promoType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderDetailsTableAnnotationComposer
    extends Composer<_$CashierDb, $OrderDetailsTable> {
  $$OrderDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientDetailUuid => $composableBuilder(
    column: $table.clientDetailUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partnerProductId => $composableBuilder(
    column: $table.partnerProductId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<double> get cogs =>
      $composableBuilder(column: $table.cogs, builder: (column) => column);

  GeneratedColumn<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get promoId =>
      $composableBuilder(column: $table.promoId, builder: (column) => column);

  GeneratedColumn<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promoType =>
      $composableBuilder(column: $table.promoType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get cashierProcessId => $composableBuilder(
    column: $table.cashierProcessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kitchenProcessId => $composableBuilder(
    column: $table.kitchenProcessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncDirty =>
      $composableBuilder(column: $table.syncDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrderDetailsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $OrderDetailsTable,
          OrderDetail,
          $$OrderDetailsTableFilterComposer,
          $$OrderDetailsTableOrderingComposer,
          $$OrderDetailsTableAnnotationComposer,
          $$OrderDetailsTableCreateCompanionBuilder,
          $$OrderDetailsTableUpdateCompanionBuilder,
          (
            OrderDetail,
            BaseReferences<_$CashierDb, $OrderDetailsTable, OrderDetail>,
          ),
          OrderDetail,
          PrefetchHooks Function()
        > {
  $$OrderDetailsTableTableManager(_$CashierDb db, $OrderDetailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientDetailUuid = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> bookingOrderClientUuid = const Value.absent(),
                Value<int?> bookingOrderServerId = const Value.absent(),
                Value<String?> productCode = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<int> partnerProductId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> basePrice = const Value.absent(),
                Value<double?> cogs = const Value.absent(),
                Value<double> optionsPrice = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<double?> promoAmount = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> cashierProcessId = const Value.absent(),
                Value<int?> kitchenProcessId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderDetailsCompanion(
                clientDetailUuid: clientDetailUuid,
                serverId: serverId,
                bookingOrderClientUuid: bookingOrderClientUuid,
                bookingOrderServerId: bookingOrderServerId,
                productCode: productCode,
                productName: productName,
                partnerProductId: partnerProductId,
                quantity: quantity,
                basePrice: basePrice,
                cogs: cogs,
                optionsPrice: optionsPrice,
                customerNote: customerNote,
                promoId: promoId,
                promoAmount: promoAmount,
                promoType: promoType,
                status: status,
                cashierProcessId: cashierProcessId,
                kitchenProcessId: kitchenProcessId,
                syncVersion: syncVersion,
                syncDirty: syncDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientDetailUuid,
                Value<int?> serverId = const Value.absent(),
                required String bookingOrderClientUuid,
                Value<int?> bookingOrderServerId = const Value.absent(),
                Value<String?> productCode = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                required int partnerProductId,
                Value<int> quantity = const Value.absent(),
                Value<double> basePrice = const Value.absent(),
                Value<double?> cogs = const Value.absent(),
                Value<double> optionsPrice = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<double?> promoAmount = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> cashierProcessId = const Value.absent(),
                Value<int?> kitchenProcessId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderDetailsCompanion.insert(
                clientDetailUuid: clientDetailUuid,
                serverId: serverId,
                bookingOrderClientUuid: bookingOrderClientUuid,
                bookingOrderServerId: bookingOrderServerId,
                productCode: productCode,
                productName: productName,
                partnerProductId: partnerProductId,
                quantity: quantity,
                basePrice: basePrice,
                cogs: cogs,
                optionsPrice: optionsPrice,
                customerNote: customerNote,
                promoId: promoId,
                promoAmount: promoAmount,
                promoType: promoType,
                status: status,
                cashierProcessId: cashierProcessId,
                kitchenProcessId: kitchenProcessId,
                syncVersion: syncVersion,
                syncDirty: syncDirty,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $OrderDetailsTable,
      OrderDetail,
      $$OrderDetailsTableFilterComposer,
      $$OrderDetailsTableOrderingComposer,
      $$OrderDetailsTableAnnotationComposer,
      $$OrderDetailsTableCreateCompanionBuilder,
      $$OrderDetailsTableUpdateCompanionBuilder,
      (
        OrderDetail,
        BaseReferences<_$CashierDb, $OrderDetailsTable, OrderDetail>,
      ),
      OrderDetail,
      PrefetchHooks Function()
    >;
typedef $$OrderDetailOptionsTableCreateCompanionBuilder =
    OrderDetailOptionsCompanion Function({
      required String clientOptionUuid,
      Value<int?> serverId,
      required String orderDetailClientUuid,
      Value<int?> orderDetailServerId,
      required int optionId,
      Value<String?> parentName,
      Value<String?> partnerProductOptionName,
      Value<double> price,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$OrderDetailOptionsTableUpdateCompanionBuilder =
    OrderDetailOptionsCompanion Function({
      Value<String> clientOptionUuid,
      Value<int?> serverId,
      Value<String> orderDetailClientUuid,
      Value<int?> orderDetailServerId,
      Value<int> optionId,
      Value<String?> parentName,
      Value<String?> partnerProductOptionName,
      Value<double> price,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$OrderDetailOptionsTableFilterComposer
    extends Composer<_$CashierDb, $OrderDetailOptionsTable> {
  $$OrderDetailOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOptionUuid => $composableBuilder(
    column: $table.clientOptionUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderDetailClientUuid => $composableBuilder(
    column: $table.orderDetailClientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partnerProductOptionName => $composableBuilder(
    column: $table.partnerProductOptionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderDetailOptionsTableOrderingComposer
    extends Composer<_$CashierDb, $OrderDetailOptionsTable> {
  $$OrderDetailOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOptionUuid => $composableBuilder(
    column: $table.clientOptionUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderDetailClientUuid => $composableBuilder(
    column: $table.orderDetailClientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partnerProductOptionName => $composableBuilder(
    column: $table.partnerProductOptionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderDetailOptionsTableAnnotationComposer
    extends Composer<_$CashierDb, $OrderDetailOptionsTable> {
  $$OrderDetailOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOptionUuid => $composableBuilder(
    column: $table.clientOptionUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get orderDetailClientUuid => $composableBuilder(
    column: $table.orderDetailClientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get optionId =>
      $composableBuilder(column: $table.optionId, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partnerProductOptionName => $composableBuilder(
    column: $table.partnerProductOptionName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrderDetailOptionsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $OrderDetailOptionsTable,
          OrderDetailOption,
          $$OrderDetailOptionsTableFilterComposer,
          $$OrderDetailOptionsTableOrderingComposer,
          $$OrderDetailOptionsTableAnnotationComposer,
          $$OrderDetailOptionsTableCreateCompanionBuilder,
          $$OrderDetailOptionsTableUpdateCompanionBuilder,
          (
            OrderDetailOption,
            BaseReferences<
              _$CashierDb,
              $OrderDetailOptionsTable,
              OrderDetailOption
            >,
          ),
          OrderDetailOption,
          PrefetchHooks Function()
        > {
  $$OrderDetailOptionsTableTableManager(
    _$CashierDb db,
    $OrderDetailOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderDetailOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderDetailOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderDetailOptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientOptionUuid = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> orderDetailClientUuid = const Value.absent(),
                Value<int?> orderDetailServerId = const Value.absent(),
                Value<int> optionId = const Value.absent(),
                Value<String?> parentName = const Value.absent(),
                Value<String?> partnerProductOptionName = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderDetailOptionsCompanion(
                clientOptionUuid: clientOptionUuid,
                serverId: serverId,
                orderDetailClientUuid: orderDetailClientUuid,
                orderDetailServerId: orderDetailServerId,
                optionId: optionId,
                parentName: parentName,
                partnerProductOptionName: partnerProductOptionName,
                price: price,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOptionUuid,
                Value<int?> serverId = const Value.absent(),
                required String orderDetailClientUuid,
                Value<int?> orderDetailServerId = const Value.absent(),
                required int optionId,
                Value<String?> parentName = const Value.absent(),
                Value<String?> partnerProductOptionName = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderDetailOptionsCompanion.insert(
                clientOptionUuid: clientOptionUuid,
                serverId: serverId,
                orderDetailClientUuid: orderDetailClientUuid,
                orderDetailServerId: orderDetailServerId,
                optionId: optionId,
                parentName: parentName,
                partnerProductOptionName: partnerProductOptionName,
                price: price,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderDetailOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $OrderDetailOptionsTable,
      OrderDetailOption,
      $$OrderDetailOptionsTableFilterComposer,
      $$OrderDetailOptionsTableOrderingComposer,
      $$OrderDetailOptionsTableAnnotationComposer,
      $$OrderDetailOptionsTableCreateCompanionBuilder,
      $$OrderDetailOptionsTableUpdateCompanionBuilder,
      (
        OrderDetailOption,
        BaseReferences<
          _$CashierDb,
          $OrderDetailOptionsTable,
          OrderDetailOption
        >,
      ),
      OrderDetailOption,
      PrefetchHooks Function()
    >;
typedef $$OrderPaymentsTableCreateCompanionBuilder =
    OrderPaymentsCompanion Function({
      required String clientPaymentUuid,
      Value<int?> serverId,
      required String bookingOrderClientUuid,
      Value<int?> bookingOrderServerId,
      Value<int?> employeeId,
      Value<int?> customerId,
      Value<String?> customerName,
      required String paymentType,
      Value<double> paidAmount,
      Value<double> changeAmount,
      Value<String> paymentStatus,
      Value<String?> note,
      Value<double?> ppn,
      Value<double?> amountBeforePpn,
      Value<double?> roundingAmount,
      Value<int?> ownerManualPaymentId,
      Value<String?> manualProviderName,
      Value<String?> manualProviderAccountName,
      Value<String?> manualProviderAccountNo,
      Value<bool> syncDirty,
      Value<String?> localFilePathsJson,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$OrderPaymentsTableUpdateCompanionBuilder =
    OrderPaymentsCompanion Function({
      Value<String> clientPaymentUuid,
      Value<int?> serverId,
      Value<String> bookingOrderClientUuid,
      Value<int?> bookingOrderServerId,
      Value<int?> employeeId,
      Value<int?> customerId,
      Value<String?> customerName,
      Value<String> paymentType,
      Value<double> paidAmount,
      Value<double> changeAmount,
      Value<String> paymentStatus,
      Value<String?> note,
      Value<double?> ppn,
      Value<double?> amountBeforePpn,
      Value<double?> roundingAmount,
      Value<int?> ownerManualPaymentId,
      Value<String?> manualProviderName,
      Value<String?> manualProviderAccountName,
      Value<String?> manualProviderAccountNo,
      Value<bool> syncDirty,
      Value<String?> localFilePathsJson,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$OrderPaymentsTableFilterComposer
    extends Composer<_$CashierDb, $OrderPaymentsTable> {
  $$OrderPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientPaymentUuid => $composableBuilder(
    column: $table.clientPaymentUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get roundingAmount => $composableBuilder(
    column: $table.roundingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ownerManualPaymentId => $composableBuilder(
    column: $table.ownerManualPaymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualProviderName => $composableBuilder(
    column: $table.manualProviderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualProviderAccountName => $composableBuilder(
    column: $table.manualProviderAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualProviderAccountNo => $composableBuilder(
    column: $table.manualProviderAccountNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderPaymentsTableOrderingComposer
    extends Composer<_$CashierDb, $OrderPaymentsTable> {
  $$OrderPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientPaymentUuid => $composableBuilder(
    column: $table.clientPaymentUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get roundingAmount => $composableBuilder(
    column: $table.roundingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ownerManualPaymentId => $composableBuilder(
    column: $table.ownerManualPaymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualProviderName => $composableBuilder(
    column: $table.manualProviderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualProviderAccountName => $composableBuilder(
    column: $table.manualProviderAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualProviderAccountNo => $composableBuilder(
    column: $table.manualProviderAccountNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncDirty => $composableBuilder(
    column: $table.syncDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderPaymentsTableAnnotationComposer
    extends Composer<_$CashierDb, $OrderPaymentsTable> {
  $$OrderPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientPaymentUuid => $composableBuilder(
    column: $table.clientPaymentUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderClientUuid => $composableBuilder(
    column: $table.bookingOrderClientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bookingOrderServerId => $composableBuilder(
    column: $table.bookingOrderServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get ppn =>
      $composableBuilder(column: $table.ppn, builder: (column) => column);

  GeneratedColumn<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get roundingAmount => $composableBuilder(
    column: $table.roundingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ownerManualPaymentId => $composableBuilder(
    column: $table.ownerManualPaymentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualProviderName => $composableBuilder(
    column: $table.manualProviderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualProviderAccountName => $composableBuilder(
    column: $table.manualProviderAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualProviderAccountNo => $composableBuilder(
    column: $table.manualProviderAccountNo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncDirty =>
      $composableBuilder(column: $table.syncDirty, builder: (column) => column);

  GeneratedColumn<String> get localFilePathsJson => $composableBuilder(
    column: $table.localFilePathsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrderPaymentsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $OrderPaymentsTable,
          OrderPayment,
          $$OrderPaymentsTableFilterComposer,
          $$OrderPaymentsTableOrderingComposer,
          $$OrderPaymentsTableAnnotationComposer,
          $$OrderPaymentsTableCreateCompanionBuilder,
          $$OrderPaymentsTableUpdateCompanionBuilder,
          (
            OrderPayment,
            BaseReferences<_$CashierDb, $OrderPaymentsTable, OrderPayment>,
          ),
          OrderPayment,
          PrefetchHooks Function()
        > {
  $$OrderPaymentsTableTableManager(_$CashierDb db, $OrderPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientPaymentUuid = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> bookingOrderClientUuid = const Value.absent(),
                Value<int?> bookingOrderServerId = const Value.absent(),
                Value<int?> employeeId = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String> paymentType = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<double?> ppn = const Value.absent(),
                Value<double?> amountBeforePpn = const Value.absent(),
                Value<double?> roundingAmount = const Value.absent(),
                Value<int?> ownerManualPaymentId = const Value.absent(),
                Value<String?> manualProviderName = const Value.absent(),
                Value<String?> manualProviderAccountName = const Value.absent(),
                Value<String?> manualProviderAccountNo = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<String?> localFilePathsJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderPaymentsCompanion(
                clientPaymentUuid: clientPaymentUuid,
                serverId: serverId,
                bookingOrderClientUuid: bookingOrderClientUuid,
                bookingOrderServerId: bookingOrderServerId,
                employeeId: employeeId,
                customerId: customerId,
                customerName: customerName,
                paymentType: paymentType,
                paidAmount: paidAmount,
                changeAmount: changeAmount,
                paymentStatus: paymentStatus,
                note: note,
                ppn: ppn,
                amountBeforePpn: amountBeforePpn,
                roundingAmount: roundingAmount,
                ownerManualPaymentId: ownerManualPaymentId,
                manualProviderName: manualProviderName,
                manualProviderAccountName: manualProviderAccountName,
                manualProviderAccountNo: manualProviderAccountNo,
                syncDirty: syncDirty,
                localFilePathsJson: localFilePathsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientPaymentUuid,
                Value<int?> serverId = const Value.absent(),
                required String bookingOrderClientUuid,
                Value<int?> bookingOrderServerId = const Value.absent(),
                Value<int?> employeeId = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                required String paymentType,
                Value<double> paidAmount = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<double?> ppn = const Value.absent(),
                Value<double?> amountBeforePpn = const Value.absent(),
                Value<double?> roundingAmount = const Value.absent(),
                Value<int?> ownerManualPaymentId = const Value.absent(),
                Value<String?> manualProviderName = const Value.absent(),
                Value<String?> manualProviderAccountName = const Value.absent(),
                Value<String?> manualProviderAccountNo = const Value.absent(),
                Value<bool> syncDirty = const Value.absent(),
                Value<String?> localFilePathsJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderPaymentsCompanion.insert(
                clientPaymentUuid: clientPaymentUuid,
                serverId: serverId,
                bookingOrderClientUuid: bookingOrderClientUuid,
                bookingOrderServerId: bookingOrderServerId,
                employeeId: employeeId,
                customerId: customerId,
                customerName: customerName,
                paymentType: paymentType,
                paidAmount: paidAmount,
                changeAmount: changeAmount,
                paymentStatus: paymentStatus,
                note: note,
                ppn: ppn,
                amountBeforePpn: amountBeforePpn,
                roundingAmount: roundingAmount,
                ownerManualPaymentId: ownerManualPaymentId,
                manualProviderName: manualProviderName,
                manualProviderAccountName: manualProviderAccountName,
                manualProviderAccountNo: manualProviderAccountNo,
                syncDirty: syncDirty,
                localFilePathsJson: localFilePathsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $OrderPaymentsTable,
      OrderPayment,
      $$OrderPaymentsTableFilterComposer,
      $$OrderPaymentsTableOrderingComposer,
      $$OrderPaymentsTableAnnotationComposer,
      $$OrderPaymentsTableCreateCompanionBuilder,
      $$OrderPaymentsTableUpdateCompanionBuilder,
      (
        OrderPayment,
        BaseReferences<_$CashierDb, $OrderPaymentsTable, OrderPayment>,
      ),
      OrderPayment,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      required String entityTable,
      Value<int?> serverId,
      Value<String?> clientUuid,
      required String reason,
      Value<String?> localSnapshotJson,
      Value<String?> serverSnapshotJson,
      Value<String?> suggestedResolution,
      Value<bool> isResolved,
      Value<String?> resolutionChoice,
      required DateTime createdAt,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      Value<String> entityTable,
      Value<int?> serverId,
      Value<String?> clientUuid,
      Value<String> reason,
      Value<String?> localSnapshotJson,
      Value<String?> serverSnapshotJson,
      Value<String?> suggestedResolution,
      Value<bool> isResolved,
      Value<String?> resolutionChoice,
      Value<DateTime> createdAt,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$CashierDb, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localSnapshotJson => $composableBuilder(
    column: $table.localSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestedResolution => $composableBuilder(
    column: $table.suggestedResolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$CashierDb, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localSnapshotJson => $composableBuilder(
    column: $table.localSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedResolution => $composableBuilder(
    column: $table.suggestedResolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$CashierDb, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get localSnapshotJson => $composableBuilder(
    column: $table.localSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverSnapshotJson => $composableBuilder(
    column: $table.serverSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestedResolution => $composableBuilder(
    column: $table.suggestedResolution,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $SyncConflictsTable,
          SyncConflict,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflict,
            BaseReferences<_$CashierDb, $SyncConflictsTable, SyncConflict>,
          ),
          SyncConflict,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$CashierDb db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientUuid = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> localSnapshotJson = const Value.absent(),
                Value<String?> serverSnapshotJson = const Value.absent(),
                Value<String?> suggestedResolution = const Value.absent(),
                Value<bool> isResolved = const Value.absent(),
                Value<String?> resolutionChoice = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                entityTable: entityTable,
                serverId: serverId,
                clientUuid: clientUuid,
                reason: reason,
                localSnapshotJson: localSnapshotJson,
                serverSnapshotJson: serverSnapshotJson,
                suggestedResolution: suggestedResolution,
                isResolved: isResolved,
                resolutionChoice: resolutionChoice,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityTable,
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientUuid = const Value.absent(),
                required String reason,
                Value<String?> localSnapshotJson = const Value.absent(),
                Value<String?> serverSnapshotJson = const Value.absent(),
                Value<String?> suggestedResolution = const Value.absent(),
                Value<bool> isResolved = const Value.absent(),
                Value<String?> resolutionChoice = const Value.absent(),
                required DateTime createdAt,
              }) => SyncConflictsCompanion.insert(
                id: id,
                entityTable: entityTable,
                serverId: serverId,
                clientUuid: clientUuid,
                reason: reason,
                localSnapshotJson: localSnapshotJson,
                serverSnapshotJson: serverSnapshotJson,
                suggestedResolution: suggestedResolution,
                isResolved: isResolved,
                resolutionChoice: resolutionChoice,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $SyncConflictsTable,
      SyncConflict,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflict,
        BaseReferences<_$CashierDb, $SyncConflictsTable, SyncConflict>,
      ),
      SyncConflict,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$CashierDb, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$CashierDb, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$CashierDb, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$CashierDb, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$CashierDb db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaData, BaseReferences<_$CashierDb, $SyncMetaTable, SyncMetaData>),
      SyncMetaData,
      PrefetchHooks Function()
    >;

class $CashierDbManager {
  final _$CashierDb _db;
  $CashierDbManager(this._db);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(_db, _db.cachedProducts);
  $$CachedOptionGroupsTableTableManager get cachedOptionGroups =>
      $$CachedOptionGroupsTableTableManager(_db, _db.cachedOptionGroups);
  $$CachedOptionItemsTableTableManager get cachedOptionItems =>
      $$CachedOptionItemsTableTableManager(_db, _db.cachedOptionItems);
  $$CachedTablesTableTableManager get cachedTables =>
      $$CachedTablesTableTableManager(_db, _db.cachedTables);
  $$CachedPaymentMethodsTableTableManager get cachedPaymentMethods =>
      $$CachedPaymentMethodsTableTableManager(_db, _db.cachedPaymentMethods);
  $$CachedPartnerSettingsTableTableManager get cachedPartnerSettings =>
      $$CachedPartnerSettingsTableTableManager(_db, _db.cachedPartnerSettings);
  $$BookingOrdersTableTableManager get bookingOrders =>
      $$BookingOrdersTableTableManager(_db, _db.bookingOrders);
  $$OrderDetailsTableTableManager get orderDetails =>
      $$OrderDetailsTableTableManager(_db, _db.orderDetails);
  $$OrderDetailOptionsTableTableManager get orderDetailOptions =>
      $$OrderDetailOptionsTableTableManager(_db, _db.orderDetailOptions);
  $$OrderPaymentsTableTableManager get orderPayments =>
      $$OrderPaymentsTableTableManager(_db, _db.orderPayments);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
