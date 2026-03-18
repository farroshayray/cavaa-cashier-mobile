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

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
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
  static const VerificationMeta _clientOrderCodeMeta = const VerificationMeta(
    'clientOrderCode',
  );
  @override
  late final GeneratedColumn<String> clientOrderCode = GeneratedColumn<String>(
    'client_order_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _serverOrderCodeMeta = const VerificationMeta(
    'serverOrderCode',
  );
  @override
  late final GeneratedColumn<String> serverOrderCode = GeneratedColumn<String>(
    'server_order_code',
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
  static const VerificationMeta _tableServerIdMeta = const VerificationMeta(
    'tableServerId',
  );
  @override
  late final GeneratedColumn<int> tableServerId = GeneratedColumn<int>(
    'table_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableNoSnapshotMeta = const VerificationMeta(
    'tableNoSnapshot',
  );
  @override
  late final GeneratedColumn<String> tableNoSnapshot = GeneratedColumn<String>(
    'table_no_snapshot',
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
  static const VerificationMeta _paymentMethodSelectedMeta =
      const VerificationMeta('paymentMethodSelected');
  @override
  late final GeneratedColumn<String> paymentMethodSelected =
      GeneratedColumn<String>(
        'payment_method_selected',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentMethodEffectiveMeta =
      const VerificationMeta('paymentMethodEffective');
  @override
  late final GeneratedColumn<String> paymentMethodEffective =
      GeneratedColumn<String>(
        'payment_method_effective',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _ppnPercentMeta = const VerificationMeta(
    'ppnPercent',
  );
  @override
  late final GeneratedColumn<double> ppnPercent = GeneratedColumn<double>(
    'ppn_percent',
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
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _cashierProofImageLocalPathMeta =
      const VerificationMeta('cashierProofImageLocalPath');
  @override
  late final GeneratedColumn<String> cashierProofImageLocalPath =
      GeneratedColumn<String>(
        'cashier_proof_image_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentConfirmedAtLocalMeta =
      const VerificationMeta('paymentConfirmedAtLocal');
  @override
  late final GeneratedColumn<DateTime> paymentConfirmedAtLocal =
      GeneratedColumn<DateTime>(
        'payment_confirmed_at_local',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
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
  static const VerificationMeta _orderSnapshotJsonMeta = const VerificationMeta(
    'orderSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> orderSnapshotJson =
      GeneratedColumn<String>(
        'order_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _orderStatusLocalMeta = const VerificationMeta(
    'orderStatusLocal',
  );
  @override
  late final GeneratedColumn<String> orderStatusLocal = GeneratedColumn<String>(
    'order_status_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('DRAFT'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualPaymentServerIdMeta =
      const VerificationMeta('manualPaymentServerId');
  @override
  late final GeneratedColumn<int> manualPaymentServerId = GeneratedColumn<int>(
    'manual_payment_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualPaymentTypeMeta = const VerificationMeta(
    'manualPaymentType',
  );
  @override
  late final GeneratedColumn<String> manualPaymentType =
      GeneratedColumn<String>(
        'manual_payment_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
  static const VerificationMeta _manualQrisImageUrlMeta =
      const VerificationMeta('manualQrisImageUrl');
  @override
  late final GeneratedColumn<String> manualQrisImageUrl =
      GeneratedColumn<String>(
        'manual_qris_image_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _manualQrisImageLocalPathMeta =
      const VerificationMeta('manualQrisImageLocalPath');
  @override
  late final GeneratedColumn<String> manualQrisImageLocalPath =
      GeneratedColumn<String>(
        'manual_qris_image_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _manualPaymentLabelMeta =
      const VerificationMeta('manualPaymentLabel');
  @override
  late final GeneratedColumn<String> manualPaymentLabel =
      GeneratedColumn<String>(
        'manual_payment_label',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _manualPaymentRawJsonMeta =
      const VerificationMeta('manualPaymentRawJson');
  @override
  late final GeneratedColumn<String> manualPaymentRawJson =
      GeneratedColumn<String>(
        'manual_payment_raw_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backendSyncStageMeta = const VerificationMeta(
    'backendSyncStage',
  );
  @override
  late final GeneratedColumn<String> backendSyncStage = GeneratedColumn<String>(
    'backend_sync_stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NONE'),
  );
  static const VerificationMeta _createdAtLocalMeta = const VerificationMeta(
    'createdAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtLocal =
      GeneratedColumn<DateTime>(
        'created_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtLocalMeta = const VerificationMeta(
    'updatedAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtLocal =
      GeneratedColumn<DateTime>(
        'updated_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
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
    localId,
    serverId,
    clientOrderCode,
    serverOrderCode,
    partnerId,
    partnerName,
    tableServerId,
    tableNoSnapshot,
    customerName,
    paymentMethodSelected,
    paymentMethodEffective,
    subtotal,
    discountValue,
    ppnPercent,
    isPpnActive,
    grandTotal,
    paidAmountLocal,
    changeAmountLocal,
    cashierProofImageLocalPath,
    paymentConfirmedAtLocal,
    latestPaymentServerId,
    orderSnapshotJson,
    orderStatusLocal,
    syncStatus,
    lastError,
    manualPaymentServerId,
    manualPaymentType,
    manualProviderName,
    manualProviderAccountName,
    manualProviderAccountNo,
    manualQrisImageUrl,
    manualQrisImageLocalPath,
    manualPaymentLabel,
    manualPaymentRawJson,
    backendSyncStage,
    createdAtLocal,
    updatedAtLocal,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('client_order_code')) {
      context.handle(
        _clientOrderCodeMeta,
        clientOrderCode.isAcceptableOrUnknown(
          data['client_order_code']!,
          _clientOrderCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOrderCodeMeta);
    }
    if (data.containsKey('server_order_code')) {
      context.handle(
        _serverOrderCodeMeta,
        serverOrderCode.isAcceptableOrUnknown(
          data['server_order_code']!,
          _serverOrderCodeMeta,
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
    if (data.containsKey('table_server_id')) {
      context.handle(
        _tableServerIdMeta,
        tableServerId.isAcceptableOrUnknown(
          data['table_server_id']!,
          _tableServerIdMeta,
        ),
      );
    }
    if (data.containsKey('table_no_snapshot')) {
      context.handle(
        _tableNoSnapshotMeta,
        tableNoSnapshot.isAcceptableOrUnknown(
          data['table_no_snapshot']!,
          _tableNoSnapshotMeta,
        ),
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
    if (data.containsKey('payment_method_selected')) {
      context.handle(
        _paymentMethodSelectedMeta,
        paymentMethodSelected.isAcceptableOrUnknown(
          data['payment_method_selected']!,
          _paymentMethodSelectedMeta,
        ),
      );
    }
    if (data.containsKey('payment_method_effective')) {
      context.handle(
        _paymentMethodEffectiveMeta,
        paymentMethodEffective.isAcceptableOrUnknown(
          data['payment_method_effective']!,
          _paymentMethodEffectiveMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
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
    if (data.containsKey('ppn_percent')) {
      context.handle(
        _ppnPercentMeta,
        ppnPercent.isAcceptableOrUnknown(data['ppn_percent']!, _ppnPercentMeta),
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
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
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
    if (data.containsKey('cashier_proof_image_local_path')) {
      context.handle(
        _cashierProofImageLocalPathMeta,
        cashierProofImageLocalPath.isAcceptableOrUnknown(
          data['cashier_proof_image_local_path']!,
          _cashierProofImageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('payment_confirmed_at_local')) {
      context.handle(
        _paymentConfirmedAtLocalMeta,
        paymentConfirmedAtLocal.isAcceptableOrUnknown(
          data['payment_confirmed_at_local']!,
          _paymentConfirmedAtLocalMeta,
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
    if (data.containsKey('order_snapshot_json')) {
      context.handle(
        _orderSnapshotJsonMeta,
        orderSnapshotJson.isAcceptableOrUnknown(
          data['order_snapshot_json']!,
          _orderSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('order_status_local')) {
      context.handle(
        _orderStatusLocalMeta,
        orderStatusLocal.isAcceptableOrUnknown(
          data['order_status_local']!,
          _orderStatusLocalMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('manual_payment_server_id')) {
      context.handle(
        _manualPaymentServerIdMeta,
        manualPaymentServerId.isAcceptableOrUnknown(
          data['manual_payment_server_id']!,
          _manualPaymentServerIdMeta,
        ),
      );
    }
    if (data.containsKey('manual_payment_type')) {
      context.handle(
        _manualPaymentTypeMeta,
        manualPaymentType.isAcceptableOrUnknown(
          data['manual_payment_type']!,
          _manualPaymentTypeMeta,
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
    if (data.containsKey('manual_qris_image_url')) {
      context.handle(
        _manualQrisImageUrlMeta,
        manualQrisImageUrl.isAcceptableOrUnknown(
          data['manual_qris_image_url']!,
          _manualQrisImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('manual_qris_image_local_path')) {
      context.handle(
        _manualQrisImageLocalPathMeta,
        manualQrisImageLocalPath.isAcceptableOrUnknown(
          data['manual_qris_image_local_path']!,
          _manualQrisImageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('manual_payment_label')) {
      context.handle(
        _manualPaymentLabelMeta,
        manualPaymentLabel.isAcceptableOrUnknown(
          data['manual_payment_label']!,
          _manualPaymentLabelMeta,
        ),
      );
    }
    if (data.containsKey('manual_payment_raw_json')) {
      context.handle(
        _manualPaymentRawJsonMeta,
        manualPaymentRawJson.isAcceptableOrUnknown(
          data['manual_payment_raw_json']!,
          _manualPaymentRawJsonMeta,
        ),
      );
    }
    if (data.containsKey('backend_sync_stage')) {
      context.handle(
        _backendSyncStageMeta,
        backendSyncStage.isAcceptableOrUnknown(
          data['backend_sync_stage']!,
          _backendSyncStageMeta,
        ),
      );
    }
    if (data.containsKey('created_at_local')) {
      context.handle(
        _createdAtLocalMeta,
        createdAtLocal.isAcceptableOrUnknown(
          data['created_at_local']!,
          _createdAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtLocalMeta);
    }
    if (data.containsKey('updated_at_local')) {
      context.handle(
        _updatedAtLocalMeta,
        updatedAtLocal.isAcceptableOrUnknown(
          data['updated_at_local']!,
          _updatedAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtLocalMeta);
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
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrder(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      clientOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_order_code'],
      )!,
      serverOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_order_code'],
      ),
      partnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partner_id'],
      ),
      partnerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partner_name'],
      ),
      tableServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}table_server_id'],
      ),
      tableNoSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no_snapshot'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      paymentMethodSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_selected'],
      ),
      paymentMethodEffective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_effective'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      )!,
      ppnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn_percent'],
      )!,
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total'],
      )!,
      paidAmountLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount_local'],
      ),
      changeAmountLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change_amount_local'],
      ),
      cashierProofImageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_proof_image_local_path'],
      ),
      paymentConfirmedAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_confirmed_at_local'],
      ),
      latestPaymentServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_payment_server_id'],
      ),
      orderSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_snapshot_json'],
      ),
      orderStatusLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status_local'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      manualPaymentServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_payment_server_id'],
      ),
      manualPaymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_payment_type'],
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
      manualQrisImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_qris_image_url'],
      ),
      manualQrisImageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_qris_image_local_path'],
      ),
      manualPaymentLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_payment_label'],
      ),
      manualPaymentRawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_payment_raw_json'],
      ),
      backendSyncStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_sync_stage'],
      )!,
      createdAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_local'],
      )!,
      updatedAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_local'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrder extends DataClass implements Insertable<LocalOrder> {
  final String localId;
  final int? serverId;
  final String clientOrderCode;
  final String? serverOrderCode;
  final int? partnerId;
  final String? partnerName;
  final int? tableServerId;
  final String? tableNoSnapshot;
  final String customerName;
  final String? paymentMethodSelected;
  final String? paymentMethodEffective;
  final double subtotal;
  final double discountValue;
  final double ppnPercent;
  final bool isPpnActive;
  final double grandTotal;
  final double? paidAmountLocal;
  final double? changeAmountLocal;
  final String? cashierProofImageLocalPath;
  final DateTime? paymentConfirmedAtLocal;
  final int? latestPaymentServerId;
  final String? orderSnapshotJson;
  final String orderStatusLocal;
  final String syncStatus;
  final String? lastError;
  final int? manualPaymentServerId;
  final String? manualPaymentType;
  final String? manualProviderName;
  final String? manualProviderAccountName;
  final String? manualProviderAccountNo;
  final String? manualQrisImageUrl;
  final String? manualQrisImageLocalPath;
  final String? manualPaymentLabel;
  final String? manualPaymentRawJson;
  final String backendSyncStage;
  final DateTime createdAtLocal;
  final DateTime updatedAtLocal;
  final DateTime? syncedAt;
  const LocalOrder({
    required this.localId,
    this.serverId,
    required this.clientOrderCode,
    this.serverOrderCode,
    this.partnerId,
    this.partnerName,
    this.tableServerId,
    this.tableNoSnapshot,
    required this.customerName,
    this.paymentMethodSelected,
    this.paymentMethodEffective,
    required this.subtotal,
    required this.discountValue,
    required this.ppnPercent,
    required this.isPpnActive,
    required this.grandTotal,
    this.paidAmountLocal,
    this.changeAmountLocal,
    this.cashierProofImageLocalPath,
    this.paymentConfirmedAtLocal,
    this.latestPaymentServerId,
    this.orderSnapshotJson,
    required this.orderStatusLocal,
    required this.syncStatus,
    this.lastError,
    this.manualPaymentServerId,
    this.manualPaymentType,
    this.manualProviderName,
    this.manualProviderAccountName,
    this.manualProviderAccountNo,
    this.manualQrisImageUrl,
    this.manualQrisImageLocalPath,
    this.manualPaymentLabel,
    this.manualPaymentRawJson,
    required this.backendSyncStage,
    required this.createdAtLocal,
    required this.updatedAtLocal,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['client_order_code'] = Variable<String>(clientOrderCode);
    if (!nullToAbsent || serverOrderCode != null) {
      map['server_order_code'] = Variable<String>(serverOrderCode);
    }
    if (!nullToAbsent || partnerId != null) {
      map['partner_id'] = Variable<int>(partnerId);
    }
    if (!nullToAbsent || partnerName != null) {
      map['partner_name'] = Variable<String>(partnerName);
    }
    if (!nullToAbsent || tableServerId != null) {
      map['table_server_id'] = Variable<int>(tableServerId);
    }
    if (!nullToAbsent || tableNoSnapshot != null) {
      map['table_no_snapshot'] = Variable<String>(tableNoSnapshot);
    }
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || paymentMethodSelected != null) {
      map['payment_method_selected'] = Variable<String>(paymentMethodSelected);
    }
    if (!nullToAbsent || paymentMethodEffective != null) {
      map['payment_method_effective'] = Variable<String>(
        paymentMethodEffective,
      );
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_value'] = Variable<double>(discountValue);
    map['ppn_percent'] = Variable<double>(ppnPercent);
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    map['grand_total'] = Variable<double>(grandTotal);
    if (!nullToAbsent || paidAmountLocal != null) {
      map['paid_amount_local'] = Variable<double>(paidAmountLocal);
    }
    if (!nullToAbsent || changeAmountLocal != null) {
      map['change_amount_local'] = Variable<double>(changeAmountLocal);
    }
    if (!nullToAbsent || cashierProofImageLocalPath != null) {
      map['cashier_proof_image_local_path'] = Variable<String>(
        cashierProofImageLocalPath,
      );
    }
    if (!nullToAbsent || paymentConfirmedAtLocal != null) {
      map['payment_confirmed_at_local'] = Variable<DateTime>(
        paymentConfirmedAtLocal,
      );
    }
    if (!nullToAbsent || latestPaymentServerId != null) {
      map['latest_payment_server_id'] = Variable<int>(latestPaymentServerId);
    }
    if (!nullToAbsent || orderSnapshotJson != null) {
      map['order_snapshot_json'] = Variable<String>(orderSnapshotJson);
    }
    map['order_status_local'] = Variable<String>(orderStatusLocal);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || manualPaymentServerId != null) {
      map['manual_payment_server_id'] = Variable<int>(manualPaymentServerId);
    }
    if (!nullToAbsent || manualPaymentType != null) {
      map['manual_payment_type'] = Variable<String>(manualPaymentType);
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
    if (!nullToAbsent || manualQrisImageUrl != null) {
      map['manual_qris_image_url'] = Variable<String>(manualQrisImageUrl);
    }
    if (!nullToAbsent || manualQrisImageLocalPath != null) {
      map['manual_qris_image_local_path'] = Variable<String>(
        manualQrisImageLocalPath,
      );
    }
    if (!nullToAbsent || manualPaymentLabel != null) {
      map['manual_payment_label'] = Variable<String>(manualPaymentLabel);
    }
    if (!nullToAbsent || manualPaymentRawJson != null) {
      map['manual_payment_raw_json'] = Variable<String>(manualPaymentRawJson);
    }
    map['backend_sync_stage'] = Variable<String>(backendSyncStage);
    map['created_at_local'] = Variable<DateTime>(createdAtLocal);
    map['updated_at_local'] = Variable<DateTime>(updatedAtLocal);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientOrderCode: Value(clientOrderCode),
      serverOrderCode: serverOrderCode == null && nullToAbsent
          ? const Value.absent()
          : Value(serverOrderCode),
      partnerId: partnerId == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerId),
      partnerName: partnerName == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerName),
      tableServerId: tableServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableServerId),
      tableNoSnapshot: tableNoSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNoSnapshot),
      customerName: Value(customerName),
      paymentMethodSelected: paymentMethodSelected == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodSelected),
      paymentMethodEffective: paymentMethodEffective == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodEffective),
      subtotal: Value(subtotal),
      discountValue: Value(discountValue),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      grandTotal: Value(grandTotal),
      paidAmountLocal: paidAmountLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAmountLocal),
      changeAmountLocal: changeAmountLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(changeAmountLocal),
      cashierProofImageLocalPath:
          cashierProofImageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierProofImageLocalPath),
      paymentConfirmedAtLocal: paymentConfirmedAtLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentConfirmedAtLocal),
      latestPaymentServerId: latestPaymentServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(latestPaymentServerId),
      orderSnapshotJson: orderSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(orderSnapshotJson),
      orderStatusLocal: Value(orderStatusLocal),
      syncStatus: Value(syncStatus),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      manualPaymentServerId: manualPaymentServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(manualPaymentServerId),
      manualPaymentType: manualPaymentType == null && nullToAbsent
          ? const Value.absent()
          : Value(manualPaymentType),
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
      manualQrisImageUrl: manualQrisImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(manualQrisImageUrl),
      manualQrisImageLocalPath: manualQrisImageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(manualQrisImageLocalPath),
      manualPaymentLabel: manualPaymentLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(manualPaymentLabel),
      manualPaymentRawJson: manualPaymentRawJson == null && nullToAbsent
          ? const Value.absent()
          : Value(manualPaymentRawJson),
      backendSyncStage: Value(backendSyncStage),
      createdAtLocal: Value(createdAtLocal),
      updatedAtLocal: Value(updatedAtLocal),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrder(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      clientOrderCode: serializer.fromJson<String>(json['clientOrderCode']),
      serverOrderCode: serializer.fromJson<String?>(json['serverOrderCode']),
      partnerId: serializer.fromJson<int?>(json['partnerId']),
      partnerName: serializer.fromJson<String?>(json['partnerName']),
      tableServerId: serializer.fromJson<int?>(json['tableServerId']),
      tableNoSnapshot: serializer.fromJson<String?>(json['tableNoSnapshot']),
      customerName: serializer.fromJson<String>(json['customerName']),
      paymentMethodSelected: serializer.fromJson<String?>(
        json['paymentMethodSelected'],
      ),
      paymentMethodEffective: serializer.fromJson<String?>(
        json['paymentMethodEffective'],
      ),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountValue: serializer.fromJson<double>(json['discountValue']),
      ppnPercent: serializer.fromJson<double>(json['ppnPercent']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      paidAmountLocal: serializer.fromJson<double?>(json['paidAmountLocal']),
      changeAmountLocal: serializer.fromJson<double?>(
        json['changeAmountLocal'],
      ),
      cashierProofImageLocalPath: serializer.fromJson<String?>(
        json['cashierProofImageLocalPath'],
      ),
      paymentConfirmedAtLocal: serializer.fromJson<DateTime?>(
        json['paymentConfirmedAtLocal'],
      ),
      latestPaymentServerId: serializer.fromJson<int?>(
        json['latestPaymentServerId'],
      ),
      orderSnapshotJson: serializer.fromJson<String?>(
        json['orderSnapshotJson'],
      ),
      orderStatusLocal: serializer.fromJson<String>(json['orderStatusLocal']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      manualPaymentServerId: serializer.fromJson<int?>(
        json['manualPaymentServerId'],
      ),
      manualPaymentType: serializer.fromJson<String?>(
        json['manualPaymentType'],
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
      manualQrisImageUrl: serializer.fromJson<String?>(
        json['manualQrisImageUrl'],
      ),
      manualQrisImageLocalPath: serializer.fromJson<String?>(
        json['manualQrisImageLocalPath'],
      ),
      manualPaymentLabel: serializer.fromJson<String?>(
        json['manualPaymentLabel'],
      ),
      manualPaymentRawJson: serializer.fromJson<String?>(
        json['manualPaymentRawJson'],
      ),
      backendSyncStage: serializer.fromJson<String>(json['backendSyncStage']),
      createdAtLocal: serializer.fromJson<DateTime>(json['createdAtLocal']),
      updatedAtLocal: serializer.fromJson<DateTime>(json['updatedAtLocal']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<int?>(serverId),
      'clientOrderCode': serializer.toJson<String>(clientOrderCode),
      'serverOrderCode': serializer.toJson<String?>(serverOrderCode),
      'partnerId': serializer.toJson<int?>(partnerId),
      'partnerName': serializer.toJson<String?>(partnerName),
      'tableServerId': serializer.toJson<int?>(tableServerId),
      'tableNoSnapshot': serializer.toJson<String?>(tableNoSnapshot),
      'customerName': serializer.toJson<String>(customerName),
      'paymentMethodSelected': serializer.toJson<String?>(
        paymentMethodSelected,
      ),
      'paymentMethodEffective': serializer.toJson<String?>(
        paymentMethodEffective,
      ),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountValue': serializer.toJson<double>(discountValue),
      'ppnPercent': serializer.toJson<double>(ppnPercent),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'paidAmountLocal': serializer.toJson<double?>(paidAmountLocal),
      'changeAmountLocal': serializer.toJson<double?>(changeAmountLocal),
      'cashierProofImageLocalPath': serializer.toJson<String?>(
        cashierProofImageLocalPath,
      ),
      'paymentConfirmedAtLocal': serializer.toJson<DateTime?>(
        paymentConfirmedAtLocal,
      ),
      'latestPaymentServerId': serializer.toJson<int?>(latestPaymentServerId),
      'orderSnapshotJson': serializer.toJson<String?>(orderSnapshotJson),
      'orderStatusLocal': serializer.toJson<String>(orderStatusLocal),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastError': serializer.toJson<String?>(lastError),
      'manualPaymentServerId': serializer.toJson<int?>(manualPaymentServerId),
      'manualPaymentType': serializer.toJson<String?>(manualPaymentType),
      'manualProviderName': serializer.toJson<String?>(manualProviderName),
      'manualProviderAccountName': serializer.toJson<String?>(
        manualProviderAccountName,
      ),
      'manualProviderAccountNo': serializer.toJson<String?>(
        manualProviderAccountNo,
      ),
      'manualQrisImageUrl': serializer.toJson<String?>(manualQrisImageUrl),
      'manualQrisImageLocalPath': serializer.toJson<String?>(
        manualQrisImageLocalPath,
      ),
      'manualPaymentLabel': serializer.toJson<String?>(manualPaymentLabel),
      'manualPaymentRawJson': serializer.toJson<String?>(manualPaymentRawJson),
      'backendSyncStage': serializer.toJson<String>(backendSyncStage),
      'createdAtLocal': serializer.toJson<DateTime>(createdAtLocal),
      'updatedAtLocal': serializer.toJson<DateTime>(updatedAtLocal),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalOrder copyWith({
    String? localId,
    Value<int?> serverId = const Value.absent(),
    String? clientOrderCode,
    Value<String?> serverOrderCode = const Value.absent(),
    Value<int?> partnerId = const Value.absent(),
    Value<String?> partnerName = const Value.absent(),
    Value<int?> tableServerId = const Value.absent(),
    Value<String?> tableNoSnapshot = const Value.absent(),
    String? customerName,
    Value<String?> paymentMethodSelected = const Value.absent(),
    Value<String?> paymentMethodEffective = const Value.absent(),
    double? subtotal,
    double? discountValue,
    double? ppnPercent,
    bool? isPpnActive,
    double? grandTotal,
    Value<double?> paidAmountLocal = const Value.absent(),
    Value<double?> changeAmountLocal = const Value.absent(),
    Value<String?> cashierProofImageLocalPath = const Value.absent(),
    Value<DateTime?> paymentConfirmedAtLocal = const Value.absent(),
    Value<int?> latestPaymentServerId = const Value.absent(),
    Value<String?> orderSnapshotJson = const Value.absent(),
    String? orderStatusLocal,
    String? syncStatus,
    Value<String?> lastError = const Value.absent(),
    Value<int?> manualPaymentServerId = const Value.absent(),
    Value<String?> manualPaymentType = const Value.absent(),
    Value<String?> manualProviderName = const Value.absent(),
    Value<String?> manualProviderAccountName = const Value.absent(),
    Value<String?> manualProviderAccountNo = const Value.absent(),
    Value<String?> manualQrisImageUrl = const Value.absent(),
    Value<String?> manualQrisImageLocalPath = const Value.absent(),
    Value<String?> manualPaymentLabel = const Value.absent(),
    Value<String?> manualPaymentRawJson = const Value.absent(),
    String? backendSyncStage,
    DateTime? createdAtLocal,
    DateTime? updatedAtLocal,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LocalOrder(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientOrderCode: clientOrderCode ?? this.clientOrderCode,
    serverOrderCode: serverOrderCode.present
        ? serverOrderCode.value
        : this.serverOrderCode,
    partnerId: partnerId.present ? partnerId.value : this.partnerId,
    partnerName: partnerName.present ? partnerName.value : this.partnerName,
    tableServerId: tableServerId.present
        ? tableServerId.value
        : this.tableServerId,
    tableNoSnapshot: tableNoSnapshot.present
        ? tableNoSnapshot.value
        : this.tableNoSnapshot,
    customerName: customerName ?? this.customerName,
    paymentMethodSelected: paymentMethodSelected.present
        ? paymentMethodSelected.value
        : this.paymentMethodSelected,
    paymentMethodEffective: paymentMethodEffective.present
        ? paymentMethodEffective.value
        : this.paymentMethodEffective,
    subtotal: subtotal ?? this.subtotal,
    discountValue: discountValue ?? this.discountValue,
    ppnPercent: ppnPercent ?? this.ppnPercent,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    grandTotal: grandTotal ?? this.grandTotal,
    paidAmountLocal: paidAmountLocal.present
        ? paidAmountLocal.value
        : this.paidAmountLocal,
    changeAmountLocal: changeAmountLocal.present
        ? changeAmountLocal.value
        : this.changeAmountLocal,
    cashierProofImageLocalPath: cashierProofImageLocalPath.present
        ? cashierProofImageLocalPath.value
        : this.cashierProofImageLocalPath,
    paymentConfirmedAtLocal: paymentConfirmedAtLocal.present
        ? paymentConfirmedAtLocal.value
        : this.paymentConfirmedAtLocal,
    latestPaymentServerId: latestPaymentServerId.present
        ? latestPaymentServerId.value
        : this.latestPaymentServerId,
    orderSnapshotJson: orderSnapshotJson.present
        ? orderSnapshotJson.value
        : this.orderSnapshotJson,
    orderStatusLocal: orderStatusLocal ?? this.orderStatusLocal,
    syncStatus: syncStatus ?? this.syncStatus,
    lastError: lastError.present ? lastError.value : this.lastError,
    manualPaymentServerId: manualPaymentServerId.present
        ? manualPaymentServerId.value
        : this.manualPaymentServerId,
    manualPaymentType: manualPaymentType.present
        ? manualPaymentType.value
        : this.manualPaymentType,
    manualProviderName: manualProviderName.present
        ? manualProviderName.value
        : this.manualProviderName,
    manualProviderAccountName: manualProviderAccountName.present
        ? manualProviderAccountName.value
        : this.manualProviderAccountName,
    manualProviderAccountNo: manualProviderAccountNo.present
        ? manualProviderAccountNo.value
        : this.manualProviderAccountNo,
    manualQrisImageUrl: manualQrisImageUrl.present
        ? manualQrisImageUrl.value
        : this.manualQrisImageUrl,
    manualQrisImageLocalPath: manualQrisImageLocalPath.present
        ? manualQrisImageLocalPath.value
        : this.manualQrisImageLocalPath,
    manualPaymentLabel: manualPaymentLabel.present
        ? manualPaymentLabel.value
        : this.manualPaymentLabel,
    manualPaymentRawJson: manualPaymentRawJson.present
        ? manualPaymentRawJson.value
        : this.manualPaymentRawJson,
    backendSyncStage: backendSyncStage ?? this.backendSyncStage,
    createdAtLocal: createdAtLocal ?? this.createdAtLocal,
    updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientOrderCode: data.clientOrderCode.present
          ? data.clientOrderCode.value
          : this.clientOrderCode,
      serverOrderCode: data.serverOrderCode.present
          ? data.serverOrderCode.value
          : this.serverOrderCode,
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      partnerName: data.partnerName.present
          ? data.partnerName.value
          : this.partnerName,
      tableServerId: data.tableServerId.present
          ? data.tableServerId.value
          : this.tableServerId,
      tableNoSnapshot: data.tableNoSnapshot.present
          ? data.tableNoSnapshot.value
          : this.tableNoSnapshot,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      paymentMethodSelected: data.paymentMethodSelected.present
          ? data.paymentMethodSelected.value
          : this.paymentMethodSelected,
      paymentMethodEffective: data.paymentMethodEffective.present
          ? data.paymentMethodEffective.value
          : this.paymentMethodEffective,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      ppnPercent: data.ppnPercent.present
          ? data.ppnPercent.value
          : this.ppnPercent,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      paidAmountLocal: data.paidAmountLocal.present
          ? data.paidAmountLocal.value
          : this.paidAmountLocal,
      changeAmountLocal: data.changeAmountLocal.present
          ? data.changeAmountLocal.value
          : this.changeAmountLocal,
      cashierProofImageLocalPath: data.cashierProofImageLocalPath.present
          ? data.cashierProofImageLocalPath.value
          : this.cashierProofImageLocalPath,
      paymentConfirmedAtLocal: data.paymentConfirmedAtLocal.present
          ? data.paymentConfirmedAtLocal.value
          : this.paymentConfirmedAtLocal,
      latestPaymentServerId: data.latestPaymentServerId.present
          ? data.latestPaymentServerId.value
          : this.latestPaymentServerId,
      orderSnapshotJson: data.orderSnapshotJson.present
          ? data.orderSnapshotJson.value
          : this.orderSnapshotJson,
      orderStatusLocal: data.orderStatusLocal.present
          ? data.orderStatusLocal.value
          : this.orderStatusLocal,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      manualPaymentServerId: data.manualPaymentServerId.present
          ? data.manualPaymentServerId.value
          : this.manualPaymentServerId,
      manualPaymentType: data.manualPaymentType.present
          ? data.manualPaymentType.value
          : this.manualPaymentType,
      manualProviderName: data.manualProviderName.present
          ? data.manualProviderName.value
          : this.manualProviderName,
      manualProviderAccountName: data.manualProviderAccountName.present
          ? data.manualProviderAccountName.value
          : this.manualProviderAccountName,
      manualProviderAccountNo: data.manualProviderAccountNo.present
          ? data.manualProviderAccountNo.value
          : this.manualProviderAccountNo,
      manualQrisImageUrl: data.manualQrisImageUrl.present
          ? data.manualQrisImageUrl.value
          : this.manualQrisImageUrl,
      manualQrisImageLocalPath: data.manualQrisImageLocalPath.present
          ? data.manualQrisImageLocalPath.value
          : this.manualQrisImageLocalPath,
      manualPaymentLabel: data.manualPaymentLabel.present
          ? data.manualPaymentLabel.value
          : this.manualPaymentLabel,
      manualPaymentRawJson: data.manualPaymentRawJson.present
          ? data.manualPaymentRawJson.value
          : this.manualPaymentRawJson,
      backendSyncStage: data.backendSyncStage.present
          ? data.backendSyncStage.value
          : this.backendSyncStage,
      createdAtLocal: data.createdAtLocal.present
          ? data.createdAtLocal.value
          : this.createdAtLocal,
      updatedAtLocal: data.updatedAtLocal.present
          ? data.updatedAtLocal.value
          : this.updatedAtLocal,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('clientOrderCode: $clientOrderCode, ')
          ..write('serverOrderCode: $serverOrderCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('partnerName: $partnerName, ')
          ..write('tableServerId: $tableServerId, ')
          ..write('tableNoSnapshot: $tableNoSnapshot, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethodSelected: $paymentMethodSelected, ')
          ..write('paymentMethodEffective: $paymentMethodEffective, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountValue: $discountValue, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('paidAmountLocal: $paidAmountLocal, ')
          ..write('changeAmountLocal: $changeAmountLocal, ')
          ..write('cashierProofImageLocalPath: $cashierProofImageLocalPath, ')
          ..write('paymentConfirmedAtLocal: $paymentConfirmedAtLocal, ')
          ..write('latestPaymentServerId: $latestPaymentServerId, ')
          ..write('orderSnapshotJson: $orderSnapshotJson, ')
          ..write('orderStatusLocal: $orderStatusLocal, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastError: $lastError, ')
          ..write('manualPaymentServerId: $manualPaymentServerId, ')
          ..write('manualPaymentType: $manualPaymentType, ')
          ..write('manualProviderName: $manualProviderName, ')
          ..write('manualProviderAccountName: $manualProviderAccountName, ')
          ..write('manualProviderAccountNo: $manualProviderAccountNo, ')
          ..write('manualQrisImageUrl: $manualQrisImageUrl, ')
          ..write('manualQrisImageLocalPath: $manualQrisImageLocalPath, ')
          ..write('manualPaymentLabel: $manualPaymentLabel, ')
          ..write('manualPaymentRawJson: $manualPaymentRawJson, ')
          ..write('backendSyncStage: $backendSyncStage, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    localId,
    serverId,
    clientOrderCode,
    serverOrderCode,
    partnerId,
    partnerName,
    tableServerId,
    tableNoSnapshot,
    customerName,
    paymentMethodSelected,
    paymentMethodEffective,
    subtotal,
    discountValue,
    ppnPercent,
    isPpnActive,
    grandTotal,
    paidAmountLocal,
    changeAmountLocal,
    cashierProofImageLocalPath,
    paymentConfirmedAtLocal,
    latestPaymentServerId,
    orderSnapshotJson,
    orderStatusLocal,
    syncStatus,
    lastError,
    manualPaymentServerId,
    manualPaymentType,
    manualProviderName,
    manualProviderAccountName,
    manualProviderAccountNo,
    manualQrisImageUrl,
    manualQrisImageLocalPath,
    manualPaymentLabel,
    manualPaymentRawJson,
    backendSyncStage,
    createdAtLocal,
    updatedAtLocal,
    syncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.clientOrderCode == this.clientOrderCode &&
          other.serverOrderCode == this.serverOrderCode &&
          other.partnerId == this.partnerId &&
          other.partnerName == this.partnerName &&
          other.tableServerId == this.tableServerId &&
          other.tableNoSnapshot == this.tableNoSnapshot &&
          other.customerName == this.customerName &&
          other.paymentMethodSelected == this.paymentMethodSelected &&
          other.paymentMethodEffective == this.paymentMethodEffective &&
          other.subtotal == this.subtotal &&
          other.discountValue == this.discountValue &&
          other.ppnPercent == this.ppnPercent &&
          other.isPpnActive == this.isPpnActive &&
          other.grandTotal == this.grandTotal &&
          other.paidAmountLocal == this.paidAmountLocal &&
          other.changeAmountLocal == this.changeAmountLocal &&
          other.cashierProofImageLocalPath == this.cashierProofImageLocalPath &&
          other.paymentConfirmedAtLocal == this.paymentConfirmedAtLocal &&
          other.latestPaymentServerId == this.latestPaymentServerId &&
          other.orderSnapshotJson == this.orderSnapshotJson &&
          other.orderStatusLocal == this.orderStatusLocal &&
          other.syncStatus == this.syncStatus &&
          other.lastError == this.lastError &&
          other.manualPaymentServerId == this.manualPaymentServerId &&
          other.manualPaymentType == this.manualPaymentType &&
          other.manualProviderName == this.manualProviderName &&
          other.manualProviderAccountName == this.manualProviderAccountName &&
          other.manualProviderAccountNo == this.manualProviderAccountNo &&
          other.manualQrisImageUrl == this.manualQrisImageUrl &&
          other.manualQrisImageLocalPath == this.manualQrisImageLocalPath &&
          other.manualPaymentLabel == this.manualPaymentLabel &&
          other.manualPaymentRawJson == this.manualPaymentRawJson &&
          other.backendSyncStage == this.backendSyncStage &&
          other.createdAtLocal == this.createdAtLocal &&
          other.updatedAtLocal == this.updatedAtLocal &&
          other.syncedAt == this.syncedAt);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<String> localId;
  final Value<int?> serverId;
  final Value<String> clientOrderCode;
  final Value<String?> serverOrderCode;
  final Value<int?> partnerId;
  final Value<String?> partnerName;
  final Value<int?> tableServerId;
  final Value<String?> tableNoSnapshot;
  final Value<String> customerName;
  final Value<String?> paymentMethodSelected;
  final Value<String?> paymentMethodEffective;
  final Value<double> subtotal;
  final Value<double> discountValue;
  final Value<double> ppnPercent;
  final Value<bool> isPpnActive;
  final Value<double> grandTotal;
  final Value<double?> paidAmountLocal;
  final Value<double?> changeAmountLocal;
  final Value<String?> cashierProofImageLocalPath;
  final Value<DateTime?> paymentConfirmedAtLocal;
  final Value<int?> latestPaymentServerId;
  final Value<String?> orderSnapshotJson;
  final Value<String> orderStatusLocal;
  final Value<String> syncStatus;
  final Value<String?> lastError;
  final Value<int?> manualPaymentServerId;
  final Value<String?> manualPaymentType;
  final Value<String?> manualProviderName;
  final Value<String?> manualProviderAccountName;
  final Value<String?> manualProviderAccountNo;
  final Value<String?> manualQrisImageUrl;
  final Value<String?> manualQrisImageLocalPath;
  final Value<String?> manualPaymentLabel;
  final Value<String?> manualPaymentRawJson;
  final Value<String> backendSyncStage;
  final Value<DateTime> createdAtLocal;
  final Value<DateTime> updatedAtLocal;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientOrderCode = const Value.absent(),
    this.serverOrderCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.partnerName = const Value.absent(),
    this.tableServerId = const Value.absent(),
    this.tableNoSnapshot = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentMethodSelected = const Value.absent(),
    this.paymentMethodEffective = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.paidAmountLocal = const Value.absent(),
    this.changeAmountLocal = const Value.absent(),
    this.cashierProofImageLocalPath = const Value.absent(),
    this.paymentConfirmedAtLocal = const Value.absent(),
    this.latestPaymentServerId = const Value.absent(),
    this.orderSnapshotJson = const Value.absent(),
    this.orderStatusLocal = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastError = const Value.absent(),
    this.manualPaymentServerId = const Value.absent(),
    this.manualPaymentType = const Value.absent(),
    this.manualProviderName = const Value.absent(),
    this.manualProviderAccountName = const Value.absent(),
    this.manualProviderAccountNo = const Value.absent(),
    this.manualQrisImageUrl = const Value.absent(),
    this.manualQrisImageLocalPath = const Value.absent(),
    this.manualPaymentLabel = const Value.absent(),
    this.manualPaymentRawJson = const Value.absent(),
    this.backendSyncStage = const Value.absent(),
    this.createdAtLocal = const Value.absent(),
    this.updatedAtLocal = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String clientOrderCode,
    this.serverOrderCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.partnerName = const Value.absent(),
    this.tableServerId = const Value.absent(),
    this.tableNoSnapshot = const Value.absent(),
    required String customerName,
    this.paymentMethodSelected = const Value.absent(),
    this.paymentMethodEffective = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.paidAmountLocal = const Value.absent(),
    this.changeAmountLocal = const Value.absent(),
    this.cashierProofImageLocalPath = const Value.absent(),
    this.paymentConfirmedAtLocal = const Value.absent(),
    this.latestPaymentServerId = const Value.absent(),
    this.orderSnapshotJson = const Value.absent(),
    this.orderStatusLocal = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastError = const Value.absent(),
    this.manualPaymentServerId = const Value.absent(),
    this.manualPaymentType = const Value.absent(),
    this.manualProviderName = const Value.absent(),
    this.manualProviderAccountName = const Value.absent(),
    this.manualProviderAccountNo = const Value.absent(),
    this.manualQrisImageUrl = const Value.absent(),
    this.manualQrisImageLocalPath = const Value.absent(),
    this.manualPaymentLabel = const Value.absent(),
    this.manualPaymentRawJson = const Value.absent(),
    this.backendSyncStage = const Value.absent(),
    required DateTime createdAtLocal,
    required DateTime updatedAtLocal,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       clientOrderCode = Value(clientOrderCode),
       customerName = Value(customerName),
       createdAtLocal = Value(createdAtLocal),
       updatedAtLocal = Value(updatedAtLocal);
  static Insertable<LocalOrder> custom({
    Expression<String>? localId,
    Expression<int>? serverId,
    Expression<String>? clientOrderCode,
    Expression<String>? serverOrderCode,
    Expression<int>? partnerId,
    Expression<String>? partnerName,
    Expression<int>? tableServerId,
    Expression<String>? tableNoSnapshot,
    Expression<String>? customerName,
    Expression<String>? paymentMethodSelected,
    Expression<String>? paymentMethodEffective,
    Expression<double>? subtotal,
    Expression<double>? discountValue,
    Expression<double>? ppnPercent,
    Expression<bool>? isPpnActive,
    Expression<double>? grandTotal,
    Expression<double>? paidAmountLocal,
    Expression<double>? changeAmountLocal,
    Expression<String>? cashierProofImageLocalPath,
    Expression<DateTime>? paymentConfirmedAtLocal,
    Expression<int>? latestPaymentServerId,
    Expression<String>? orderSnapshotJson,
    Expression<String>? orderStatusLocal,
    Expression<String>? syncStatus,
    Expression<String>? lastError,
    Expression<int>? manualPaymentServerId,
    Expression<String>? manualPaymentType,
    Expression<String>? manualProviderName,
    Expression<String>? manualProviderAccountName,
    Expression<String>? manualProviderAccountNo,
    Expression<String>? manualQrisImageUrl,
    Expression<String>? manualQrisImageLocalPath,
    Expression<String>? manualPaymentLabel,
    Expression<String>? manualPaymentRawJson,
    Expression<String>? backendSyncStage,
    Expression<DateTime>? createdAtLocal,
    Expression<DateTime>? updatedAtLocal,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (clientOrderCode != null) 'client_order_code': clientOrderCode,
      if (serverOrderCode != null) 'server_order_code': serverOrderCode,
      if (partnerId != null) 'partner_id': partnerId,
      if (partnerName != null) 'partner_name': partnerName,
      if (tableServerId != null) 'table_server_id': tableServerId,
      if (tableNoSnapshot != null) 'table_no_snapshot': tableNoSnapshot,
      if (customerName != null) 'customer_name': customerName,
      if (paymentMethodSelected != null)
        'payment_method_selected': paymentMethodSelected,
      if (paymentMethodEffective != null)
        'payment_method_effective': paymentMethodEffective,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountValue != null) 'discount_value': discountValue,
      if (ppnPercent != null) 'ppn_percent': ppnPercent,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (paidAmountLocal != null) 'paid_amount_local': paidAmountLocal,
      if (changeAmountLocal != null) 'change_amount_local': changeAmountLocal,
      if (cashierProofImageLocalPath != null)
        'cashier_proof_image_local_path': cashierProofImageLocalPath,
      if (paymentConfirmedAtLocal != null)
        'payment_confirmed_at_local': paymentConfirmedAtLocal,
      if (latestPaymentServerId != null)
        'latest_payment_server_id': latestPaymentServerId,
      if (orderSnapshotJson != null) 'order_snapshot_json': orderSnapshotJson,
      if (orderStatusLocal != null) 'order_status_local': orderStatusLocal,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastError != null) 'last_error': lastError,
      if (manualPaymentServerId != null)
        'manual_payment_server_id': manualPaymentServerId,
      if (manualPaymentType != null) 'manual_payment_type': manualPaymentType,
      if (manualProviderName != null)
        'manual_provider_name': manualProviderName,
      if (manualProviderAccountName != null)
        'manual_provider_account_name': manualProviderAccountName,
      if (manualProviderAccountNo != null)
        'manual_provider_account_no': manualProviderAccountNo,
      if (manualQrisImageUrl != null)
        'manual_qris_image_url': manualQrisImageUrl,
      if (manualQrisImageLocalPath != null)
        'manual_qris_image_local_path': manualQrisImageLocalPath,
      if (manualPaymentLabel != null)
        'manual_payment_label': manualPaymentLabel,
      if (manualPaymentRawJson != null)
        'manual_payment_raw_json': manualPaymentRawJson,
      if (backendSyncStage != null) 'backend_sync_stage': backendSyncStage,
      if (createdAtLocal != null) 'created_at_local': createdAtLocal,
      if (updatedAtLocal != null) 'updated_at_local': updatedAtLocal,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? localId,
    Value<int?>? serverId,
    Value<String>? clientOrderCode,
    Value<String?>? serverOrderCode,
    Value<int?>? partnerId,
    Value<String?>? partnerName,
    Value<int?>? tableServerId,
    Value<String?>? tableNoSnapshot,
    Value<String>? customerName,
    Value<String?>? paymentMethodSelected,
    Value<String?>? paymentMethodEffective,
    Value<double>? subtotal,
    Value<double>? discountValue,
    Value<double>? ppnPercent,
    Value<bool>? isPpnActive,
    Value<double>? grandTotal,
    Value<double?>? paidAmountLocal,
    Value<double?>? changeAmountLocal,
    Value<String?>? cashierProofImageLocalPath,
    Value<DateTime?>? paymentConfirmedAtLocal,
    Value<int?>? latestPaymentServerId,
    Value<String?>? orderSnapshotJson,
    Value<String>? orderStatusLocal,
    Value<String>? syncStatus,
    Value<String?>? lastError,
    Value<int?>? manualPaymentServerId,
    Value<String?>? manualPaymentType,
    Value<String?>? manualProviderName,
    Value<String?>? manualProviderAccountName,
    Value<String?>? manualProviderAccountNo,
    Value<String?>? manualQrisImageUrl,
    Value<String?>? manualQrisImageLocalPath,
    Value<String?>? manualPaymentLabel,
    Value<String?>? manualPaymentRawJson,
    Value<String>? backendSyncStage,
    Value<DateTime>? createdAtLocal,
    Value<DateTime>? updatedAtLocal,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      clientOrderCode: clientOrderCode ?? this.clientOrderCode,
      serverOrderCode: serverOrderCode ?? this.serverOrderCode,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      tableServerId: tableServerId ?? this.tableServerId,
      tableNoSnapshot: tableNoSnapshot ?? this.tableNoSnapshot,
      customerName: customerName ?? this.customerName,
      paymentMethodSelected:
          paymentMethodSelected ?? this.paymentMethodSelected,
      paymentMethodEffective:
          paymentMethodEffective ?? this.paymentMethodEffective,
      subtotal: subtotal ?? this.subtotal,
      discountValue: discountValue ?? this.discountValue,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmountLocal: paidAmountLocal ?? this.paidAmountLocal,
      changeAmountLocal: changeAmountLocal ?? this.changeAmountLocal,
      cashierProofImageLocalPath:
          cashierProofImageLocalPath ?? this.cashierProofImageLocalPath,
      paymentConfirmedAtLocal:
          paymentConfirmedAtLocal ?? this.paymentConfirmedAtLocal,
      latestPaymentServerId:
          latestPaymentServerId ?? this.latestPaymentServerId,
      orderSnapshotJson: orderSnapshotJson ?? this.orderSnapshotJson,
      orderStatusLocal: orderStatusLocal ?? this.orderStatusLocal,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
      manualPaymentServerId:
          manualPaymentServerId ?? this.manualPaymentServerId,
      manualPaymentType: manualPaymentType ?? this.manualPaymentType,
      manualProviderName: manualProviderName ?? this.manualProviderName,
      manualProviderAccountName:
          manualProviderAccountName ?? this.manualProviderAccountName,
      manualProviderAccountNo:
          manualProviderAccountNo ?? this.manualProviderAccountNo,
      manualQrisImageUrl: manualQrisImageUrl ?? this.manualQrisImageUrl,
      manualQrisImageLocalPath:
          manualQrisImageLocalPath ?? this.manualQrisImageLocalPath,
      manualPaymentLabel: manualPaymentLabel ?? this.manualPaymentLabel,
      manualPaymentRawJson: manualPaymentRawJson ?? this.manualPaymentRawJson,
      backendSyncStage: backendSyncStage ?? this.backendSyncStage,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (clientOrderCode.present) {
      map['client_order_code'] = Variable<String>(clientOrderCode.value);
    }
    if (serverOrderCode.present) {
      map['server_order_code'] = Variable<String>(serverOrderCode.value);
    }
    if (partnerId.present) {
      map['partner_id'] = Variable<int>(partnerId.value);
    }
    if (partnerName.present) {
      map['partner_name'] = Variable<String>(partnerName.value);
    }
    if (tableServerId.present) {
      map['table_server_id'] = Variable<int>(tableServerId.value);
    }
    if (tableNoSnapshot.present) {
      map['table_no_snapshot'] = Variable<String>(tableNoSnapshot.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (paymentMethodSelected.present) {
      map['payment_method_selected'] = Variable<String>(
        paymentMethodSelected.value,
      );
    }
    if (paymentMethodEffective.present) {
      map['payment_method_effective'] = Variable<String>(
        paymentMethodEffective.value,
      );
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (ppnPercent.present) {
      map['ppn_percent'] = Variable<double>(ppnPercent.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (paidAmountLocal.present) {
      map['paid_amount_local'] = Variable<double>(paidAmountLocal.value);
    }
    if (changeAmountLocal.present) {
      map['change_amount_local'] = Variable<double>(changeAmountLocal.value);
    }
    if (cashierProofImageLocalPath.present) {
      map['cashier_proof_image_local_path'] = Variable<String>(
        cashierProofImageLocalPath.value,
      );
    }
    if (paymentConfirmedAtLocal.present) {
      map['payment_confirmed_at_local'] = Variable<DateTime>(
        paymentConfirmedAtLocal.value,
      );
    }
    if (latestPaymentServerId.present) {
      map['latest_payment_server_id'] = Variable<int>(
        latestPaymentServerId.value,
      );
    }
    if (orderSnapshotJson.present) {
      map['order_snapshot_json'] = Variable<String>(orderSnapshotJson.value);
    }
    if (orderStatusLocal.present) {
      map['order_status_local'] = Variable<String>(orderStatusLocal.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (manualPaymentServerId.present) {
      map['manual_payment_server_id'] = Variable<int>(
        manualPaymentServerId.value,
      );
    }
    if (manualPaymentType.present) {
      map['manual_payment_type'] = Variable<String>(manualPaymentType.value);
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
    if (manualQrisImageUrl.present) {
      map['manual_qris_image_url'] = Variable<String>(manualQrisImageUrl.value);
    }
    if (manualQrisImageLocalPath.present) {
      map['manual_qris_image_local_path'] = Variable<String>(
        manualQrisImageLocalPath.value,
      );
    }
    if (manualPaymentLabel.present) {
      map['manual_payment_label'] = Variable<String>(manualPaymentLabel.value);
    }
    if (manualPaymentRawJson.present) {
      map['manual_payment_raw_json'] = Variable<String>(
        manualPaymentRawJson.value,
      );
    }
    if (backendSyncStage.present) {
      map['backend_sync_stage'] = Variable<String>(backendSyncStage.value);
    }
    if (createdAtLocal.present) {
      map['created_at_local'] = Variable<DateTime>(createdAtLocal.value);
    }
    if (updatedAtLocal.present) {
      map['updated_at_local'] = Variable<DateTime>(updatedAtLocal.value);
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
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('clientOrderCode: $clientOrderCode, ')
          ..write('serverOrderCode: $serverOrderCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('partnerName: $partnerName, ')
          ..write('tableServerId: $tableServerId, ')
          ..write('tableNoSnapshot: $tableNoSnapshot, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethodSelected: $paymentMethodSelected, ')
          ..write('paymentMethodEffective: $paymentMethodEffective, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountValue: $discountValue, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('paidAmountLocal: $paidAmountLocal, ')
          ..write('changeAmountLocal: $changeAmountLocal, ')
          ..write('cashierProofImageLocalPath: $cashierProofImageLocalPath, ')
          ..write('paymentConfirmedAtLocal: $paymentConfirmedAtLocal, ')
          ..write('latestPaymentServerId: $latestPaymentServerId, ')
          ..write('orderSnapshotJson: $orderSnapshotJson, ')
          ..write('orderStatusLocal: $orderStatusLocal, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastError: $lastError, ')
          ..write('manualPaymentServerId: $manualPaymentServerId, ')
          ..write('manualPaymentType: $manualPaymentType, ')
          ..write('manualProviderName: $manualProviderName, ')
          ..write('manualProviderAccountName: $manualProviderAccountName, ')
          ..write('manualProviderAccountNo: $manualProviderAccountNo, ')
          ..write('manualQrisImageUrl: $manualQrisImageUrl, ')
          ..write('manualQrisImageLocalPath: $manualQrisImageLocalPath, ')
          ..write('manualPaymentLabel: $manualPaymentLabel, ')
          ..write('manualPaymentRawJson: $manualPaymentRawJson, ')
          ..write('backendSyncStage: $backendSyncStage, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrderItemsTable extends LocalOrderItems
    with TableInfo<$LocalOrderItemsTable, LocalOrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderLocalIdMeta = const VerificationMeta(
    'orderLocalId',
  );
  @override
  late final GeneratedColumn<String> orderLocalId = GeneratedColumn<String>(
    'order_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverOrderDetailIdMeta =
      const VerificationMeta('serverOrderDetailId');
  @override
  late final GeneratedColumn<int> serverOrderDetailId = GeneratedColumn<int>(
    'server_order_detail_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const VerificationMeta _categoryServerIdMeta = const VerificationMeta(
    'categoryServerId',
  );
  @override
  late final GeneratedColumn<int> categoryServerId = GeneratedColumn<int>(
    'category_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameSnapshotMeta =
      const VerificationMeta('categoryNameSnapshot');
  @override
  late final GeneratedColumn<String> categoryNameSnapshot =
      GeneratedColumn<String>(
        'category_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<double> lineTotal = GeneratedColumn<double>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtLocalMeta = const VerificationMeta(
    'createdAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtLocal =
      GeneratedColumn<DateTime>(
        'created_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    orderLocalId,
    serverOrderDetailId,
    productServerId,
    productNameSnapshot,
    basePrice,
    promoId,
    promoType,
    promoAmount,
    categoryServerId,
    categoryNameSnapshot,
    optionsPrice,
    qty,
    customerNote,
    lineTotal,
    createdAtLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('order_local_id')) {
      context.handle(
        _orderLocalIdMeta,
        orderLocalId.isAcceptableOrUnknown(
          data['order_local_id']!,
          _orderLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderLocalIdMeta);
    }
    if (data.containsKey('server_order_detail_id')) {
      context.handle(
        _serverOrderDetailIdMeta,
        serverOrderDetailId.isAcceptableOrUnknown(
          data['server_order_detail_id']!,
          _serverOrderDetailIdMeta,
        ),
      );
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
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
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
    if (data.containsKey('promo_amount')) {
      context.handle(
        _promoAmountMeta,
        promoAmount.isAcceptableOrUnknown(
          data['promo_amount']!,
          _promoAmountMeta,
        ),
      );
    }
    if (data.containsKey('category_server_id')) {
      context.handle(
        _categoryServerIdMeta,
        categoryServerId.isAcceptableOrUnknown(
          data['category_server_id']!,
          _categoryServerIdMeta,
        ),
      );
    }
    if (data.containsKey('category_name_snapshot')) {
      context.handle(
        _categoryNameSnapshotMeta,
        categoryNameSnapshot.isAcceptableOrUnknown(
          data['category_name_snapshot']!,
          _categoryNameSnapshotMeta,
        ),
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
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
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
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    }
    if (data.containsKey('created_at_local')) {
      context.handle(
        _createdAtLocalMeta,
        createdAtLocal.isAcceptableOrUnknown(
          data['created_at_local']!,
          _createdAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalOrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrderItem(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      orderLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_local_id'],
      )!,
      serverOrderDetailId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_order_detail_id'],
      ),
      productServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_server_id'],
      )!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_price'],
      )!,
      promoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}promo_id'],
      ),
      promoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promo_type'],
      ),
      promoAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}promo_amount'],
      ),
      categoryServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_server_id'],
      ),
      categoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_snapshot'],
      ),
      optionsPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}options_price'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      customerNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_note'],
      ),
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_total'],
      )!,
      createdAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_local'],
      )!,
    );
  }

  @override
  $LocalOrderItemsTable createAlias(String alias) {
    return $LocalOrderItemsTable(attachedDatabase, alias);
  }
}

class LocalOrderItem extends DataClass implements Insertable<LocalOrderItem> {
  final String localId;
  final String orderLocalId;
  final int? serverOrderDetailId;
  final int productServerId;
  final String productNameSnapshot;
  final double basePrice;
  final int? promoId;
  final String? promoType;
  final double? promoAmount;
  final int? categoryServerId;
  final String? categoryNameSnapshot;
  final double optionsPrice;
  final int qty;
  final String? customerNote;
  final double lineTotal;
  final DateTime createdAtLocal;
  const LocalOrderItem({
    required this.localId,
    required this.orderLocalId,
    this.serverOrderDetailId,
    required this.productServerId,
    required this.productNameSnapshot,
    required this.basePrice,
    this.promoId,
    this.promoType,
    this.promoAmount,
    this.categoryServerId,
    this.categoryNameSnapshot,
    required this.optionsPrice,
    required this.qty,
    this.customerNote,
    required this.lineTotal,
    required this.createdAtLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['order_local_id'] = Variable<String>(orderLocalId);
    if (!nullToAbsent || serverOrderDetailId != null) {
      map['server_order_detail_id'] = Variable<int>(serverOrderDetailId);
    }
    map['product_server_id'] = Variable<int>(productServerId);
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    map['base_price'] = Variable<double>(basePrice);
    if (!nullToAbsent || promoId != null) {
      map['promo_id'] = Variable<int>(promoId);
    }
    if (!nullToAbsent || promoType != null) {
      map['promo_type'] = Variable<String>(promoType);
    }
    if (!nullToAbsent || promoAmount != null) {
      map['promo_amount'] = Variable<double>(promoAmount);
    }
    if (!nullToAbsent || categoryServerId != null) {
      map['category_server_id'] = Variable<int>(categoryServerId);
    }
    if (!nullToAbsent || categoryNameSnapshot != null) {
      map['category_name_snapshot'] = Variable<String>(categoryNameSnapshot);
    }
    map['options_price'] = Variable<double>(optionsPrice);
    map['qty'] = Variable<int>(qty);
    if (!nullToAbsent || customerNote != null) {
      map['customer_note'] = Variable<String>(customerNote);
    }
    map['line_total'] = Variable<double>(lineTotal);
    map['created_at_local'] = Variable<DateTime>(createdAtLocal);
    return map;
  }

  LocalOrderItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalOrderItemsCompanion(
      localId: Value(localId),
      orderLocalId: Value(orderLocalId),
      serverOrderDetailId: serverOrderDetailId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverOrderDetailId),
      productServerId: Value(productServerId),
      productNameSnapshot: Value(productNameSnapshot),
      basePrice: Value(basePrice),
      promoId: promoId == null && nullToAbsent
          ? const Value.absent()
          : Value(promoId),
      promoType: promoType == null && nullToAbsent
          ? const Value.absent()
          : Value(promoType),
      promoAmount: promoAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(promoAmount),
      categoryServerId: categoryServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryServerId),
      categoryNameSnapshot: categoryNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryNameSnapshot),
      optionsPrice: Value(optionsPrice),
      qty: Value(qty),
      customerNote: customerNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customerNote),
      lineTotal: Value(lineTotal),
      createdAtLocal: Value(createdAtLocal),
    );
  }

  factory LocalOrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrderItem(
      localId: serializer.fromJson<String>(json['localId']),
      orderLocalId: serializer.fromJson<String>(json['orderLocalId']),
      serverOrderDetailId: serializer.fromJson<int?>(
        json['serverOrderDetailId'],
      ),
      productServerId: serializer.fromJson<int>(json['productServerId']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
      basePrice: serializer.fromJson<double>(json['basePrice']),
      promoId: serializer.fromJson<int?>(json['promoId']),
      promoType: serializer.fromJson<String?>(json['promoType']),
      promoAmount: serializer.fromJson<double?>(json['promoAmount']),
      categoryServerId: serializer.fromJson<int?>(json['categoryServerId']),
      categoryNameSnapshot: serializer.fromJson<String?>(
        json['categoryNameSnapshot'],
      ),
      optionsPrice: serializer.fromJson<double>(json['optionsPrice']),
      qty: serializer.fromJson<int>(json['qty']),
      customerNote: serializer.fromJson<String?>(json['customerNote']),
      lineTotal: serializer.fromJson<double>(json['lineTotal']),
      createdAtLocal: serializer.fromJson<DateTime>(json['createdAtLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'orderLocalId': serializer.toJson<String>(orderLocalId),
      'serverOrderDetailId': serializer.toJson<int?>(serverOrderDetailId),
      'productServerId': serializer.toJson<int>(productServerId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'basePrice': serializer.toJson<double>(basePrice),
      'promoId': serializer.toJson<int?>(promoId),
      'promoType': serializer.toJson<String?>(promoType),
      'promoAmount': serializer.toJson<double?>(promoAmount),
      'categoryServerId': serializer.toJson<int?>(categoryServerId),
      'categoryNameSnapshot': serializer.toJson<String?>(categoryNameSnapshot),
      'optionsPrice': serializer.toJson<double>(optionsPrice),
      'qty': serializer.toJson<int>(qty),
      'customerNote': serializer.toJson<String?>(customerNote),
      'lineTotal': serializer.toJson<double>(lineTotal),
      'createdAtLocal': serializer.toJson<DateTime>(createdAtLocal),
    };
  }

  LocalOrderItem copyWith({
    String? localId,
    String? orderLocalId,
    Value<int?> serverOrderDetailId = const Value.absent(),
    int? productServerId,
    String? productNameSnapshot,
    double? basePrice,
    Value<int?> promoId = const Value.absent(),
    Value<String?> promoType = const Value.absent(),
    Value<double?> promoAmount = const Value.absent(),
    Value<int?> categoryServerId = const Value.absent(),
    Value<String?> categoryNameSnapshot = const Value.absent(),
    double? optionsPrice,
    int? qty,
    Value<String?> customerNote = const Value.absent(),
    double? lineTotal,
    DateTime? createdAtLocal,
  }) => LocalOrderItem(
    localId: localId ?? this.localId,
    orderLocalId: orderLocalId ?? this.orderLocalId,
    serverOrderDetailId: serverOrderDetailId.present
        ? serverOrderDetailId.value
        : this.serverOrderDetailId,
    productServerId: productServerId ?? this.productServerId,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    basePrice: basePrice ?? this.basePrice,
    promoId: promoId.present ? promoId.value : this.promoId,
    promoType: promoType.present ? promoType.value : this.promoType,
    promoAmount: promoAmount.present ? promoAmount.value : this.promoAmount,
    categoryServerId: categoryServerId.present
        ? categoryServerId.value
        : this.categoryServerId,
    categoryNameSnapshot: categoryNameSnapshot.present
        ? categoryNameSnapshot.value
        : this.categoryNameSnapshot,
    optionsPrice: optionsPrice ?? this.optionsPrice,
    qty: qty ?? this.qty,
    customerNote: customerNote.present ? customerNote.value : this.customerNote,
    lineTotal: lineTotal ?? this.lineTotal,
    createdAtLocal: createdAtLocal ?? this.createdAtLocal,
  );
  LocalOrderItem copyWithCompanion(LocalOrderItemsCompanion data) {
    return LocalOrderItem(
      localId: data.localId.present ? data.localId.value : this.localId,
      orderLocalId: data.orderLocalId.present
          ? data.orderLocalId.value
          : this.orderLocalId,
      serverOrderDetailId: data.serverOrderDetailId.present
          ? data.serverOrderDetailId.value
          : this.serverOrderDetailId,
      productServerId: data.productServerId.present
          ? data.productServerId.value
          : this.productServerId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      promoId: data.promoId.present ? data.promoId.value : this.promoId,
      promoType: data.promoType.present ? data.promoType.value : this.promoType,
      promoAmount: data.promoAmount.present
          ? data.promoAmount.value
          : this.promoAmount,
      categoryServerId: data.categoryServerId.present
          ? data.categoryServerId.value
          : this.categoryServerId,
      categoryNameSnapshot: data.categoryNameSnapshot.present
          ? data.categoryNameSnapshot.value
          : this.categoryNameSnapshot,
      optionsPrice: data.optionsPrice.present
          ? data.optionsPrice.value
          : this.optionsPrice,
      qty: data.qty.present ? data.qty.value : this.qty,
      customerNote: data.customerNote.present
          ? data.customerNote.value
          : this.customerNote,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      createdAtLocal: data.createdAtLocal.present
          ? data.createdAtLocal.value
          : this.createdAtLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrderItem(')
          ..write('localId: $localId, ')
          ..write('orderLocalId: $orderLocalId, ')
          ..write('serverOrderDetailId: $serverOrderDetailId, ')
          ..write('productServerId: $productServerId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('basePrice: $basePrice, ')
          ..write('promoId: $promoId, ')
          ..write('promoType: $promoType, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('optionsPrice: $optionsPrice, ')
          ..write('qty: $qty, ')
          ..write('customerNote: $customerNote, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAtLocal: $createdAtLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    orderLocalId,
    serverOrderDetailId,
    productServerId,
    productNameSnapshot,
    basePrice,
    promoId,
    promoType,
    promoAmount,
    categoryServerId,
    categoryNameSnapshot,
    optionsPrice,
    qty,
    customerNote,
    lineTotal,
    createdAtLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrderItem &&
          other.localId == this.localId &&
          other.orderLocalId == this.orderLocalId &&
          other.serverOrderDetailId == this.serverOrderDetailId &&
          other.productServerId == this.productServerId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.basePrice == this.basePrice &&
          other.promoId == this.promoId &&
          other.promoType == this.promoType &&
          other.promoAmount == this.promoAmount &&
          other.categoryServerId == this.categoryServerId &&
          other.categoryNameSnapshot == this.categoryNameSnapshot &&
          other.optionsPrice == this.optionsPrice &&
          other.qty == this.qty &&
          other.customerNote == this.customerNote &&
          other.lineTotal == this.lineTotal &&
          other.createdAtLocal == this.createdAtLocal);
}

class LocalOrderItemsCompanion extends UpdateCompanion<LocalOrderItem> {
  final Value<String> localId;
  final Value<String> orderLocalId;
  final Value<int?> serverOrderDetailId;
  final Value<int> productServerId;
  final Value<String> productNameSnapshot;
  final Value<double> basePrice;
  final Value<int?> promoId;
  final Value<String?> promoType;
  final Value<double?> promoAmount;
  final Value<int?> categoryServerId;
  final Value<String?> categoryNameSnapshot;
  final Value<double> optionsPrice;
  final Value<int> qty;
  final Value<String?> customerNote;
  final Value<double> lineTotal;
  final Value<DateTime> createdAtLocal;
  final Value<int> rowid;
  const LocalOrderItemsCompanion({
    this.localId = const Value.absent(),
    this.orderLocalId = const Value.absent(),
    this.serverOrderDetailId = const Value.absent(),
    this.productServerId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoType = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.categoryServerId = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.optionsPrice = const Value.absent(),
    this.qty = const Value.absent(),
    this.customerNote = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.createdAtLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrderItemsCompanion.insert({
    required String localId,
    required String orderLocalId,
    this.serverOrderDetailId = const Value.absent(),
    required int productServerId,
    required String productNameSnapshot,
    this.basePrice = const Value.absent(),
    this.promoId = const Value.absent(),
    this.promoType = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.categoryServerId = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.optionsPrice = const Value.absent(),
    required int qty,
    this.customerNote = const Value.absent(),
    this.lineTotal = const Value.absent(),
    required DateTime createdAtLocal,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       orderLocalId = Value(orderLocalId),
       productServerId = Value(productServerId),
       productNameSnapshot = Value(productNameSnapshot),
       qty = Value(qty),
       createdAtLocal = Value(createdAtLocal);
  static Insertable<LocalOrderItem> custom({
    Expression<String>? localId,
    Expression<String>? orderLocalId,
    Expression<int>? serverOrderDetailId,
    Expression<int>? productServerId,
    Expression<String>? productNameSnapshot,
    Expression<double>? basePrice,
    Expression<int>? promoId,
    Expression<String>? promoType,
    Expression<double>? promoAmount,
    Expression<int>? categoryServerId,
    Expression<String>? categoryNameSnapshot,
    Expression<double>? optionsPrice,
    Expression<int>? qty,
    Expression<String>? customerNote,
    Expression<double>? lineTotal,
    Expression<DateTime>? createdAtLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (orderLocalId != null) 'order_local_id': orderLocalId,
      if (serverOrderDetailId != null)
        'server_order_detail_id': serverOrderDetailId,
      if (productServerId != null) 'product_server_id': productServerId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (basePrice != null) 'base_price': basePrice,
      if (promoId != null) 'promo_id': promoId,
      if (promoType != null) 'promo_type': promoType,
      if (promoAmount != null) 'promo_amount': promoAmount,
      if (categoryServerId != null) 'category_server_id': categoryServerId,
      if (categoryNameSnapshot != null)
        'category_name_snapshot': categoryNameSnapshot,
      if (optionsPrice != null) 'options_price': optionsPrice,
      if (qty != null) 'qty': qty,
      if (customerNote != null) 'customer_note': customerNote,
      if (lineTotal != null) 'line_total': lineTotal,
      if (createdAtLocal != null) 'created_at_local': createdAtLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrderItemsCompanion copyWith({
    Value<String>? localId,
    Value<String>? orderLocalId,
    Value<int?>? serverOrderDetailId,
    Value<int>? productServerId,
    Value<String>? productNameSnapshot,
    Value<double>? basePrice,
    Value<int?>? promoId,
    Value<String?>? promoType,
    Value<double?>? promoAmount,
    Value<int?>? categoryServerId,
    Value<String?>? categoryNameSnapshot,
    Value<double>? optionsPrice,
    Value<int>? qty,
    Value<String?>? customerNote,
    Value<double>? lineTotal,
    Value<DateTime>? createdAtLocal,
    Value<int>? rowid,
  }) {
    return LocalOrderItemsCompanion(
      localId: localId ?? this.localId,
      orderLocalId: orderLocalId ?? this.orderLocalId,
      serverOrderDetailId: serverOrderDetailId ?? this.serverOrderDetailId,
      productServerId: productServerId ?? this.productServerId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      basePrice: basePrice ?? this.basePrice,
      promoId: promoId ?? this.promoId,
      promoType: promoType ?? this.promoType,
      promoAmount: promoAmount ?? this.promoAmount,
      categoryServerId: categoryServerId ?? this.categoryServerId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      optionsPrice: optionsPrice ?? this.optionsPrice,
      qty: qty ?? this.qty,
      customerNote: customerNote ?? this.customerNote,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (orderLocalId.present) {
      map['order_local_id'] = Variable<String>(orderLocalId.value);
    }
    if (serverOrderDetailId.present) {
      map['server_order_detail_id'] = Variable<int>(serverOrderDetailId.value);
    }
    if (productServerId.present) {
      map['product_server_id'] = Variable<int>(productServerId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (basePrice.present) {
      map['base_price'] = Variable<double>(basePrice.value);
    }
    if (promoId.present) {
      map['promo_id'] = Variable<int>(promoId.value);
    }
    if (promoType.present) {
      map['promo_type'] = Variable<String>(promoType.value);
    }
    if (promoAmount.present) {
      map['promo_amount'] = Variable<double>(promoAmount.value);
    }
    if (categoryServerId.present) {
      map['category_server_id'] = Variable<int>(categoryServerId.value);
    }
    if (categoryNameSnapshot.present) {
      map['category_name_snapshot'] = Variable<String>(
        categoryNameSnapshot.value,
      );
    }
    if (optionsPrice.present) {
      map['options_price'] = Variable<double>(optionsPrice.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (customerNote.present) {
      map['customer_note'] = Variable<String>(customerNote.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<double>(lineTotal.value);
    }
    if (createdAtLocal.present) {
      map['created_at_local'] = Variable<DateTime>(createdAtLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrderItemsCompanion(')
          ..write('localId: $localId, ')
          ..write('orderLocalId: $orderLocalId, ')
          ..write('serverOrderDetailId: $serverOrderDetailId, ')
          ..write('productServerId: $productServerId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('basePrice: $basePrice, ')
          ..write('promoId: $promoId, ')
          ..write('promoType: $promoType, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('optionsPrice: $optionsPrice, ')
          ..write('qty: $qty, ')
          ..write('customerNote: $customerNote, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrderItemOptionsTable extends LocalOrderItemOptions
    with TableInfo<$LocalOrderItemOptionsTable, LocalOrderItemOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrderItemOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderItemLocalIdMeta = const VerificationMeta(
    'orderItemLocalId',
  );
  @override
  late final GeneratedColumn<String> orderItemLocalId = GeneratedColumn<String>(
    'order_item_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverOrderDetailOptionIdMeta =
      const VerificationMeta('serverOrderDetailOptionId');
  @override
  late final GeneratedColumn<int> serverOrderDetailOptionId =
      GeneratedColumn<int>(
        'server_order_detail_option_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _optionServerIdMeta = const VerificationMeta(
    'optionServerId',
  );
  @override
  late final GeneratedColumn<int> optionServerId = GeneratedColumn<int>(
    'option_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentNameSnapshotMeta =
      const VerificationMeta('parentNameSnapshot');
  @override
  late final GeneratedColumn<String> parentNameSnapshot =
      GeneratedColumn<String>(
        'parent_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _optionNameSnapshotMeta =
      const VerificationMeta('optionNameSnapshot');
  @override
  late final GeneratedColumn<String> optionNameSnapshot =
      GeneratedColumn<String>(
        'option_name_snapshot',
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
  static const VerificationMeta _createdAtLocalMeta = const VerificationMeta(
    'createdAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtLocal =
      GeneratedColumn<DateTime>(
        'created_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    orderItemLocalId,
    serverOrderDetailOptionId,
    optionServerId,
    parentNameSnapshot,
    optionNameSnapshot,
    price,
    createdAtLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_order_item_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrderItemOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('order_item_local_id')) {
      context.handle(
        _orderItemLocalIdMeta,
        orderItemLocalId.isAcceptableOrUnknown(
          data['order_item_local_id']!,
          _orderItemLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderItemLocalIdMeta);
    }
    if (data.containsKey('server_order_detail_option_id')) {
      context.handle(
        _serverOrderDetailOptionIdMeta,
        serverOrderDetailOptionId.isAcceptableOrUnknown(
          data['server_order_detail_option_id']!,
          _serverOrderDetailOptionIdMeta,
        ),
      );
    }
    if (data.containsKey('option_server_id')) {
      context.handle(
        _optionServerIdMeta,
        optionServerId.isAcceptableOrUnknown(
          data['option_server_id']!,
          _optionServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionServerIdMeta);
    }
    if (data.containsKey('parent_name_snapshot')) {
      context.handle(
        _parentNameSnapshotMeta,
        parentNameSnapshot.isAcceptableOrUnknown(
          data['parent_name_snapshot']!,
          _parentNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('option_name_snapshot')) {
      context.handle(
        _optionNameSnapshotMeta,
        optionNameSnapshot.isAcceptableOrUnknown(
          data['option_name_snapshot']!,
          _optionNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionNameSnapshotMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('created_at_local')) {
      context.handle(
        _createdAtLocalMeta,
        createdAtLocal.isAcceptableOrUnknown(
          data['created_at_local']!,
          _createdAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalOrderItemOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrderItemOption(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      orderItemLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_item_local_id'],
      )!,
      serverOrderDetailOptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_order_detail_option_id'],
      ),
      optionServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}option_server_id'],
      )!,
      parentNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_name_snapshot'],
      ),
      optionNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_name_snapshot'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      createdAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_local'],
      )!,
    );
  }

  @override
  $LocalOrderItemOptionsTable createAlias(String alias) {
    return $LocalOrderItemOptionsTable(attachedDatabase, alias);
  }
}

class LocalOrderItemOption extends DataClass
    implements Insertable<LocalOrderItemOption> {
  final String localId;
  final String orderItemLocalId;
  final int? serverOrderDetailOptionId;
  final int optionServerId;
  final String? parentNameSnapshot;
  final String optionNameSnapshot;
  final double price;
  final DateTime createdAtLocal;
  const LocalOrderItemOption({
    required this.localId,
    required this.orderItemLocalId,
    this.serverOrderDetailOptionId,
    required this.optionServerId,
    this.parentNameSnapshot,
    required this.optionNameSnapshot,
    required this.price,
    required this.createdAtLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['order_item_local_id'] = Variable<String>(orderItemLocalId);
    if (!nullToAbsent || serverOrderDetailOptionId != null) {
      map['server_order_detail_option_id'] = Variable<int>(
        serverOrderDetailOptionId,
      );
    }
    map['option_server_id'] = Variable<int>(optionServerId);
    if (!nullToAbsent || parentNameSnapshot != null) {
      map['parent_name_snapshot'] = Variable<String>(parentNameSnapshot);
    }
    map['option_name_snapshot'] = Variable<String>(optionNameSnapshot);
    map['price'] = Variable<double>(price);
    map['created_at_local'] = Variable<DateTime>(createdAtLocal);
    return map;
  }

  LocalOrderItemOptionsCompanion toCompanion(bool nullToAbsent) {
    return LocalOrderItemOptionsCompanion(
      localId: Value(localId),
      orderItemLocalId: Value(orderItemLocalId),
      serverOrderDetailOptionId:
          serverOrderDetailOptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverOrderDetailOptionId),
      optionServerId: Value(optionServerId),
      parentNameSnapshot: parentNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(parentNameSnapshot),
      optionNameSnapshot: Value(optionNameSnapshot),
      price: Value(price),
      createdAtLocal: Value(createdAtLocal),
    );
  }

  factory LocalOrderItemOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrderItemOption(
      localId: serializer.fromJson<String>(json['localId']),
      orderItemLocalId: serializer.fromJson<String>(json['orderItemLocalId']),
      serverOrderDetailOptionId: serializer.fromJson<int?>(
        json['serverOrderDetailOptionId'],
      ),
      optionServerId: serializer.fromJson<int>(json['optionServerId']),
      parentNameSnapshot: serializer.fromJson<String?>(
        json['parentNameSnapshot'],
      ),
      optionNameSnapshot: serializer.fromJson<String>(
        json['optionNameSnapshot'],
      ),
      price: serializer.fromJson<double>(json['price']),
      createdAtLocal: serializer.fromJson<DateTime>(json['createdAtLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'orderItemLocalId': serializer.toJson<String>(orderItemLocalId),
      'serverOrderDetailOptionId': serializer.toJson<int?>(
        serverOrderDetailOptionId,
      ),
      'optionServerId': serializer.toJson<int>(optionServerId),
      'parentNameSnapshot': serializer.toJson<String?>(parentNameSnapshot),
      'optionNameSnapshot': serializer.toJson<String>(optionNameSnapshot),
      'price': serializer.toJson<double>(price),
      'createdAtLocal': serializer.toJson<DateTime>(createdAtLocal),
    };
  }

  LocalOrderItemOption copyWith({
    String? localId,
    String? orderItemLocalId,
    Value<int?> serverOrderDetailOptionId = const Value.absent(),
    int? optionServerId,
    Value<String?> parentNameSnapshot = const Value.absent(),
    String? optionNameSnapshot,
    double? price,
    DateTime? createdAtLocal,
  }) => LocalOrderItemOption(
    localId: localId ?? this.localId,
    orderItemLocalId: orderItemLocalId ?? this.orderItemLocalId,
    serverOrderDetailOptionId: serverOrderDetailOptionId.present
        ? serverOrderDetailOptionId.value
        : this.serverOrderDetailOptionId,
    optionServerId: optionServerId ?? this.optionServerId,
    parentNameSnapshot: parentNameSnapshot.present
        ? parentNameSnapshot.value
        : this.parentNameSnapshot,
    optionNameSnapshot: optionNameSnapshot ?? this.optionNameSnapshot,
    price: price ?? this.price,
    createdAtLocal: createdAtLocal ?? this.createdAtLocal,
  );
  LocalOrderItemOption copyWithCompanion(LocalOrderItemOptionsCompanion data) {
    return LocalOrderItemOption(
      localId: data.localId.present ? data.localId.value : this.localId,
      orderItemLocalId: data.orderItemLocalId.present
          ? data.orderItemLocalId.value
          : this.orderItemLocalId,
      serverOrderDetailOptionId: data.serverOrderDetailOptionId.present
          ? data.serverOrderDetailOptionId.value
          : this.serverOrderDetailOptionId,
      optionServerId: data.optionServerId.present
          ? data.optionServerId.value
          : this.optionServerId,
      parentNameSnapshot: data.parentNameSnapshot.present
          ? data.parentNameSnapshot.value
          : this.parentNameSnapshot,
      optionNameSnapshot: data.optionNameSnapshot.present
          ? data.optionNameSnapshot.value
          : this.optionNameSnapshot,
      price: data.price.present ? data.price.value : this.price,
      createdAtLocal: data.createdAtLocal.present
          ? data.createdAtLocal.value
          : this.createdAtLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrderItemOption(')
          ..write('localId: $localId, ')
          ..write('orderItemLocalId: $orderItemLocalId, ')
          ..write('serverOrderDetailOptionId: $serverOrderDetailOptionId, ')
          ..write('optionServerId: $optionServerId, ')
          ..write('parentNameSnapshot: $parentNameSnapshot, ')
          ..write('optionNameSnapshot: $optionNameSnapshot, ')
          ..write('price: $price, ')
          ..write('createdAtLocal: $createdAtLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    orderItemLocalId,
    serverOrderDetailOptionId,
    optionServerId,
    parentNameSnapshot,
    optionNameSnapshot,
    price,
    createdAtLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrderItemOption &&
          other.localId == this.localId &&
          other.orderItemLocalId == this.orderItemLocalId &&
          other.serverOrderDetailOptionId == this.serverOrderDetailOptionId &&
          other.optionServerId == this.optionServerId &&
          other.parentNameSnapshot == this.parentNameSnapshot &&
          other.optionNameSnapshot == this.optionNameSnapshot &&
          other.price == this.price &&
          other.createdAtLocal == this.createdAtLocal);
}

class LocalOrderItemOptionsCompanion
    extends UpdateCompanion<LocalOrderItemOption> {
  final Value<String> localId;
  final Value<String> orderItemLocalId;
  final Value<int?> serverOrderDetailOptionId;
  final Value<int> optionServerId;
  final Value<String?> parentNameSnapshot;
  final Value<String> optionNameSnapshot;
  final Value<double> price;
  final Value<DateTime> createdAtLocal;
  final Value<int> rowid;
  const LocalOrderItemOptionsCompanion({
    this.localId = const Value.absent(),
    this.orderItemLocalId = const Value.absent(),
    this.serverOrderDetailOptionId = const Value.absent(),
    this.optionServerId = const Value.absent(),
    this.parentNameSnapshot = const Value.absent(),
    this.optionNameSnapshot = const Value.absent(),
    this.price = const Value.absent(),
    this.createdAtLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrderItemOptionsCompanion.insert({
    required String localId,
    required String orderItemLocalId,
    this.serverOrderDetailOptionId = const Value.absent(),
    required int optionServerId,
    this.parentNameSnapshot = const Value.absent(),
    required String optionNameSnapshot,
    this.price = const Value.absent(),
    required DateTime createdAtLocal,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       orderItemLocalId = Value(orderItemLocalId),
       optionServerId = Value(optionServerId),
       optionNameSnapshot = Value(optionNameSnapshot),
       createdAtLocal = Value(createdAtLocal);
  static Insertable<LocalOrderItemOption> custom({
    Expression<String>? localId,
    Expression<String>? orderItemLocalId,
    Expression<int>? serverOrderDetailOptionId,
    Expression<int>? optionServerId,
    Expression<String>? parentNameSnapshot,
    Expression<String>? optionNameSnapshot,
    Expression<double>? price,
    Expression<DateTime>? createdAtLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (orderItemLocalId != null) 'order_item_local_id': orderItemLocalId,
      if (serverOrderDetailOptionId != null)
        'server_order_detail_option_id': serverOrderDetailOptionId,
      if (optionServerId != null) 'option_server_id': optionServerId,
      if (parentNameSnapshot != null)
        'parent_name_snapshot': parentNameSnapshot,
      if (optionNameSnapshot != null)
        'option_name_snapshot': optionNameSnapshot,
      if (price != null) 'price': price,
      if (createdAtLocal != null) 'created_at_local': createdAtLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrderItemOptionsCompanion copyWith({
    Value<String>? localId,
    Value<String>? orderItemLocalId,
    Value<int?>? serverOrderDetailOptionId,
    Value<int>? optionServerId,
    Value<String?>? parentNameSnapshot,
    Value<String>? optionNameSnapshot,
    Value<double>? price,
    Value<DateTime>? createdAtLocal,
    Value<int>? rowid,
  }) {
    return LocalOrderItemOptionsCompanion(
      localId: localId ?? this.localId,
      orderItemLocalId: orderItemLocalId ?? this.orderItemLocalId,
      serverOrderDetailOptionId:
          serverOrderDetailOptionId ?? this.serverOrderDetailOptionId,
      optionServerId: optionServerId ?? this.optionServerId,
      parentNameSnapshot: parentNameSnapshot ?? this.parentNameSnapshot,
      optionNameSnapshot: optionNameSnapshot ?? this.optionNameSnapshot,
      price: price ?? this.price,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (orderItemLocalId.present) {
      map['order_item_local_id'] = Variable<String>(orderItemLocalId.value);
    }
    if (serverOrderDetailOptionId.present) {
      map['server_order_detail_option_id'] = Variable<int>(
        serverOrderDetailOptionId.value,
      );
    }
    if (optionServerId.present) {
      map['option_server_id'] = Variable<int>(optionServerId.value);
    }
    if (parentNameSnapshot.present) {
      map['parent_name_snapshot'] = Variable<String>(parentNameSnapshot.value);
    }
    if (optionNameSnapshot.present) {
      map['option_name_snapshot'] = Variable<String>(optionNameSnapshot.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (createdAtLocal.present) {
      map['created_at_local'] = Variable<DateTime>(createdAtLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrderItemOptionsCompanion(')
          ..write('localId: $localId, ')
          ..write('orderItemLocalId: $orderItemLocalId, ')
          ..write('serverOrderDetailOptionId: $serverOrderDetailOptionId, ')
          ..write('optionServerId: $optionServerId, ')
          ..write('parentNameSnapshot: $parentNameSnapshot, ')
          ..write('optionNameSnapshot: $optionNameSnapshot, ')
          ..write('price: $price, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPaymentsTable extends LocalPayments
    with TableInfo<$LocalPaymentsTable, LocalPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderLocalIdMeta = const VerificationMeta(
    'orderLocalId',
  );
  @override
  late final GeneratedColumn<String> orderLocalId = GeneratedColumn<String>(
    'order_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverPaymentIdMeta = const VerificationMeta(
    'serverPaymentId',
  );
  @override
  late final GeneratedColumn<int> serverPaymentId = GeneratedColumn<int>(
    'server_payment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _manualPaymentServerIdMeta =
      const VerificationMeta('manualPaymentServerId');
  @override
  late final GeneratedColumn<int> manualPaymentServerId = GeneratedColumn<int>(
    'manual_payment_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountBeforePpnMeta = const VerificationMeta(
    'amountBeforePpn',
  );
  @override
  late final GeneratedColumn<double> amountBeforePpn = GeneratedColumn<double>(
    'amount_before_ppn',
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
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _proofImageLocalPathMeta =
      const VerificationMeta('proofImageLocalPath');
  @override
  late final GeneratedColumn<String> proofImageLocalPath =
      GeneratedColumn<String>(
        'proof_image_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _proofImageUploadedMeta =
      const VerificationMeta('proofImageUploaded');
  @override
  late final GeneratedColumn<bool> proofImageUploaded = GeneratedColumn<bool>(
    'proof_image_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("proof_image_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtLocalMeta = const VerificationMeta(
    'createdAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtLocal =
      GeneratedColumn<DateTime>(
        'created_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
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
    localId,
    orderLocalId,
    serverPaymentId,
    paymentType,
    manualPaymentServerId,
    amountBeforePpn,
    ppn,
    paidAmount,
    changeAmount,
    paymentStatus,
    note,
    proofImageLocalPath,
    proofImageUploaded,
    createdAtLocal,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('order_local_id')) {
      context.handle(
        _orderLocalIdMeta,
        orderLocalId.isAcceptableOrUnknown(
          data['order_local_id']!,
          _orderLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderLocalIdMeta);
    }
    if (data.containsKey('server_payment_id')) {
      context.handle(
        _serverPaymentIdMeta,
        serverPaymentId.isAcceptableOrUnknown(
          data['server_payment_id']!,
          _serverPaymentIdMeta,
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
    if (data.containsKey('manual_payment_server_id')) {
      context.handle(
        _manualPaymentServerIdMeta,
        manualPaymentServerId.isAcceptableOrUnknown(
          data['manual_payment_server_id']!,
          _manualPaymentServerIdMeta,
        ),
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
    if (data.containsKey('ppn')) {
      context.handle(
        _ppnMeta,
        ppn.isAcceptableOrUnknown(data['ppn']!, _ppnMeta),
      );
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
    if (data.containsKey('proof_image_local_path')) {
      context.handle(
        _proofImageLocalPathMeta,
        proofImageLocalPath.isAcceptableOrUnknown(
          data['proof_image_local_path']!,
          _proofImageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('proof_image_uploaded')) {
      context.handle(
        _proofImageUploadedMeta,
        proofImageUploaded.isAcceptableOrUnknown(
          data['proof_image_uploaded']!,
          _proofImageUploadedMeta,
        ),
      );
    }
    if (data.containsKey('created_at_local')) {
      context.handle(
        _createdAtLocalMeta,
        createdAtLocal.isAcceptableOrUnknown(
          data['created_at_local']!,
          _createdAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtLocalMeta);
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
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPayment(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      orderLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_local_id'],
      )!,
      serverPaymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_payment_id'],
      ),
      paymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_type'],
      )!,
      manualPaymentServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_payment_server_id'],
      ),
      amountBeforePpn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_before_ppn'],
      )!,
      ppn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn'],
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
      proofImageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_image_local_path'],
      ),
      proofImageUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}proof_image_uploaded'],
      )!,
      createdAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_local'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LocalPaymentsTable createAlias(String alias) {
    return $LocalPaymentsTable(attachedDatabase, alias);
  }
}

class LocalPayment extends DataClass implements Insertable<LocalPayment> {
  final String localId;
  final String orderLocalId;
  final int? serverPaymentId;
  final String paymentType;
  final int? manualPaymentServerId;
  final double amountBeforePpn;
  final double ppn;
  final double paidAmount;
  final double changeAmount;
  final String paymentStatus;
  final String? note;
  final String? proofImageLocalPath;
  final bool proofImageUploaded;
  final DateTime createdAtLocal;
  final DateTime? syncedAt;
  const LocalPayment({
    required this.localId,
    required this.orderLocalId,
    this.serverPaymentId,
    required this.paymentType,
    this.manualPaymentServerId,
    required this.amountBeforePpn,
    required this.ppn,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentStatus,
    this.note,
    this.proofImageLocalPath,
    required this.proofImageUploaded,
    required this.createdAtLocal,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['order_local_id'] = Variable<String>(orderLocalId);
    if (!nullToAbsent || serverPaymentId != null) {
      map['server_payment_id'] = Variable<int>(serverPaymentId);
    }
    map['payment_type'] = Variable<String>(paymentType);
    if (!nullToAbsent || manualPaymentServerId != null) {
      map['manual_payment_server_id'] = Variable<int>(manualPaymentServerId);
    }
    map['amount_before_ppn'] = Variable<double>(amountBeforePpn);
    map['ppn'] = Variable<double>(ppn);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['change_amount'] = Variable<double>(changeAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || proofImageLocalPath != null) {
      map['proof_image_local_path'] = Variable<String>(proofImageLocalPath);
    }
    map['proof_image_uploaded'] = Variable<bool>(proofImageUploaded);
    map['created_at_local'] = Variable<DateTime>(createdAtLocal);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalPaymentsCompanion toCompanion(bool nullToAbsent) {
    return LocalPaymentsCompanion(
      localId: Value(localId),
      orderLocalId: Value(orderLocalId),
      serverPaymentId: serverPaymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverPaymentId),
      paymentType: Value(paymentType),
      manualPaymentServerId: manualPaymentServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(manualPaymentServerId),
      amountBeforePpn: Value(amountBeforePpn),
      ppn: Value(ppn),
      paidAmount: Value(paidAmount),
      changeAmount: Value(changeAmount),
      paymentStatus: Value(paymentStatus),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      proofImageLocalPath: proofImageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(proofImageLocalPath),
      proofImageUploaded: Value(proofImageUploaded),
      createdAtLocal: Value(createdAtLocal),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPayment(
      localId: serializer.fromJson<String>(json['localId']),
      orderLocalId: serializer.fromJson<String>(json['orderLocalId']),
      serverPaymentId: serializer.fromJson<int?>(json['serverPaymentId']),
      paymentType: serializer.fromJson<String>(json['paymentType']),
      manualPaymentServerId: serializer.fromJson<int?>(
        json['manualPaymentServerId'],
      ),
      amountBeforePpn: serializer.fromJson<double>(json['amountBeforePpn']),
      ppn: serializer.fromJson<double>(json['ppn']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      changeAmount: serializer.fromJson<double>(json['changeAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      note: serializer.fromJson<String?>(json['note']),
      proofImageLocalPath: serializer.fromJson<String?>(
        json['proofImageLocalPath'],
      ),
      proofImageUploaded: serializer.fromJson<bool>(json['proofImageUploaded']),
      createdAtLocal: serializer.fromJson<DateTime>(json['createdAtLocal']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'orderLocalId': serializer.toJson<String>(orderLocalId),
      'serverPaymentId': serializer.toJson<int?>(serverPaymentId),
      'paymentType': serializer.toJson<String>(paymentType),
      'manualPaymentServerId': serializer.toJson<int?>(manualPaymentServerId),
      'amountBeforePpn': serializer.toJson<double>(amountBeforePpn),
      'ppn': serializer.toJson<double>(ppn),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'changeAmount': serializer.toJson<double>(changeAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'note': serializer.toJson<String?>(note),
      'proofImageLocalPath': serializer.toJson<String?>(proofImageLocalPath),
      'proofImageUploaded': serializer.toJson<bool>(proofImageUploaded),
      'createdAtLocal': serializer.toJson<DateTime>(createdAtLocal),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalPayment copyWith({
    String? localId,
    String? orderLocalId,
    Value<int?> serverPaymentId = const Value.absent(),
    String? paymentType,
    Value<int?> manualPaymentServerId = const Value.absent(),
    double? amountBeforePpn,
    double? ppn,
    double? paidAmount,
    double? changeAmount,
    String? paymentStatus,
    Value<String?> note = const Value.absent(),
    Value<String?> proofImageLocalPath = const Value.absent(),
    bool? proofImageUploaded,
    DateTime? createdAtLocal,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LocalPayment(
    localId: localId ?? this.localId,
    orderLocalId: orderLocalId ?? this.orderLocalId,
    serverPaymentId: serverPaymentId.present
        ? serverPaymentId.value
        : this.serverPaymentId,
    paymentType: paymentType ?? this.paymentType,
    manualPaymentServerId: manualPaymentServerId.present
        ? manualPaymentServerId.value
        : this.manualPaymentServerId,
    amountBeforePpn: amountBeforePpn ?? this.amountBeforePpn,
    ppn: ppn ?? this.ppn,
    paidAmount: paidAmount ?? this.paidAmount,
    changeAmount: changeAmount ?? this.changeAmount,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    note: note.present ? note.value : this.note,
    proofImageLocalPath: proofImageLocalPath.present
        ? proofImageLocalPath.value
        : this.proofImageLocalPath,
    proofImageUploaded: proofImageUploaded ?? this.proofImageUploaded,
    createdAtLocal: createdAtLocal ?? this.createdAtLocal,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LocalPayment copyWithCompanion(LocalPaymentsCompanion data) {
    return LocalPayment(
      localId: data.localId.present ? data.localId.value : this.localId,
      orderLocalId: data.orderLocalId.present
          ? data.orderLocalId.value
          : this.orderLocalId,
      serverPaymentId: data.serverPaymentId.present
          ? data.serverPaymentId.value
          : this.serverPaymentId,
      paymentType: data.paymentType.present
          ? data.paymentType.value
          : this.paymentType,
      manualPaymentServerId: data.manualPaymentServerId.present
          ? data.manualPaymentServerId.value
          : this.manualPaymentServerId,
      amountBeforePpn: data.amountBeforePpn.present
          ? data.amountBeforePpn.value
          : this.amountBeforePpn,
      ppn: data.ppn.present ? data.ppn.value : this.ppn,
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
      proofImageLocalPath: data.proofImageLocalPath.present
          ? data.proofImageLocalPath.value
          : this.proofImageLocalPath,
      proofImageUploaded: data.proofImageUploaded.present
          ? data.proofImageUploaded.value
          : this.proofImageUploaded,
      createdAtLocal: data.createdAtLocal.present
          ? data.createdAtLocal.value
          : this.createdAtLocal,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPayment(')
          ..write('localId: $localId, ')
          ..write('orderLocalId: $orderLocalId, ')
          ..write('serverPaymentId: $serverPaymentId, ')
          ..write('paymentType: $paymentType, ')
          ..write('manualPaymentServerId: $manualPaymentServerId, ')
          ..write('amountBeforePpn: $amountBeforePpn, ')
          ..write('ppn: $ppn, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('note: $note, ')
          ..write('proofImageLocalPath: $proofImageLocalPath, ')
          ..write('proofImageUploaded: $proofImageUploaded, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    orderLocalId,
    serverPaymentId,
    paymentType,
    manualPaymentServerId,
    amountBeforePpn,
    ppn,
    paidAmount,
    changeAmount,
    paymentStatus,
    note,
    proofImageLocalPath,
    proofImageUploaded,
    createdAtLocal,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPayment &&
          other.localId == this.localId &&
          other.orderLocalId == this.orderLocalId &&
          other.serverPaymentId == this.serverPaymentId &&
          other.paymentType == this.paymentType &&
          other.manualPaymentServerId == this.manualPaymentServerId &&
          other.amountBeforePpn == this.amountBeforePpn &&
          other.ppn == this.ppn &&
          other.paidAmount == this.paidAmount &&
          other.changeAmount == this.changeAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.note == this.note &&
          other.proofImageLocalPath == this.proofImageLocalPath &&
          other.proofImageUploaded == this.proofImageUploaded &&
          other.createdAtLocal == this.createdAtLocal &&
          other.syncedAt == this.syncedAt);
}

class LocalPaymentsCompanion extends UpdateCompanion<LocalPayment> {
  final Value<String> localId;
  final Value<String> orderLocalId;
  final Value<int?> serverPaymentId;
  final Value<String> paymentType;
  final Value<int?> manualPaymentServerId;
  final Value<double> amountBeforePpn;
  final Value<double> ppn;
  final Value<double> paidAmount;
  final Value<double> changeAmount;
  final Value<String> paymentStatus;
  final Value<String?> note;
  final Value<String?> proofImageLocalPath;
  final Value<bool> proofImageUploaded;
  final Value<DateTime> createdAtLocal;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalPaymentsCompanion({
    this.localId = const Value.absent(),
    this.orderLocalId = const Value.absent(),
    this.serverPaymentId = const Value.absent(),
    this.paymentType = const Value.absent(),
    this.manualPaymentServerId = const Value.absent(),
    this.amountBeforePpn = const Value.absent(),
    this.ppn = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.proofImageLocalPath = const Value.absent(),
    this.proofImageUploaded = const Value.absent(),
    this.createdAtLocal = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPaymentsCompanion.insert({
    required String localId,
    required String orderLocalId,
    this.serverPaymentId = const Value.absent(),
    required String paymentType,
    this.manualPaymentServerId = const Value.absent(),
    this.amountBeforePpn = const Value.absent(),
    this.ppn = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.proofImageLocalPath = const Value.absent(),
    this.proofImageUploaded = const Value.absent(),
    required DateTime createdAtLocal,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       orderLocalId = Value(orderLocalId),
       paymentType = Value(paymentType),
       createdAtLocal = Value(createdAtLocal);
  static Insertable<LocalPayment> custom({
    Expression<String>? localId,
    Expression<String>? orderLocalId,
    Expression<int>? serverPaymentId,
    Expression<String>? paymentType,
    Expression<int>? manualPaymentServerId,
    Expression<double>? amountBeforePpn,
    Expression<double>? ppn,
    Expression<double>? paidAmount,
    Expression<double>? changeAmount,
    Expression<String>? paymentStatus,
    Expression<String>? note,
    Expression<String>? proofImageLocalPath,
    Expression<bool>? proofImageUploaded,
    Expression<DateTime>? createdAtLocal,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (orderLocalId != null) 'order_local_id': orderLocalId,
      if (serverPaymentId != null) 'server_payment_id': serverPaymentId,
      if (paymentType != null) 'payment_type': paymentType,
      if (manualPaymentServerId != null)
        'manual_payment_server_id': manualPaymentServerId,
      if (amountBeforePpn != null) 'amount_before_ppn': amountBeforePpn,
      if (ppn != null) 'ppn': ppn,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (note != null) 'note': note,
      if (proofImageLocalPath != null)
        'proof_image_local_path': proofImageLocalPath,
      if (proofImageUploaded != null)
        'proof_image_uploaded': proofImageUploaded,
      if (createdAtLocal != null) 'created_at_local': createdAtLocal,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPaymentsCompanion copyWith({
    Value<String>? localId,
    Value<String>? orderLocalId,
    Value<int?>? serverPaymentId,
    Value<String>? paymentType,
    Value<int?>? manualPaymentServerId,
    Value<double>? amountBeforePpn,
    Value<double>? ppn,
    Value<double>? paidAmount,
    Value<double>? changeAmount,
    Value<String>? paymentStatus,
    Value<String?>? note,
    Value<String?>? proofImageLocalPath,
    Value<bool>? proofImageUploaded,
    Value<DateTime>? createdAtLocal,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalPaymentsCompanion(
      localId: localId ?? this.localId,
      orderLocalId: orderLocalId ?? this.orderLocalId,
      serverPaymentId: serverPaymentId ?? this.serverPaymentId,
      paymentType: paymentType ?? this.paymentType,
      manualPaymentServerId:
          manualPaymentServerId ?? this.manualPaymentServerId,
      amountBeforePpn: amountBeforePpn ?? this.amountBeforePpn,
      ppn: ppn ?? this.ppn,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      note: note ?? this.note,
      proofImageLocalPath: proofImageLocalPath ?? this.proofImageLocalPath,
      proofImageUploaded: proofImageUploaded ?? this.proofImageUploaded,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (orderLocalId.present) {
      map['order_local_id'] = Variable<String>(orderLocalId.value);
    }
    if (serverPaymentId.present) {
      map['server_payment_id'] = Variable<int>(serverPaymentId.value);
    }
    if (paymentType.present) {
      map['payment_type'] = Variable<String>(paymentType.value);
    }
    if (manualPaymentServerId.present) {
      map['manual_payment_server_id'] = Variable<int>(
        manualPaymentServerId.value,
      );
    }
    if (amountBeforePpn.present) {
      map['amount_before_ppn'] = Variable<double>(amountBeforePpn.value);
    }
    if (ppn.present) {
      map['ppn'] = Variable<double>(ppn.value);
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
    if (proofImageLocalPath.present) {
      map['proof_image_local_path'] = Variable<String>(
        proofImageLocalPath.value,
      );
    }
    if (proofImageUploaded.present) {
      map['proof_image_uploaded'] = Variable<bool>(proofImageUploaded.value);
    }
    if (createdAtLocal.present) {
      map['created_at_local'] = Variable<DateTime>(createdAtLocal.value);
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
    return (StringBuffer('LocalPaymentsCompanion(')
          ..write('localId: $localId, ')
          ..write('orderLocalId: $orderLocalId, ')
          ..write('serverPaymentId: $serverPaymentId, ')
          ..write('paymentType: $paymentType, ')
          ..write('manualPaymentServerId: $manualPaymentServerId, ')
          ..write('amountBeforePpn: $amountBeforePpn, ')
          ..write('ppn: $ppn, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('note: $note, ')
          ..write('proofImageLocalPath: $proofImageLocalPath, ')
          ..write('proofImageUploaded: $proofImageUploaded, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityLocalIdMeta = const VerificationMeta(
    'entityLocalId',
  );
  @override
  late final GeneratedColumn<String> entityLocalId = GeneratedColumn<String>(
    'entity_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependsOnQueueIdMeta = const VerificationMeta(
    'dependsOnQueueId',
  );
  @override
  late final GeneratedColumn<int> dependsOnQueueId = GeneratedColumn<int>(
    'depends_on_queue_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityLocalId,
    action,
    dependsOnQueueId,
    payloadJson,
    status,
    attemptCount,
    lastError,
    nextRetryAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
        _entityLocalIdMeta,
        entityLocalId.isAcceptableOrUnknown(
          data['entity_local_id']!,
          _entityLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityLocalIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('depends_on_queue_id')) {
      context.handle(
        _dependsOnQueueIdMeta,
        dependsOnQueueId.isAcceptableOrUnknown(
          data['depends_on_queue_id']!,
          _dependsOnQueueIdMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_local_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      dependsOnQueueId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depends_on_queue_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final String entityLocalId;
  final String action;
  final int? dependsOnQueueId;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    required this.action,
    this.dependsOnQueueId,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    this.lastError,
    this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_local_id'] = Variable<String>(entityLocalId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || dependsOnQueueId != null) {
      map['depends_on_queue_id'] = Variable<int>(dependsOnQueueId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityLocalId: Value(entityLocalId),
      action: Value(action),
      dependsOnQueueId: dependsOnQueueId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOnQueueId),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityLocalId: serializer.fromJson<String>(json['entityLocalId']),
      action: serializer.fromJson<String>(json['action']),
      dependsOnQueueId: serializer.fromJson<int?>(json['dependsOnQueueId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityLocalId': serializer.toJson<String>(entityLocalId),
      'action': serializer.toJson<String>(action),
      'dependsOnQueueId': serializer.toJson<int?>(dependsOnQueueId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? entityType,
    String? entityLocalId,
    String? action,
    Value<int?> dependsOnQueueId = const Value.absent(),
    String? payloadJson,
    String? status,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityLocalId: entityLocalId ?? this.entityLocalId,
    action: action ?? this.action,
    dependsOnQueueId: dependsOnQueueId.present
        ? dependsOnQueueId.value
        : this.dependsOnQueueId,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityLocalId: data.entityLocalId.present
          ? data.entityLocalId.value
          : this.entityLocalId,
      action: data.action.present ? data.action.value : this.action,
      dependsOnQueueId: data.dependsOnQueueId.present
          ? data.dependsOnQueueId.value
          : this.dependsOnQueueId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('action: $action, ')
          ..write('dependsOnQueueId: $dependsOnQueueId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityLocalId,
    action,
    dependsOnQueueId,
    payloadJson,
    status,
    attemptCount,
    lastError,
    nextRetryAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.action == this.action &&
          other.dependsOnQueueId == this.dependsOnQueueId &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityLocalId;
  final Value<String> action;
  final Value<int?> dependsOnQueueId;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.action = const Value.absent(),
    this.dependsOnQueueId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityLocalId,
    required String action,
    this.dependsOnQueueId = const Value.absent(),
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : entityType = Value(entityType),
       entityLocalId = Value(entityLocalId),
       action = Value(action),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityLocalId,
    Expression<String>? action,
    Expression<int>? dependsOnQueueId,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (action != null) 'action': action,
      if (dependsOnQueueId != null) 'depends_on_queue_id': dependsOnQueueId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityLocalId,
    Value<String>? action,
    Value<int?>? dependsOnQueueId,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      action: action ?? this.action,
      dependsOnQueueId: dependsOnQueueId ?? this.dependsOnQueueId,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<String>(entityLocalId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (dependsOnQueueId.present) {
      map['depends_on_queue_id'] = Variable<int>(dependsOnQueueId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('action: $action, ')
          ..write('dependsOnQueueId: $dependsOnQueueId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPaymentOrdersTable extends CachedPaymentOrders
    with TableInfo<$CachedPaymentOrdersTable, CachedPaymentOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPaymentOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ppnPercentMeta = const VerificationMeta(
    'ppnPercent',
  );
  @override
  late final GeneratedColumn<double> ppnPercent = GeneratedColumn<double>(
    'ppn_percent',
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
  static const VerificationMeta _isPendingDeleteMeta = const VerificationMeta(
    'isPendingDelete',
  );
  @override
  late final GeneratedColumn<bool> isPendingDelete = GeneratedColumn<bool>(
    'is_pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
    'grand_total',
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
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    paymentRequestJson,
    latestPaymentJson,
    paymentMethod,
    orderStatus,
    detailJson,
    subtotal,
    ppnPercent,
    isPpnActive,
    isPendingDelete,
    grandTotal,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payment_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPaymentOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_bookingOrderCodeMeta);
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
    if (data.containsKey('table_no')) {
      context.handle(
        _tableNoMeta,
        tableNo.isAcceptableOrUnknown(data['table_no']!, _tableNoMeta),
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
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderStatusMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('ppn_percent')) {
      context.handle(
        _ppnPercentMeta,
        ppnPercent.isAcceptableOrUnknown(data['ppn_percent']!, _ppnPercentMeta),
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
    if (data.containsKey('is_pending_delete')) {
      context.handle(
        _isPendingDeleteMeta,
        isPendingDelete.isAcceptableOrUnknown(
          data['is_pending_delete']!,
          _isPendingDeleteMeta,
        ),
      );
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
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
  Set<GeneratedColumn> get $primaryKey => {serverId};
  @override
  CachedPaymentOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPaymentOrder(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      bookingOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_code'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      tableNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no'],
      ),
      paymentRequestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_request_json'],
      ),
      latestPaymentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_payment_json'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      ppnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn_percent'],
      )!,
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      isPendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_delete'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPaymentOrdersTable createAlias(String alias) {
    return $CachedPaymentOrdersTable(attachedDatabase, alias);
  }
}

class CachedPaymentOrder extends DataClass
    implements Insertable<CachedPaymentOrder> {
  final int serverId;
  final String bookingOrderCode;
  final String customerName;
  final String? tableNo;
  final String? paymentRequestJson;
  final String? latestPaymentJson;
  final String? paymentMethod;
  final String orderStatus;
  final String? detailJson;
  final double subtotal;
  final double ppnPercent;
  final bool isPpnActive;
  final bool isPendingDelete;
  final double grandTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime cachedAt;
  const CachedPaymentOrder({
    required this.serverId,
    required this.bookingOrderCode,
    required this.customerName,
    this.tableNo,
    this.paymentRequestJson,
    this.latestPaymentJson,
    this.paymentMethod,
    required this.orderStatus,
    this.detailJson,
    required this.subtotal,
    required this.ppnPercent,
    required this.isPpnActive,
    required this.isPendingDelete,
    required this.grandTotal,
    this.createdAt,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['booking_order_code'] = Variable<String>(bookingOrderCode);
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || tableNo != null) {
      map['table_no'] = Variable<String>(tableNo);
    }
    if (!nullToAbsent || paymentRequestJson != null) {
      map['payment_request_json'] = Variable<String>(paymentRequestJson);
    }
    if (!nullToAbsent || latestPaymentJson != null) {
      map['latest_payment_json'] = Variable<String>(latestPaymentJson);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['order_status'] = Variable<String>(orderStatus);
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['ppn_percent'] = Variable<double>(ppnPercent);
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    map['is_pending_delete'] = Variable<bool>(isPendingDelete);
    map['grand_total'] = Variable<double>(grandTotal);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPaymentOrdersCompanion toCompanion(bool nullToAbsent) {
    return CachedPaymentOrdersCompanion(
      serverId: Value(serverId),
      bookingOrderCode: Value(bookingOrderCode),
      customerName: Value(customerName),
      tableNo: tableNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNo),
      paymentRequestJson: paymentRequestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentRequestJson),
      latestPaymentJson: latestPaymentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestPaymentJson),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      orderStatus: Value(orderStatus),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
      subtotal: Value(subtotal),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      isPendingDelete: Value(isPendingDelete),
      grandTotal: Value(grandTotal),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPaymentOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPaymentOrder(
      serverId: serializer.fromJson<int>(json['serverId']),
      bookingOrderCode: serializer.fromJson<String>(json['bookingOrderCode']),
      customerName: serializer.fromJson<String>(json['customerName']),
      tableNo: serializer.fromJson<String?>(json['tableNo']),
      paymentRequestJson: serializer.fromJson<String?>(
        json['paymentRequestJson'],
      ),
      latestPaymentJson: serializer.fromJson<String?>(
        json['latestPaymentJson'],
      ),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      ppnPercent: serializer.fromJson<double>(json['ppnPercent']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      isPendingDelete: serializer.fromJson<bool>(json['isPendingDelete']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'bookingOrderCode': serializer.toJson<String>(bookingOrderCode),
      'customerName': serializer.toJson<String>(customerName),
      'tableNo': serializer.toJson<String?>(tableNo),
      'paymentRequestJson': serializer.toJson<String?>(paymentRequestJson),
      'latestPaymentJson': serializer.toJson<String?>(latestPaymentJson),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'detailJson': serializer.toJson<String?>(detailJson),
      'subtotal': serializer.toJson<double>(subtotal),
      'ppnPercent': serializer.toJson<double>(ppnPercent),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'isPendingDelete': serializer.toJson<bool>(isPendingDelete),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPaymentOrder copyWith({
    int? serverId,
    String? bookingOrderCode,
    String? customerName,
    Value<String?> tableNo = const Value.absent(),
    Value<String?> paymentRequestJson = const Value.absent(),
    Value<String?> latestPaymentJson = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    String? orderStatus,
    Value<String?> detailJson = const Value.absent(),
    double? subtotal,
    double? ppnPercent,
    bool? isPpnActive,
    bool? isPendingDelete,
    double? grandTotal,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedPaymentOrder(
    serverId: serverId ?? this.serverId,
    bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
    customerName: customerName ?? this.customerName,
    tableNo: tableNo.present ? tableNo.value : this.tableNo,
    paymentRequestJson: paymentRequestJson.present
        ? paymentRequestJson.value
        : this.paymentRequestJson,
    latestPaymentJson: latestPaymentJson.present
        ? latestPaymentJson.value
        : this.latestPaymentJson,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    orderStatus: orderStatus ?? this.orderStatus,
    detailJson: detailJson.present ? detailJson.value : this.detailJson,
    subtotal: subtotal ?? this.subtotal,
    ppnPercent: ppnPercent ?? this.ppnPercent,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    isPendingDelete: isPendingDelete ?? this.isPendingDelete,
    grandTotal: grandTotal ?? this.grandTotal,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPaymentOrder copyWithCompanion(CachedPaymentOrdersCompanion data) {
    return CachedPaymentOrder(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderCode: data.bookingOrderCode.present
          ? data.bookingOrderCode.value
          : this.bookingOrderCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      tableNo: data.tableNo.present ? data.tableNo.value : this.tableNo,
      paymentRequestJson: data.paymentRequestJson.present
          ? data.paymentRequestJson.value
          : this.paymentRequestJson,
      latestPaymentJson: data.latestPaymentJson.present
          ? data.latestPaymentJson.value
          : this.latestPaymentJson,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      ppnPercent: data.ppnPercent.present
          ? data.ppnPercent.value
          : this.ppnPercent,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      isPendingDelete: data.isPendingDelete.present
          ? data.isPendingDelete.value
          : this.isPendingDelete,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrder(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('paymentRequestJson: $paymentRequestJson, ')
          ..write('latestPaymentJson: $latestPaymentJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('detailJson: $detailJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    paymentRequestJson,
    latestPaymentJson,
    paymentMethod,
    orderStatus,
    detailJson,
    subtotal,
    ppnPercent,
    isPpnActive,
    isPendingDelete,
    grandTotal,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPaymentOrder &&
          other.serverId == this.serverId &&
          other.bookingOrderCode == this.bookingOrderCode &&
          other.customerName == this.customerName &&
          other.tableNo == this.tableNo &&
          other.paymentRequestJson == this.paymentRequestJson &&
          other.latestPaymentJson == this.latestPaymentJson &&
          other.paymentMethod == this.paymentMethod &&
          other.orderStatus == this.orderStatus &&
          other.detailJson == this.detailJson &&
          other.subtotal == this.subtotal &&
          other.ppnPercent == this.ppnPercent &&
          other.isPpnActive == this.isPpnActive &&
          other.isPendingDelete == this.isPendingDelete &&
          other.grandTotal == this.grandTotal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedPaymentOrdersCompanion extends UpdateCompanion<CachedPaymentOrder> {
  final Value<int> serverId;
  final Value<String> bookingOrderCode;
  final Value<String> customerName;
  final Value<String?> tableNo;
  final Value<String?> paymentRequestJson;
  final Value<String?> latestPaymentJson;
  final Value<String?> paymentMethod;
  final Value<String> orderStatus;
  final Value<String?> detailJson;
  final Value<double> subtotal;
  final Value<double> ppnPercent;
  final Value<bool> isPpnActive;
  final Value<bool> isPendingDelete;
  final Value<double> grandTotal;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime> cachedAt;
  const CachedPaymentOrdersCompanion({
    this.serverId = const Value.absent(),
    this.bookingOrderCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.paymentRequestJson = const Value.absent(),
    this.latestPaymentJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedPaymentOrdersCompanion.insert({
    this.serverId = const Value.absent(),
    required String bookingOrderCode,
    required String customerName,
    this.tableNo = const Value.absent(),
    this.paymentRequestJson = const Value.absent(),
    this.latestPaymentJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required String orderStatus,
    this.detailJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required DateTime cachedAt,
  }) : bookingOrderCode = Value(bookingOrderCode),
       customerName = Value(customerName),
       orderStatus = Value(orderStatus),
       cachedAt = Value(cachedAt);
  static Insertable<CachedPaymentOrder> custom({
    Expression<int>? serverId,
    Expression<String>? bookingOrderCode,
    Expression<String>? customerName,
    Expression<String>? tableNo,
    Expression<String>? paymentRequestJson,
    Expression<String>? latestPaymentJson,
    Expression<String>? paymentMethod,
    Expression<String>? orderStatus,
    Expression<String>? detailJson,
    Expression<double>? subtotal,
    Expression<double>? ppnPercent,
    Expression<bool>? isPpnActive,
    Expression<bool>? isPendingDelete,
    Expression<double>? grandTotal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderCode != null) 'booking_order_code': bookingOrderCode,
      if (customerName != null) 'customer_name': customerName,
      if (tableNo != null) 'table_no': tableNo,
      if (paymentRequestJson != null)
        'payment_request_json': paymentRequestJson,
      if (latestPaymentJson != null) 'latest_payment_json': latestPaymentJson,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (orderStatus != null) 'order_status': orderStatus,
      if (detailJson != null) 'detail_json': detailJson,
      if (subtotal != null) 'subtotal': subtotal,
      if (ppnPercent != null) 'ppn_percent': ppnPercent,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (isPendingDelete != null) 'is_pending_delete': isPendingDelete,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedPaymentOrdersCompanion copyWith({
    Value<int>? serverId,
    Value<String>? bookingOrderCode,
    Value<String>? customerName,
    Value<String?>? tableNo,
    Value<String?>? paymentRequestJson,
    Value<String?>? latestPaymentJson,
    Value<String?>? paymentMethod,
    Value<String>? orderStatus,
    Value<String?>? detailJson,
    Value<double>? subtotal,
    Value<double>? ppnPercent,
    Value<bool>? isPpnActive,
    Value<bool>? isPendingDelete,
    Value<double>? grandTotal,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime>? cachedAt,
  }) {
    return CachedPaymentOrdersCompanion(
      serverId: serverId ?? this.serverId,
      bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
      customerName: customerName ?? this.customerName,
      tableNo: tableNo ?? this.tableNo,
      paymentRequestJson: paymentRequestJson ?? this.paymentRequestJson,
      latestPaymentJson: latestPaymentJson ?? this.latestPaymentJson,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderStatus: orderStatus ?? this.orderStatus,
      detailJson: detailJson ?? this.detailJson,
      subtotal: subtotal ?? this.subtotal,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      isPendingDelete: isPendingDelete ?? this.isPendingDelete,
      grandTotal: grandTotal ?? this.grandTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderCode.present) {
      map['booking_order_code'] = Variable<String>(bookingOrderCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (tableNo.present) {
      map['table_no'] = Variable<String>(tableNo.value);
    }
    if (paymentRequestJson.present) {
      map['payment_request_json'] = Variable<String>(paymentRequestJson.value);
    }
    if (latestPaymentJson.present) {
      map['latest_payment_json'] = Variable<String>(latestPaymentJson.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (ppnPercent.present) {
      map['ppn_percent'] = Variable<double>(ppnPercent.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (isPendingDelete.present) {
      map['is_pending_delete'] = Variable<bool>(isPendingDelete.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrdersCompanion(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('paymentRequestJson: $paymentRequestJson, ')
          ..write('latestPaymentJson: $latestPaymentJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('detailJson: $detailJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedProcessOrdersTable extends CachedProcessOrders
    with TableInfo<$CachedProcessOrdersTable, CachedProcessOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProcessOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _processRequestJsonMeta =
      const VerificationMeta('processRequestJson');
  @override
  late final GeneratedColumn<String> processRequestJson =
      GeneratedColumn<String>(
        'process_request_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestProcessJsonMeta = const VerificationMeta(
    'latestProcessJson',
  );
  @override
  late final GeneratedColumn<String> latestProcessJson =
      GeneratedColumn<String>(
        'latest_process_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ppnPercentMeta = const VerificationMeta(
    'ppnPercent',
  );
  @override
  late final GeneratedColumn<double> ppnPercent = GeneratedColumn<double>(
    'ppn_percent',
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
  static const VerificationMeta _pendingActionMeta = const VerificationMeta(
    'pendingAction',
  );
  @override
  late final GeneratedColumn<String> pendingAction = GeneratedColumn<String>(
    'pending_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedLocallyMeta = const VerificationMeta(
    'deletedLocally',
  );
  @override
  late final GeneratedColumn<bool> deletedLocally = GeneratedColumn<bool>(
    'deleted_locally',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_locally" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    processRequestJson,
    latestProcessJson,
    detailJson,
    paymentMethod,
    orderStatus,
    subtotal,
    ppnPercent,
    isPpnActive,
    pendingAction,
    isSynced,
    deletedLocally,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_process_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProcessOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_bookingOrderCodeMeta);
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
    if (data.containsKey('table_no')) {
      context.handle(
        _tableNoMeta,
        tableNo.isAcceptableOrUnknown(data['table_no']!, _tableNoMeta),
      );
    }
    if (data.containsKey('process_request_json')) {
      context.handle(
        _processRequestJsonMeta,
        processRequestJson.isAcceptableOrUnknown(
          data['process_request_json']!,
          _processRequestJsonMeta,
        ),
      );
    }
    if (data.containsKey('latest_process_json')) {
      context.handle(
        _latestProcessJsonMeta,
        latestProcessJson.isAcceptableOrUnknown(
          data['latest_process_json']!,
          _latestProcessJsonMeta,
        ),
      );
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
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
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderStatusMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('ppn_percent')) {
      context.handle(
        _ppnPercentMeta,
        ppnPercent.isAcceptableOrUnknown(data['ppn_percent']!, _ppnPercentMeta),
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
    if (data.containsKey('pending_action')) {
      context.handle(
        _pendingActionMeta,
        pendingAction.isAcceptableOrUnknown(
          data['pending_action']!,
          _pendingActionMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('deleted_locally')) {
      context.handle(
        _deletedLocallyMeta,
        deletedLocally.isAcceptableOrUnknown(
          data['deleted_locally']!,
          _deletedLocallyMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {serverId};
  @override
  CachedProcessOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProcessOrder(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      bookingOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_code'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      tableNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no'],
      ),
      processRequestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process_request_json'],
      ),
      latestProcessJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_process_json'],
      ),
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      ppnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn_percent'],
      )!,
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      pendingAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_action'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      deletedLocally: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_locally'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $CachedProcessOrdersTable createAlias(String alias) {
    return $CachedProcessOrdersTable(attachedDatabase, alias);
  }
}

class CachedProcessOrder extends DataClass
    implements Insertable<CachedProcessOrder> {
  final int serverId;
  final String bookingOrderCode;
  final String customerName;
  final String? tableNo;
  final String? processRequestJson;
  final String? latestProcessJson;
  final String? detailJson;
  final String? paymentMethod;
  final String orderStatus;
  final double subtotal;
  final double ppnPercent;
  final bool isPpnActive;
  final String? pendingAction;
  final bool isSynced;
  final bool deletedLocally;
  final DateTime? syncedAt;
  const CachedProcessOrder({
    required this.serverId,
    required this.bookingOrderCode,
    required this.customerName,
    this.tableNo,
    this.processRequestJson,
    this.latestProcessJson,
    this.detailJson,
    this.paymentMethod,
    required this.orderStatus,
    required this.subtotal,
    required this.ppnPercent,
    required this.isPpnActive,
    this.pendingAction,
    required this.isSynced,
    required this.deletedLocally,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['booking_order_code'] = Variable<String>(bookingOrderCode);
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || tableNo != null) {
      map['table_no'] = Variable<String>(tableNo);
    }
    if (!nullToAbsent || processRequestJson != null) {
      map['process_request_json'] = Variable<String>(processRequestJson);
    }
    if (!nullToAbsent || latestProcessJson != null) {
      map['latest_process_json'] = Variable<String>(latestProcessJson);
    }
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['order_status'] = Variable<String>(orderStatus);
    map['subtotal'] = Variable<double>(subtotal);
    map['ppn_percent'] = Variable<double>(ppnPercent);
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    if (!nullToAbsent || pendingAction != null) {
      map['pending_action'] = Variable<String>(pendingAction);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['deleted_locally'] = Variable<bool>(deletedLocally);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  CachedProcessOrdersCompanion toCompanion(bool nullToAbsent) {
    return CachedProcessOrdersCompanion(
      serverId: Value(serverId),
      bookingOrderCode: Value(bookingOrderCode),
      customerName: Value(customerName),
      tableNo: tableNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNo),
      processRequestJson: processRequestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(processRequestJson),
      latestProcessJson: latestProcessJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestProcessJson),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      orderStatus: Value(orderStatus),
      subtotal: Value(subtotal),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      pendingAction: pendingAction == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingAction),
      isSynced: Value(isSynced),
      deletedLocally: Value(deletedLocally),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory CachedProcessOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProcessOrder(
      serverId: serializer.fromJson<int>(json['serverId']),
      bookingOrderCode: serializer.fromJson<String>(json['bookingOrderCode']),
      customerName: serializer.fromJson<String>(json['customerName']),
      tableNo: serializer.fromJson<String?>(json['tableNo']),
      processRequestJson: serializer.fromJson<String?>(
        json['processRequestJson'],
      ),
      latestProcessJson: serializer.fromJson<String?>(
        json['latestProcessJson'],
      ),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      ppnPercent: serializer.fromJson<double>(json['ppnPercent']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      pendingAction: serializer.fromJson<String?>(json['pendingAction']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      deletedLocally: serializer.fromJson<bool>(json['deletedLocally']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'bookingOrderCode': serializer.toJson<String>(bookingOrderCode),
      'customerName': serializer.toJson<String>(customerName),
      'tableNo': serializer.toJson<String?>(tableNo),
      'processRequestJson': serializer.toJson<String?>(processRequestJson),
      'latestProcessJson': serializer.toJson<String?>(latestProcessJson),
      'detailJson': serializer.toJson<String?>(detailJson),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'subtotal': serializer.toJson<double>(subtotal),
      'ppnPercent': serializer.toJson<double>(ppnPercent),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'pendingAction': serializer.toJson<String?>(pendingAction),
      'isSynced': serializer.toJson<bool>(isSynced),
      'deletedLocally': serializer.toJson<bool>(deletedLocally),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  CachedProcessOrder copyWith({
    int? serverId,
    String? bookingOrderCode,
    String? customerName,
    Value<String?> tableNo = const Value.absent(),
    Value<String?> processRequestJson = const Value.absent(),
    Value<String?> latestProcessJson = const Value.absent(),
    Value<String?> detailJson = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    String? orderStatus,
    double? subtotal,
    double? ppnPercent,
    bool? isPpnActive,
    Value<String?> pendingAction = const Value.absent(),
    bool? isSynced,
    bool? deletedLocally,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => CachedProcessOrder(
    serverId: serverId ?? this.serverId,
    bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
    customerName: customerName ?? this.customerName,
    tableNo: tableNo.present ? tableNo.value : this.tableNo,
    processRequestJson: processRequestJson.present
        ? processRequestJson.value
        : this.processRequestJson,
    latestProcessJson: latestProcessJson.present
        ? latestProcessJson.value
        : this.latestProcessJson,
    detailJson: detailJson.present ? detailJson.value : this.detailJson,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    orderStatus: orderStatus ?? this.orderStatus,
    subtotal: subtotal ?? this.subtotal,
    ppnPercent: ppnPercent ?? this.ppnPercent,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    pendingAction: pendingAction.present
        ? pendingAction.value
        : this.pendingAction,
    isSynced: isSynced ?? this.isSynced,
    deletedLocally: deletedLocally ?? this.deletedLocally,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  CachedProcessOrder copyWithCompanion(CachedProcessOrdersCompanion data) {
    return CachedProcessOrder(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderCode: data.bookingOrderCode.present
          ? data.bookingOrderCode.value
          : this.bookingOrderCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      tableNo: data.tableNo.present ? data.tableNo.value : this.tableNo,
      processRequestJson: data.processRequestJson.present
          ? data.processRequestJson.value
          : this.processRequestJson,
      latestProcessJson: data.latestProcessJson.present
          ? data.latestProcessJson.value
          : this.latestProcessJson,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      ppnPercent: data.ppnPercent.present
          ? data.ppnPercent.value
          : this.ppnPercent,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      pendingAction: data.pendingAction.present
          ? data.pendingAction.value
          : this.pendingAction,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      deletedLocally: data.deletedLocally.present
          ? data.deletedLocally.value
          : this.deletedLocally,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProcessOrder(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('processRequestJson: $processRequestJson, ')
          ..write('latestProcessJson: $latestProcessJson, ')
          ..write('detailJson: $detailJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('pendingAction: $pendingAction, ')
          ..write('isSynced: $isSynced, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    processRequestJson,
    latestProcessJson,
    detailJson,
    paymentMethod,
    orderStatus,
    subtotal,
    ppnPercent,
    isPpnActive,
    pendingAction,
    isSynced,
    deletedLocally,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProcessOrder &&
          other.serverId == this.serverId &&
          other.bookingOrderCode == this.bookingOrderCode &&
          other.customerName == this.customerName &&
          other.tableNo == this.tableNo &&
          other.processRequestJson == this.processRequestJson &&
          other.latestProcessJson == this.latestProcessJson &&
          other.detailJson == this.detailJson &&
          other.paymentMethod == this.paymentMethod &&
          other.orderStatus == this.orderStatus &&
          other.subtotal == this.subtotal &&
          other.ppnPercent == this.ppnPercent &&
          other.isPpnActive == this.isPpnActive &&
          other.pendingAction == this.pendingAction &&
          other.isSynced == this.isSynced &&
          other.deletedLocally == this.deletedLocally &&
          other.syncedAt == this.syncedAt);
}

class CachedProcessOrdersCompanion extends UpdateCompanion<CachedProcessOrder> {
  final Value<int> serverId;
  final Value<String> bookingOrderCode;
  final Value<String> customerName;
  final Value<String?> tableNo;
  final Value<String?> processRequestJson;
  final Value<String?> latestProcessJson;
  final Value<String?> detailJson;
  final Value<String?> paymentMethod;
  final Value<String> orderStatus;
  final Value<double> subtotal;
  final Value<double> ppnPercent;
  final Value<bool> isPpnActive;
  final Value<String?> pendingAction;
  final Value<bool> isSynced;
  final Value<bool> deletedLocally;
  final Value<DateTime?> syncedAt;
  const CachedProcessOrdersCompanion({
    this.serverId = const Value.absent(),
    this.bookingOrderCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.processRequestJson = const Value.absent(),
    this.latestProcessJson = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.pendingAction = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  CachedProcessOrdersCompanion.insert({
    this.serverId = const Value.absent(),
    required String bookingOrderCode,
    required String customerName,
    this.tableNo = const Value.absent(),
    this.processRequestJson = const Value.absent(),
    this.latestProcessJson = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required String orderStatus,
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.pendingAction = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : bookingOrderCode = Value(bookingOrderCode),
       customerName = Value(customerName),
       orderStatus = Value(orderStatus);
  static Insertable<CachedProcessOrder> custom({
    Expression<int>? serverId,
    Expression<String>? bookingOrderCode,
    Expression<String>? customerName,
    Expression<String>? tableNo,
    Expression<String>? processRequestJson,
    Expression<String>? latestProcessJson,
    Expression<String>? detailJson,
    Expression<String>? paymentMethod,
    Expression<String>? orderStatus,
    Expression<double>? subtotal,
    Expression<double>? ppnPercent,
    Expression<bool>? isPpnActive,
    Expression<String>? pendingAction,
    Expression<bool>? isSynced,
    Expression<bool>? deletedLocally,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderCode != null) 'booking_order_code': bookingOrderCode,
      if (customerName != null) 'customer_name': customerName,
      if (tableNo != null) 'table_no': tableNo,
      if (processRequestJson != null)
        'process_request_json': processRequestJson,
      if (latestProcessJson != null) 'latest_process_json': latestProcessJson,
      if (detailJson != null) 'detail_json': detailJson,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (orderStatus != null) 'order_status': orderStatus,
      if (subtotal != null) 'subtotal': subtotal,
      if (ppnPercent != null) 'ppn_percent': ppnPercent,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (pendingAction != null) 'pending_action': pendingAction,
      if (isSynced != null) 'is_synced': isSynced,
      if (deletedLocally != null) 'deleted_locally': deletedLocally,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  CachedProcessOrdersCompanion copyWith({
    Value<int>? serverId,
    Value<String>? bookingOrderCode,
    Value<String>? customerName,
    Value<String?>? tableNo,
    Value<String?>? processRequestJson,
    Value<String?>? latestProcessJson,
    Value<String?>? detailJson,
    Value<String?>? paymentMethod,
    Value<String>? orderStatus,
    Value<double>? subtotal,
    Value<double>? ppnPercent,
    Value<bool>? isPpnActive,
    Value<String?>? pendingAction,
    Value<bool>? isSynced,
    Value<bool>? deletedLocally,
    Value<DateTime?>? syncedAt,
  }) {
    return CachedProcessOrdersCompanion(
      serverId: serverId ?? this.serverId,
      bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
      customerName: customerName ?? this.customerName,
      tableNo: tableNo ?? this.tableNo,
      processRequestJson: processRequestJson ?? this.processRequestJson,
      latestProcessJson: latestProcessJson ?? this.latestProcessJson,
      detailJson: detailJson ?? this.detailJson,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderStatus: orderStatus ?? this.orderStatus,
      subtotal: subtotal ?? this.subtotal,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      pendingAction: pendingAction ?? this.pendingAction,
      isSynced: isSynced ?? this.isSynced,
      deletedLocally: deletedLocally ?? this.deletedLocally,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderCode.present) {
      map['booking_order_code'] = Variable<String>(bookingOrderCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (tableNo.present) {
      map['table_no'] = Variable<String>(tableNo.value);
    }
    if (processRequestJson.present) {
      map['process_request_json'] = Variable<String>(processRequestJson.value);
    }
    if (latestProcessJson.present) {
      map['latest_process_json'] = Variable<String>(latestProcessJson.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (ppnPercent.present) {
      map['ppn_percent'] = Variable<double>(ppnPercent.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (pendingAction.present) {
      map['pending_action'] = Variable<String>(pendingAction.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (deletedLocally.present) {
      map['deleted_locally'] = Variable<bool>(deletedLocally.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProcessOrdersCompanion(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('processRequestJson: $processRequestJson, ')
          ..write('latestProcessJson: $latestProcessJson, ')
          ..write('detailJson: $detailJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('pendingAction: $pendingAction, ')
          ..write('isSynced: $isSynced, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPaymentOrderItemsTable extends CachedPaymentOrderItems
    with TableInfo<$CachedPaymentOrderItemsTable, CachedPaymentOrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPaymentOrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverDetailIdMeta = const VerificationMeta(
    'serverDetailId',
  );
  @override
  late final GeneratedColumn<int> serverDetailId = GeneratedColumn<int>(
    'server_detail_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderServerIdMeta = const VerificationMeta(
    'orderServerId',
  );
  @override
  late final GeneratedColumn<int> orderServerId = GeneratedColumn<int>(
    'order_server_id',
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _promoAmountMeta = const VerificationMeta(
    'promoAmount',
  );
  @override
  late final GeneratedColumn<double> promoAmount = GeneratedColumn<double>(
    'promo_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  @override
  List<GeneratedColumn> get $columns => [
    serverDetailId,
    orderServerId,
    productServerId,
    productName,
    basePrice,
    promoAmount,
    qty,
    customerNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payment_order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPaymentOrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_detail_id')) {
      context.handle(
        _serverDetailIdMeta,
        serverDetailId.isAcceptableOrUnknown(
          data['server_detail_id']!,
          _serverDetailIdMeta,
        ),
      );
    }
    if (data.containsKey('order_server_id')) {
      context.handle(
        _orderServerIdMeta,
        orderServerId.isAcceptableOrUnknown(
          data['order_server_id']!,
          _orderServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderServerIdMeta);
    }
    if (data.containsKey('product_server_id')) {
      context.handle(
        _productServerIdMeta,
        productServerId.isAcceptableOrUnknown(
          data['product_server_id']!,
          _productServerIdMeta,
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
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
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
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverDetailId};
  @override
  CachedPaymentOrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPaymentOrderItem(
      serverDetailId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_detail_id'],
      )!,
      orderServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_server_id'],
      )!,
      productServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_server_id'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_price'],
      )!,
      promoAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}promo_amount'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      customerNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_note'],
      ),
    );
  }

  @override
  $CachedPaymentOrderItemsTable createAlias(String alias) {
    return $CachedPaymentOrderItemsTable(attachedDatabase, alias);
  }
}

class CachedPaymentOrderItem extends DataClass
    implements Insertable<CachedPaymentOrderItem> {
  final int serverDetailId;
  final int orderServerId;
  final int? productServerId;
  final String productName;
  final double basePrice;
  final double promoAmount;
  final int qty;
  final String? customerNote;
  const CachedPaymentOrderItem({
    required this.serverDetailId,
    required this.orderServerId,
    this.productServerId,
    required this.productName,
    required this.basePrice,
    required this.promoAmount,
    required this.qty,
    this.customerNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_detail_id'] = Variable<int>(serverDetailId);
    map['order_server_id'] = Variable<int>(orderServerId);
    if (!nullToAbsent || productServerId != null) {
      map['product_server_id'] = Variable<int>(productServerId);
    }
    map['product_name'] = Variable<String>(productName);
    map['base_price'] = Variable<double>(basePrice);
    map['promo_amount'] = Variable<double>(promoAmount);
    map['qty'] = Variable<int>(qty);
    if (!nullToAbsent || customerNote != null) {
      map['customer_note'] = Variable<String>(customerNote);
    }
    return map;
  }

  CachedPaymentOrderItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedPaymentOrderItemsCompanion(
      serverDetailId: Value(serverDetailId),
      orderServerId: Value(orderServerId),
      productServerId: productServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(productServerId),
      productName: Value(productName),
      basePrice: Value(basePrice),
      promoAmount: Value(promoAmount),
      qty: Value(qty),
      customerNote: customerNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customerNote),
    );
  }

  factory CachedPaymentOrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPaymentOrderItem(
      serverDetailId: serializer.fromJson<int>(json['serverDetailId']),
      orderServerId: serializer.fromJson<int>(json['orderServerId']),
      productServerId: serializer.fromJson<int?>(json['productServerId']),
      productName: serializer.fromJson<String>(json['productName']),
      basePrice: serializer.fromJson<double>(json['basePrice']),
      promoAmount: serializer.fromJson<double>(json['promoAmount']),
      qty: serializer.fromJson<int>(json['qty']),
      customerNote: serializer.fromJson<String?>(json['customerNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverDetailId': serializer.toJson<int>(serverDetailId),
      'orderServerId': serializer.toJson<int>(orderServerId),
      'productServerId': serializer.toJson<int?>(productServerId),
      'productName': serializer.toJson<String>(productName),
      'basePrice': serializer.toJson<double>(basePrice),
      'promoAmount': serializer.toJson<double>(promoAmount),
      'qty': serializer.toJson<int>(qty),
      'customerNote': serializer.toJson<String?>(customerNote),
    };
  }

  CachedPaymentOrderItem copyWith({
    int? serverDetailId,
    int? orderServerId,
    Value<int?> productServerId = const Value.absent(),
    String? productName,
    double? basePrice,
    double? promoAmount,
    int? qty,
    Value<String?> customerNote = const Value.absent(),
  }) => CachedPaymentOrderItem(
    serverDetailId: serverDetailId ?? this.serverDetailId,
    orderServerId: orderServerId ?? this.orderServerId,
    productServerId: productServerId.present
        ? productServerId.value
        : this.productServerId,
    productName: productName ?? this.productName,
    basePrice: basePrice ?? this.basePrice,
    promoAmount: promoAmount ?? this.promoAmount,
    qty: qty ?? this.qty,
    customerNote: customerNote.present ? customerNote.value : this.customerNote,
  );
  CachedPaymentOrderItem copyWithCompanion(
    CachedPaymentOrderItemsCompanion data,
  ) {
    return CachedPaymentOrderItem(
      serverDetailId: data.serverDetailId.present
          ? data.serverDetailId.value
          : this.serverDetailId,
      orderServerId: data.orderServerId.present
          ? data.orderServerId.value
          : this.orderServerId,
      productServerId: data.productServerId.present
          ? data.productServerId.value
          : this.productServerId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      promoAmount: data.promoAmount.present
          ? data.promoAmount.value
          : this.promoAmount,
      qty: data.qty.present ? data.qty.value : this.qty,
      customerNote: data.customerNote.present
          ? data.customerNote.value
          : this.customerNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrderItem(')
          ..write('serverDetailId: $serverDetailId, ')
          ..write('orderServerId: $orderServerId, ')
          ..write('productServerId: $productServerId, ')
          ..write('productName: $productName, ')
          ..write('basePrice: $basePrice, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('qty: $qty, ')
          ..write('customerNote: $customerNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverDetailId,
    orderServerId,
    productServerId,
    productName,
    basePrice,
    promoAmount,
    qty,
    customerNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPaymentOrderItem &&
          other.serverDetailId == this.serverDetailId &&
          other.orderServerId == this.orderServerId &&
          other.productServerId == this.productServerId &&
          other.productName == this.productName &&
          other.basePrice == this.basePrice &&
          other.promoAmount == this.promoAmount &&
          other.qty == this.qty &&
          other.customerNote == this.customerNote);
}

class CachedPaymentOrderItemsCompanion
    extends UpdateCompanion<CachedPaymentOrderItem> {
  final Value<int> serverDetailId;
  final Value<int> orderServerId;
  final Value<int?> productServerId;
  final Value<String> productName;
  final Value<double> basePrice;
  final Value<double> promoAmount;
  final Value<int> qty;
  final Value<String?> customerNote;
  const CachedPaymentOrderItemsCompanion({
    this.serverDetailId = const Value.absent(),
    this.orderServerId = const Value.absent(),
    this.productServerId = const Value.absent(),
    this.productName = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.qty = const Value.absent(),
    this.customerNote = const Value.absent(),
  });
  CachedPaymentOrderItemsCompanion.insert({
    this.serverDetailId = const Value.absent(),
    required int orderServerId,
    this.productServerId = const Value.absent(),
    required String productName,
    this.basePrice = const Value.absent(),
    this.promoAmount = const Value.absent(),
    this.qty = const Value.absent(),
    this.customerNote = const Value.absent(),
  }) : orderServerId = Value(orderServerId),
       productName = Value(productName);
  static Insertable<CachedPaymentOrderItem> custom({
    Expression<int>? serverDetailId,
    Expression<int>? orderServerId,
    Expression<int>? productServerId,
    Expression<String>? productName,
    Expression<double>? basePrice,
    Expression<double>? promoAmount,
    Expression<int>? qty,
    Expression<String>? customerNote,
  }) {
    return RawValuesInsertable({
      if (serverDetailId != null) 'server_detail_id': serverDetailId,
      if (orderServerId != null) 'order_server_id': orderServerId,
      if (productServerId != null) 'product_server_id': productServerId,
      if (productName != null) 'product_name': productName,
      if (basePrice != null) 'base_price': basePrice,
      if (promoAmount != null) 'promo_amount': promoAmount,
      if (qty != null) 'qty': qty,
      if (customerNote != null) 'customer_note': customerNote,
    });
  }

  CachedPaymentOrderItemsCompanion copyWith({
    Value<int>? serverDetailId,
    Value<int>? orderServerId,
    Value<int?>? productServerId,
    Value<String>? productName,
    Value<double>? basePrice,
    Value<double>? promoAmount,
    Value<int>? qty,
    Value<String?>? customerNote,
  }) {
    return CachedPaymentOrderItemsCompanion(
      serverDetailId: serverDetailId ?? this.serverDetailId,
      orderServerId: orderServerId ?? this.orderServerId,
      productServerId: productServerId ?? this.productServerId,
      productName: productName ?? this.productName,
      basePrice: basePrice ?? this.basePrice,
      promoAmount: promoAmount ?? this.promoAmount,
      qty: qty ?? this.qty,
      customerNote: customerNote ?? this.customerNote,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverDetailId.present) {
      map['server_detail_id'] = Variable<int>(serverDetailId.value);
    }
    if (orderServerId.present) {
      map['order_server_id'] = Variable<int>(orderServerId.value);
    }
    if (productServerId.present) {
      map['product_server_id'] = Variable<int>(productServerId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<double>(basePrice.value);
    }
    if (promoAmount.present) {
      map['promo_amount'] = Variable<double>(promoAmount.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (customerNote.present) {
      map['customer_note'] = Variable<String>(customerNote.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrderItemsCompanion(')
          ..write('serverDetailId: $serverDetailId, ')
          ..write('orderServerId: $orderServerId, ')
          ..write('productServerId: $productServerId, ')
          ..write('productName: $productName, ')
          ..write('basePrice: $basePrice, ')
          ..write('promoAmount: $promoAmount, ')
          ..write('qty: $qty, ')
          ..write('customerNote: $customerNote')
          ..write(')'))
        .toString();
  }
}

class $CachedPaymentOrderItemOptionsTable extends CachedPaymentOrderItemOptions
    with
        TableInfo<
          $CachedPaymentOrderItemOptionsTable,
          CachedPaymentOrderItemOption
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPaymentOrderItemOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverDetailOptionIdMeta =
      const VerificationMeta('serverDetailOptionId');
  @override
  late final GeneratedColumn<int> serverDetailOptionId = GeneratedColumn<int>(
    'server_detail_option_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderDetailServerIdMeta =
      const VerificationMeta('orderDetailServerId');
  @override
  late final GeneratedColumn<int> orderDetailServerId = GeneratedColumn<int>(
    'order_detail_server_id',
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
  static const VerificationMeta _optionNameMeta = const VerificationMeta(
    'optionName',
  );
  @override
  late final GeneratedColumn<String> optionName = GeneratedColumn<String>(
    'option_name',
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
  @override
  List<GeneratedColumn> get $columns => [
    serverDetailOptionId,
    orderDetailServerId,
    parentName,
    optionName,
    price,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payment_order_item_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPaymentOrderItemOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_detail_option_id')) {
      context.handle(
        _serverDetailOptionIdMeta,
        serverDetailOptionId.isAcceptableOrUnknown(
          data['server_detail_option_id']!,
          _serverDetailOptionIdMeta,
        ),
      );
    }
    if (data.containsKey('order_detail_server_id')) {
      context.handle(
        _orderDetailServerIdMeta,
        orderDetailServerId.isAcceptableOrUnknown(
          data['order_detail_server_id']!,
          _orderDetailServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderDetailServerIdMeta);
    }
    if (data.containsKey('parent_name')) {
      context.handle(
        _parentNameMeta,
        parentName.isAcceptableOrUnknown(data['parent_name']!, _parentNameMeta),
      );
    }
    if (data.containsKey('option_name')) {
      context.handle(
        _optionNameMeta,
        optionName.isAcceptableOrUnknown(data['option_name']!, _optionNameMeta),
      );
    } else if (isInserting) {
      context.missing(_optionNameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverDetailOptionId};
  @override
  CachedPaymentOrderItemOption map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPaymentOrderItemOption(
      serverDetailOptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_detail_option_id'],
      )!,
      orderDetailServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_detail_server_id'],
      )!,
      parentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_name'],
      ),
      optionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
    );
  }

  @override
  $CachedPaymentOrderItemOptionsTable createAlias(String alias) {
    return $CachedPaymentOrderItemOptionsTable(attachedDatabase, alias);
  }
}

class CachedPaymentOrderItemOption extends DataClass
    implements Insertable<CachedPaymentOrderItemOption> {
  final int serverDetailOptionId;
  final int orderDetailServerId;
  final String? parentName;
  final String optionName;
  final double price;
  const CachedPaymentOrderItemOption({
    required this.serverDetailOptionId,
    required this.orderDetailServerId,
    this.parentName,
    required this.optionName,
    required this.price,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_detail_option_id'] = Variable<int>(serverDetailOptionId);
    map['order_detail_server_id'] = Variable<int>(orderDetailServerId);
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    map['option_name'] = Variable<String>(optionName);
    map['price'] = Variable<double>(price);
    return map;
  }

  CachedPaymentOrderItemOptionsCompanion toCompanion(bool nullToAbsent) {
    return CachedPaymentOrderItemOptionsCompanion(
      serverDetailOptionId: Value(serverDetailOptionId),
      orderDetailServerId: Value(orderDetailServerId),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      optionName: Value(optionName),
      price: Value(price),
    );
  }

  factory CachedPaymentOrderItemOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPaymentOrderItemOption(
      serverDetailOptionId: serializer.fromJson<int>(
        json['serverDetailOptionId'],
      ),
      orderDetailServerId: serializer.fromJson<int>(
        json['orderDetailServerId'],
      ),
      parentName: serializer.fromJson<String?>(json['parentName']),
      optionName: serializer.fromJson<String>(json['optionName']),
      price: serializer.fromJson<double>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverDetailOptionId': serializer.toJson<int>(serverDetailOptionId),
      'orderDetailServerId': serializer.toJson<int>(orderDetailServerId),
      'parentName': serializer.toJson<String?>(parentName),
      'optionName': serializer.toJson<String>(optionName),
      'price': serializer.toJson<double>(price),
    };
  }

  CachedPaymentOrderItemOption copyWith({
    int? serverDetailOptionId,
    int? orderDetailServerId,
    Value<String?> parentName = const Value.absent(),
    String? optionName,
    double? price,
  }) => CachedPaymentOrderItemOption(
    serverDetailOptionId: serverDetailOptionId ?? this.serverDetailOptionId,
    orderDetailServerId: orderDetailServerId ?? this.orderDetailServerId,
    parentName: parentName.present ? parentName.value : this.parentName,
    optionName: optionName ?? this.optionName,
    price: price ?? this.price,
  );
  CachedPaymentOrderItemOption copyWithCompanion(
    CachedPaymentOrderItemOptionsCompanion data,
  ) {
    return CachedPaymentOrderItemOption(
      serverDetailOptionId: data.serverDetailOptionId.present
          ? data.serverDetailOptionId.value
          : this.serverDetailOptionId,
      orderDetailServerId: data.orderDetailServerId.present
          ? data.orderDetailServerId.value
          : this.orderDetailServerId,
      parentName: data.parentName.present
          ? data.parentName.value
          : this.parentName,
      optionName: data.optionName.present
          ? data.optionName.value
          : this.optionName,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrderItemOption(')
          ..write('serverDetailOptionId: $serverDetailOptionId, ')
          ..write('orderDetailServerId: $orderDetailServerId, ')
          ..write('parentName: $parentName, ')
          ..write('optionName: $optionName, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverDetailOptionId,
    orderDetailServerId,
    parentName,
    optionName,
    price,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPaymentOrderItemOption &&
          other.serverDetailOptionId == this.serverDetailOptionId &&
          other.orderDetailServerId == this.orderDetailServerId &&
          other.parentName == this.parentName &&
          other.optionName == this.optionName &&
          other.price == this.price);
}

class CachedPaymentOrderItemOptionsCompanion
    extends UpdateCompanion<CachedPaymentOrderItemOption> {
  final Value<int> serverDetailOptionId;
  final Value<int> orderDetailServerId;
  final Value<String?> parentName;
  final Value<String> optionName;
  final Value<double> price;
  const CachedPaymentOrderItemOptionsCompanion({
    this.serverDetailOptionId = const Value.absent(),
    this.orderDetailServerId = const Value.absent(),
    this.parentName = const Value.absent(),
    this.optionName = const Value.absent(),
    this.price = const Value.absent(),
  });
  CachedPaymentOrderItemOptionsCompanion.insert({
    this.serverDetailOptionId = const Value.absent(),
    required int orderDetailServerId,
    this.parentName = const Value.absent(),
    required String optionName,
    this.price = const Value.absent(),
  }) : orderDetailServerId = Value(orderDetailServerId),
       optionName = Value(optionName);
  static Insertable<CachedPaymentOrderItemOption> custom({
    Expression<int>? serverDetailOptionId,
    Expression<int>? orderDetailServerId,
    Expression<String>? parentName,
    Expression<String>? optionName,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (serverDetailOptionId != null)
        'server_detail_option_id': serverDetailOptionId,
      if (orderDetailServerId != null)
        'order_detail_server_id': orderDetailServerId,
      if (parentName != null) 'parent_name': parentName,
      if (optionName != null) 'option_name': optionName,
      if (price != null) 'price': price,
    });
  }

  CachedPaymentOrderItemOptionsCompanion copyWith({
    Value<int>? serverDetailOptionId,
    Value<int>? orderDetailServerId,
    Value<String?>? parentName,
    Value<String>? optionName,
    Value<double>? price,
  }) {
    return CachedPaymentOrderItemOptionsCompanion(
      serverDetailOptionId: serverDetailOptionId ?? this.serverDetailOptionId,
      orderDetailServerId: orderDetailServerId ?? this.orderDetailServerId,
      parentName: parentName ?? this.parentName,
      optionName: optionName ?? this.optionName,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverDetailOptionId.present) {
      map['server_detail_option_id'] = Variable<int>(
        serverDetailOptionId.value,
      );
    }
    if (orderDetailServerId.present) {
      map['order_detail_server_id'] = Variable<int>(orderDetailServerId.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (optionName.present) {
      map['option_name'] = Variable<String>(optionName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPaymentOrderItemOptionsCompanion(')
          ..write('serverDetailOptionId: $serverDetailOptionId, ')
          ..write('orderDetailServerId: $orderDetailServerId, ')
          ..write('parentName: $parentName, ')
          ..write('optionName: $optionName, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

class $CachedDoneOrdersTable extends CachedDoneOrders
    with TableInfo<$CachedDoneOrdersTable, CachedDoneOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDoneOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _doneRequestJsonMeta = const VerificationMeta(
    'doneRequestJson',
  );
  @override
  late final GeneratedColumn<String> doneRequestJson = GeneratedColumn<String>(
    'done_request_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestDoneJsonMeta = const VerificationMeta(
    'latestDoneJson',
  );
  @override
  late final GeneratedColumn<String> latestDoneJson = GeneratedColumn<String>(
    'latest_done_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ppnPercentMeta = const VerificationMeta(
    'ppnPercent',
  );
  @override
  late final GeneratedColumn<double> ppnPercent = GeneratedColumn<double>(
    'ppn_percent',
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedLocallyMeta = const VerificationMeta(
    'deletedLocally',
  );
  @override
  late final GeneratedColumn<bool> deletedLocally = GeneratedColumn<bool>(
    'deleted_locally',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_locally" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    doneRequestJson,
    latestDoneJson,
    paymentMethod,
    orderStatus,
    detailJson,
    subtotal,
    ppnPercent,
    isPpnActive,
    isSynced,
    deletedLocally,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_done_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDoneOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_bookingOrderCodeMeta);
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
    if (data.containsKey('table_no')) {
      context.handle(
        _tableNoMeta,
        tableNo.isAcceptableOrUnknown(data['table_no']!, _tableNoMeta),
      );
    }
    if (data.containsKey('done_request_json')) {
      context.handle(
        _doneRequestJsonMeta,
        doneRequestJson.isAcceptableOrUnknown(
          data['done_request_json']!,
          _doneRequestJsonMeta,
        ),
      );
    }
    if (data.containsKey('latest_done_json')) {
      context.handle(
        _latestDoneJsonMeta,
        latestDoneJson.isAcceptableOrUnknown(
          data['latest_done_json']!,
          _latestDoneJsonMeta,
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
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderStatusMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('ppn_percent')) {
      context.handle(
        _ppnPercentMeta,
        ppnPercent.isAcceptableOrUnknown(data['ppn_percent']!, _ppnPercentMeta),
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
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('deleted_locally')) {
      context.handle(
        _deletedLocallyMeta,
        deletedLocally.isAcceptableOrUnknown(
          data['deleted_locally']!,
          _deletedLocallyMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {serverId};
  @override
  CachedDoneOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDoneOrder(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      bookingOrderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_order_code'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      tableNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_no'],
      ),
      doneRequestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done_request_json'],
      ),
      latestDoneJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_done_json'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      ppnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ppn_percent'],
      )!,
      isPpnActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ppn_active'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      deletedLocally: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_locally'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $CachedDoneOrdersTable createAlias(String alias) {
    return $CachedDoneOrdersTable(attachedDatabase, alias);
  }
}

class CachedDoneOrder extends DataClass implements Insertable<CachedDoneOrder> {
  final int serverId;
  final String bookingOrderCode;
  final String customerName;
  final String? tableNo;
  final String? doneRequestJson;
  final String? latestDoneJson;
  final String? paymentMethod;
  final String orderStatus;
  final String? detailJson;
  final double subtotal;
  final double ppnPercent;
  final bool isPpnActive;
  final bool isSynced;
  final bool deletedLocally;
  final DateTime? syncedAt;
  const CachedDoneOrder({
    required this.serverId,
    required this.bookingOrderCode,
    required this.customerName,
    this.tableNo,
    this.doneRequestJson,
    this.latestDoneJson,
    this.paymentMethod,
    required this.orderStatus,
    this.detailJson,
    required this.subtotal,
    required this.ppnPercent,
    required this.isPpnActive,
    required this.isSynced,
    required this.deletedLocally,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['booking_order_code'] = Variable<String>(bookingOrderCode);
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || tableNo != null) {
      map['table_no'] = Variable<String>(tableNo);
    }
    if (!nullToAbsent || doneRequestJson != null) {
      map['done_request_json'] = Variable<String>(doneRequestJson);
    }
    if (!nullToAbsent || latestDoneJson != null) {
      map['latest_done_json'] = Variable<String>(latestDoneJson);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['order_status'] = Variable<String>(orderStatus);
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['ppn_percent'] = Variable<double>(ppnPercent);
    map['is_ppn_active'] = Variable<bool>(isPpnActive);
    map['is_synced'] = Variable<bool>(isSynced);
    map['deleted_locally'] = Variable<bool>(deletedLocally);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  CachedDoneOrdersCompanion toCompanion(bool nullToAbsent) {
    return CachedDoneOrdersCompanion(
      serverId: Value(serverId),
      bookingOrderCode: Value(bookingOrderCode),
      customerName: Value(customerName),
      tableNo: tableNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNo),
      doneRequestJson: doneRequestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(doneRequestJson),
      latestDoneJson: latestDoneJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestDoneJson),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      orderStatus: Value(orderStatus),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
      subtotal: Value(subtotal),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      isSynced: Value(isSynced),
      deletedLocally: Value(deletedLocally),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory CachedDoneOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDoneOrder(
      serverId: serializer.fromJson<int>(json['serverId']),
      bookingOrderCode: serializer.fromJson<String>(json['bookingOrderCode']),
      customerName: serializer.fromJson<String>(json['customerName']),
      tableNo: serializer.fromJson<String?>(json['tableNo']),
      doneRequestJson: serializer.fromJson<String?>(json['doneRequestJson']),
      latestDoneJson: serializer.fromJson<String?>(json['latestDoneJson']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      ppnPercent: serializer.fromJson<double>(json['ppnPercent']),
      isPpnActive: serializer.fromJson<bool>(json['isPpnActive']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      deletedLocally: serializer.fromJson<bool>(json['deletedLocally']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'bookingOrderCode': serializer.toJson<String>(bookingOrderCode),
      'customerName': serializer.toJson<String>(customerName),
      'tableNo': serializer.toJson<String?>(tableNo),
      'doneRequestJson': serializer.toJson<String?>(doneRequestJson),
      'latestDoneJson': serializer.toJson<String?>(latestDoneJson),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'detailJson': serializer.toJson<String?>(detailJson),
      'subtotal': serializer.toJson<double>(subtotal),
      'ppnPercent': serializer.toJson<double>(ppnPercent),
      'isPpnActive': serializer.toJson<bool>(isPpnActive),
      'isSynced': serializer.toJson<bool>(isSynced),
      'deletedLocally': serializer.toJson<bool>(deletedLocally),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  CachedDoneOrder copyWith({
    int? serverId,
    String? bookingOrderCode,
    String? customerName,
    Value<String?> tableNo = const Value.absent(),
    Value<String?> doneRequestJson = const Value.absent(),
    Value<String?> latestDoneJson = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    String? orderStatus,
    Value<String?> detailJson = const Value.absent(),
    double? subtotal,
    double? ppnPercent,
    bool? isPpnActive,
    bool? isSynced,
    bool? deletedLocally,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => CachedDoneOrder(
    serverId: serverId ?? this.serverId,
    bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
    customerName: customerName ?? this.customerName,
    tableNo: tableNo.present ? tableNo.value : this.tableNo,
    doneRequestJson: doneRequestJson.present
        ? doneRequestJson.value
        : this.doneRequestJson,
    latestDoneJson: latestDoneJson.present
        ? latestDoneJson.value
        : this.latestDoneJson,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    orderStatus: orderStatus ?? this.orderStatus,
    detailJson: detailJson.present ? detailJson.value : this.detailJson,
    subtotal: subtotal ?? this.subtotal,
    ppnPercent: ppnPercent ?? this.ppnPercent,
    isPpnActive: isPpnActive ?? this.isPpnActive,
    isSynced: isSynced ?? this.isSynced,
    deletedLocally: deletedLocally ?? this.deletedLocally,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  CachedDoneOrder copyWithCompanion(CachedDoneOrdersCompanion data) {
    return CachedDoneOrder(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      bookingOrderCode: data.bookingOrderCode.present
          ? data.bookingOrderCode.value
          : this.bookingOrderCode,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      tableNo: data.tableNo.present ? data.tableNo.value : this.tableNo,
      doneRequestJson: data.doneRequestJson.present
          ? data.doneRequestJson.value
          : this.doneRequestJson,
      latestDoneJson: data.latestDoneJson.present
          ? data.latestDoneJson.value
          : this.latestDoneJson,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      ppnPercent: data.ppnPercent.present
          ? data.ppnPercent.value
          : this.ppnPercent,
      isPpnActive: data.isPpnActive.present
          ? data.isPpnActive.value
          : this.isPpnActive,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      deletedLocally: data.deletedLocally.present
          ? data.deletedLocally.value
          : this.deletedLocally,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDoneOrder(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('doneRequestJson: $doneRequestJson, ')
          ..write('latestDoneJson: $latestDoneJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('detailJson: $detailJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverId,
    bookingOrderCode,
    customerName,
    tableNo,
    doneRequestJson,
    latestDoneJson,
    paymentMethod,
    orderStatus,
    detailJson,
    subtotal,
    ppnPercent,
    isPpnActive,
    isSynced,
    deletedLocally,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDoneOrder &&
          other.serverId == this.serverId &&
          other.bookingOrderCode == this.bookingOrderCode &&
          other.customerName == this.customerName &&
          other.tableNo == this.tableNo &&
          other.doneRequestJson == this.doneRequestJson &&
          other.latestDoneJson == this.latestDoneJson &&
          other.paymentMethod == this.paymentMethod &&
          other.orderStatus == this.orderStatus &&
          other.detailJson == this.detailJson &&
          other.subtotal == this.subtotal &&
          other.ppnPercent == this.ppnPercent &&
          other.isPpnActive == this.isPpnActive &&
          other.isSynced == this.isSynced &&
          other.deletedLocally == this.deletedLocally &&
          other.syncedAt == this.syncedAt);
}

class CachedDoneOrdersCompanion extends UpdateCompanion<CachedDoneOrder> {
  final Value<int> serverId;
  final Value<String> bookingOrderCode;
  final Value<String> customerName;
  final Value<String?> tableNo;
  final Value<String?> doneRequestJson;
  final Value<String?> latestDoneJson;
  final Value<String?> paymentMethod;
  final Value<String> orderStatus;
  final Value<String?> detailJson;
  final Value<double> subtotal;
  final Value<double> ppnPercent;
  final Value<bool> isPpnActive;
  final Value<bool> isSynced;
  final Value<bool> deletedLocally;
  final Value<DateTime?> syncedAt;
  const CachedDoneOrdersCompanion({
    this.serverId = const Value.absent(),
    this.bookingOrderCode = const Value.absent(),
    this.customerName = const Value.absent(),
    this.tableNo = const Value.absent(),
    this.doneRequestJson = const Value.absent(),
    this.latestDoneJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  CachedDoneOrdersCompanion.insert({
    this.serverId = const Value.absent(),
    required String bookingOrderCode,
    required String customerName,
    this.tableNo = const Value.absent(),
    this.doneRequestJson = const Value.absent(),
    this.latestDoneJson = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required String orderStatus,
    this.detailJson = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.ppnPercent = const Value.absent(),
    this.isPpnActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : bookingOrderCode = Value(bookingOrderCode),
       customerName = Value(customerName),
       orderStatus = Value(orderStatus);
  static Insertable<CachedDoneOrder> custom({
    Expression<int>? serverId,
    Expression<String>? bookingOrderCode,
    Expression<String>? customerName,
    Expression<String>? tableNo,
    Expression<String>? doneRequestJson,
    Expression<String>? latestDoneJson,
    Expression<String>? paymentMethod,
    Expression<String>? orderStatus,
    Expression<String>? detailJson,
    Expression<double>? subtotal,
    Expression<double>? ppnPercent,
    Expression<bool>? isPpnActive,
    Expression<bool>? isSynced,
    Expression<bool>? deletedLocally,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (bookingOrderCode != null) 'booking_order_code': bookingOrderCode,
      if (customerName != null) 'customer_name': customerName,
      if (tableNo != null) 'table_no': tableNo,
      if (doneRequestJson != null) 'done_request_json': doneRequestJson,
      if (latestDoneJson != null) 'latest_done_json': latestDoneJson,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (orderStatus != null) 'order_status': orderStatus,
      if (detailJson != null) 'detail_json': detailJson,
      if (subtotal != null) 'subtotal': subtotal,
      if (ppnPercent != null) 'ppn_percent': ppnPercent,
      if (isPpnActive != null) 'is_ppn_active': isPpnActive,
      if (isSynced != null) 'is_synced': isSynced,
      if (deletedLocally != null) 'deleted_locally': deletedLocally,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  CachedDoneOrdersCompanion copyWith({
    Value<int>? serverId,
    Value<String>? bookingOrderCode,
    Value<String>? customerName,
    Value<String?>? tableNo,
    Value<String?>? doneRequestJson,
    Value<String?>? latestDoneJson,
    Value<String?>? paymentMethod,
    Value<String>? orderStatus,
    Value<String?>? detailJson,
    Value<double>? subtotal,
    Value<double>? ppnPercent,
    Value<bool>? isPpnActive,
    Value<bool>? isSynced,
    Value<bool>? deletedLocally,
    Value<DateTime?>? syncedAt,
  }) {
    return CachedDoneOrdersCompanion(
      serverId: serverId ?? this.serverId,
      bookingOrderCode: bookingOrderCode ?? this.bookingOrderCode,
      customerName: customerName ?? this.customerName,
      tableNo: tableNo ?? this.tableNo,
      doneRequestJson: doneRequestJson ?? this.doneRequestJson,
      latestDoneJson: latestDoneJson ?? this.latestDoneJson,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderStatus: orderStatus ?? this.orderStatus,
      detailJson: detailJson ?? this.detailJson,
      subtotal: subtotal ?? this.subtotal,
      ppnPercent: ppnPercent ?? this.ppnPercent,
      isPpnActive: isPpnActive ?? this.isPpnActive,
      isSynced: isSynced ?? this.isSynced,
      deletedLocally: deletedLocally ?? this.deletedLocally,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (bookingOrderCode.present) {
      map['booking_order_code'] = Variable<String>(bookingOrderCode.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (tableNo.present) {
      map['table_no'] = Variable<String>(tableNo.value);
    }
    if (doneRequestJson.present) {
      map['done_request_json'] = Variable<String>(doneRequestJson.value);
    }
    if (latestDoneJson.present) {
      map['latest_done_json'] = Variable<String>(latestDoneJson.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (ppnPercent.present) {
      map['ppn_percent'] = Variable<double>(ppnPercent.value);
    }
    if (isPpnActive.present) {
      map['is_ppn_active'] = Variable<bool>(isPpnActive.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (deletedLocally.present) {
      map['deleted_locally'] = Variable<bool>(deletedLocally.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDoneOrdersCompanion(')
          ..write('serverId: $serverId, ')
          ..write('bookingOrderCode: $bookingOrderCode, ')
          ..write('customerName: $customerName, ')
          ..write('tableNo: $tableNo, ')
          ..write('doneRequestJson: $doneRequestJson, ')
          ..write('latestDoneJson: $latestDoneJson, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('detailJson: $detailJson, ')
          ..write('subtotal: $subtotal, ')
          ..write('ppnPercent: $ppnPercent, ')
          ..write('isPpnActive: $isPpnActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('syncedAt: $syncedAt')
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
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $LocalOrderItemsTable localOrderItems = $LocalOrderItemsTable(
    this,
  );
  late final $LocalOrderItemOptionsTable localOrderItemOptions =
      $LocalOrderItemOptionsTable(this);
  late final $LocalPaymentsTable localPayments = $LocalPaymentsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CachedPaymentOrdersTable cachedPaymentOrders =
      $CachedPaymentOrdersTable(this);
  late final $CachedProcessOrdersTable cachedProcessOrders =
      $CachedProcessOrdersTable(this);
  late final $CachedPaymentOrderItemsTable cachedPaymentOrderItems =
      $CachedPaymentOrderItemsTable(this);
  late final $CachedPaymentOrderItemOptionsTable cachedPaymentOrderItemOptions =
      $CachedPaymentOrderItemOptionsTable(this);
  late final $CachedDoneOrdersTable cachedDoneOrders = $CachedDoneOrdersTable(
    this,
  );
  late final CachedProcessOrdersDao cachedProcessOrdersDao =
      CachedProcessOrdersDao(this as CashierDb);
  late final CachedDoneOrdersDao cachedDoneOrdersDao = CachedDoneOrdersDao(
    this as CashierDb,
  );
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
    localOrders,
    localOrderItems,
    localOrderItemOptions,
    localPayments,
    syncQueue,
    cachedPaymentOrders,
    cachedProcessOrders,
    cachedPaymentOrderItems,
    cachedPaymentOrderItemOptions,
    cachedDoneOrders,
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
typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String localId,
      Value<int?> serverId,
      required String clientOrderCode,
      Value<String?> serverOrderCode,
      Value<int?> partnerId,
      Value<String?> partnerName,
      Value<int?> tableServerId,
      Value<String?> tableNoSnapshot,
      required String customerName,
      Value<String?> paymentMethodSelected,
      Value<String?> paymentMethodEffective,
      Value<double> subtotal,
      Value<double> discountValue,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<double> grandTotal,
      Value<double?> paidAmountLocal,
      Value<double?> changeAmountLocal,
      Value<String?> cashierProofImageLocalPath,
      Value<DateTime?> paymentConfirmedAtLocal,
      Value<int?> latestPaymentServerId,
      Value<String?> orderSnapshotJson,
      Value<String> orderStatusLocal,
      Value<String> syncStatus,
      Value<String?> lastError,
      Value<int?> manualPaymentServerId,
      Value<String?> manualPaymentType,
      Value<String?> manualProviderName,
      Value<String?> manualProviderAccountName,
      Value<String?> manualProviderAccountNo,
      Value<String?> manualQrisImageUrl,
      Value<String?> manualQrisImageLocalPath,
      Value<String?> manualPaymentLabel,
      Value<String?> manualPaymentRawJson,
      Value<String> backendSyncStage,
      required DateTime createdAtLocal,
      required DateTime updatedAtLocal,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> localId,
      Value<int?> serverId,
      Value<String> clientOrderCode,
      Value<String?> serverOrderCode,
      Value<int?> partnerId,
      Value<String?> partnerName,
      Value<int?> tableServerId,
      Value<String?> tableNoSnapshot,
      Value<String> customerName,
      Value<String?> paymentMethodSelected,
      Value<String?> paymentMethodEffective,
      Value<double> subtotal,
      Value<double> discountValue,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<double> grandTotal,
      Value<double?> paidAmountLocal,
      Value<double?> changeAmountLocal,
      Value<String?> cashierProofImageLocalPath,
      Value<DateTime?> paymentConfirmedAtLocal,
      Value<int?> latestPaymentServerId,
      Value<String?> orderSnapshotJson,
      Value<String> orderStatusLocal,
      Value<String> syncStatus,
      Value<String?> lastError,
      Value<int?> manualPaymentServerId,
      Value<String?> manualPaymentType,
      Value<String?> manualProviderName,
      Value<String?> manualProviderAccountName,
      Value<String?> manualProviderAccountNo,
      Value<String?> manualQrisImageUrl,
      Value<String?> manualQrisImageLocalPath,
      Value<String?> manualPaymentLabel,
      Value<String?> manualPaymentRawJson,
      Value<String> backendSyncStage,
      Value<DateTime> createdAtLocal,
      Value<DateTime> updatedAtLocal,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$LocalOrdersTableFilterComposer
    extends Composer<_$CashierDb, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOrderCode => $composableBuilder(
    column: $table.clientOrderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverOrderCode => $composableBuilder(
    column: $table.serverOrderCode,
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

  ColumnFilters<int> get tableServerId => $composableBuilder(
    column: $table.tableServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNoSnapshot => $composableBuilder(
    column: $table.tableNoSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethodSelected => $composableBuilder(
    column: $table.paymentMethodSelected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethodEffective => $composableBuilder(
    column: $table.paymentMethodEffective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
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

  ColumnFilters<String> get cashierProofImageLocalPath => $composableBuilder(
    column: $table.cashierProofImageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentConfirmedAtLocal => $composableBuilder(
    column: $table.paymentConfirmedAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderSnapshotJson => $composableBuilder(
    column: $table.orderSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatusLocal => $composableBuilder(
    column: $table.orderStatusLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualPaymentType => $composableBuilder(
    column: $table.manualPaymentType,
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

  ColumnFilters<String> get manualQrisImageUrl => $composableBuilder(
    column: $table.manualQrisImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualQrisImageLocalPath => $composableBuilder(
    column: $table.manualQrisImageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualPaymentLabel => $composableBuilder(
    column: $table.manualPaymentLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualPaymentRawJson => $composableBuilder(
    column: $table.manualPaymentRawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendSyncStage => $composableBuilder(
    column: $table.backendSyncStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrdersTableOrderingComposer
    extends Composer<_$CashierDb, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOrderCode => $composableBuilder(
    column: $table.clientOrderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverOrderCode => $composableBuilder(
    column: $table.serverOrderCode,
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

  ColumnOrderings<int> get tableServerId => $composableBuilder(
    column: $table.tableServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNoSnapshot => $composableBuilder(
    column: $table.tableNoSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethodSelected => $composableBuilder(
    column: $table.paymentMethodSelected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethodEffective => $composableBuilder(
    column: $table.paymentMethodEffective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
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

  ColumnOrderings<String> get cashierProofImageLocalPath => $composableBuilder(
    column: $table.cashierProofImageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentConfirmedAtLocal => $composableBuilder(
    column: $table.paymentConfirmedAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderSnapshotJson => $composableBuilder(
    column: $table.orderSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatusLocal => $composableBuilder(
    column: $table.orderStatusLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualPaymentType => $composableBuilder(
    column: $table.manualPaymentType,
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

  ColumnOrderings<String> get manualQrisImageUrl => $composableBuilder(
    column: $table.manualQrisImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualQrisImageLocalPath => $composableBuilder(
    column: $table.manualQrisImageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualPaymentLabel => $composableBuilder(
    column: $table.manualPaymentLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualPaymentRawJson => $composableBuilder(
    column: $table.manualPaymentRawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendSyncStage => $composableBuilder(
    column: $table.backendSyncStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdersTableAnnotationComposer
    extends Composer<_$CashierDb, $LocalOrdersTable> {
  $$LocalOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get clientOrderCode => $composableBuilder(
    column: $table.clientOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverOrderCode => $composableBuilder(
    column: $table.serverOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partnerId =>
      $composableBuilder(column: $table.partnerId, builder: (column) => column);

  GeneratedColumn<String> get partnerName => $composableBuilder(
    column: $table.partnerName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tableServerId => $composableBuilder(
    column: $table.tableServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableNoSnapshot => $composableBuilder(
    column: $table.tableNoSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethodSelected => $composableBuilder(
    column: $table.paymentMethodSelected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethodEffective => $composableBuilder(
    column: $table.paymentMethodEffective,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
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

  GeneratedColumn<String> get cashierProofImageLocalPath => $composableBuilder(
    column: $table.cashierProofImageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paymentConfirmedAtLocal => $composableBuilder(
    column: $table.paymentConfirmedAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestPaymentServerId => $composableBuilder(
    column: $table.latestPaymentServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderSnapshotJson => $composableBuilder(
    column: $table.orderSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatusLocal => $composableBuilder(
    column: $table.orderStatusLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualPaymentType => $composableBuilder(
    column: $table.manualPaymentType,
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

  GeneratedColumn<String> get manualQrisImageUrl => $composableBuilder(
    column: $table.manualQrisImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualQrisImageLocalPath => $composableBuilder(
    column: $table.manualQrisImageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualPaymentLabel => $composableBuilder(
    column: $table.manualPaymentLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manualPaymentRawJson => $composableBuilder(
    column: $table.manualPaymentRawJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendSyncStage => $composableBuilder(
    column: $table.backendSyncStage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalOrdersTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $LocalOrdersTable,
          LocalOrder,
          $$LocalOrdersTableFilterComposer,
          $$LocalOrdersTableOrderingComposer,
          $$LocalOrdersTableAnnotationComposer,
          $$LocalOrdersTableCreateCompanionBuilder,
          $$LocalOrdersTableUpdateCompanionBuilder,
          (
            LocalOrder,
            BaseReferences<_$CashierDb, $LocalOrdersTable, LocalOrder>,
          ),
          LocalOrder,
          PrefetchHooks Function()
        > {
  $$LocalOrdersTableTableManager(_$CashierDb db, $LocalOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> clientOrderCode = const Value.absent(),
                Value<String?> serverOrderCode = const Value.absent(),
                Value<int?> partnerId = const Value.absent(),
                Value<String?> partnerName = const Value.absent(),
                Value<int?> tableServerId = const Value.absent(),
                Value<String?> tableNoSnapshot = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> paymentMethodSelected = const Value.absent(),
                Value<String?> paymentMethodEffective = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double?> paidAmountLocal = const Value.absent(),
                Value<double?> changeAmountLocal = const Value.absent(),
                Value<String?> cashierProofImageLocalPath =
                    const Value.absent(),
                Value<DateTime?> paymentConfirmedAtLocal = const Value.absent(),
                Value<int?> latestPaymentServerId = const Value.absent(),
                Value<String?> orderSnapshotJson = const Value.absent(),
                Value<String> orderStatusLocal = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> manualPaymentServerId = const Value.absent(),
                Value<String?> manualPaymentType = const Value.absent(),
                Value<String?> manualProviderName = const Value.absent(),
                Value<String?> manualProviderAccountName = const Value.absent(),
                Value<String?> manualProviderAccountNo = const Value.absent(),
                Value<String?> manualQrisImageUrl = const Value.absent(),
                Value<String?> manualQrisImageLocalPath = const Value.absent(),
                Value<String?> manualPaymentLabel = const Value.absent(),
                Value<String?> manualPaymentRawJson = const Value.absent(),
                Value<String> backendSyncStage = const Value.absent(),
                Value<DateTime> createdAtLocal = const Value.absent(),
                Value<DateTime> updatedAtLocal = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                localId: localId,
                serverId: serverId,
                clientOrderCode: clientOrderCode,
                serverOrderCode: serverOrderCode,
                partnerId: partnerId,
                partnerName: partnerName,
                tableServerId: tableServerId,
                tableNoSnapshot: tableNoSnapshot,
                customerName: customerName,
                paymentMethodSelected: paymentMethodSelected,
                paymentMethodEffective: paymentMethodEffective,
                subtotal: subtotal,
                discountValue: discountValue,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                grandTotal: grandTotal,
                paidAmountLocal: paidAmountLocal,
                changeAmountLocal: changeAmountLocal,
                cashierProofImageLocalPath: cashierProofImageLocalPath,
                paymentConfirmedAtLocal: paymentConfirmedAtLocal,
                latestPaymentServerId: latestPaymentServerId,
                orderSnapshotJson: orderSnapshotJson,
                orderStatusLocal: orderStatusLocal,
                syncStatus: syncStatus,
                lastError: lastError,
                manualPaymentServerId: manualPaymentServerId,
                manualPaymentType: manualPaymentType,
                manualProviderName: manualProviderName,
                manualProviderAccountName: manualProviderAccountName,
                manualProviderAccountNo: manualProviderAccountNo,
                manualQrisImageUrl: manualQrisImageUrl,
                manualQrisImageLocalPath: manualQrisImageLocalPath,
                manualPaymentLabel: manualPaymentLabel,
                manualPaymentRawJson: manualPaymentRawJson,
                backendSyncStage: backendSyncStage,
                createdAtLocal: createdAtLocal,
                updatedAtLocal: updatedAtLocal,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<int?> serverId = const Value.absent(),
                required String clientOrderCode,
                Value<String?> serverOrderCode = const Value.absent(),
                Value<int?> partnerId = const Value.absent(),
                Value<String?> partnerName = const Value.absent(),
                Value<int?> tableServerId = const Value.absent(),
                Value<String?> tableNoSnapshot = const Value.absent(),
                required String customerName,
                Value<String?> paymentMethodSelected = const Value.absent(),
                Value<String?> paymentMethodEffective = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountValue = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double?> paidAmountLocal = const Value.absent(),
                Value<double?> changeAmountLocal = const Value.absent(),
                Value<String?> cashierProofImageLocalPath =
                    const Value.absent(),
                Value<DateTime?> paymentConfirmedAtLocal = const Value.absent(),
                Value<int?> latestPaymentServerId = const Value.absent(),
                Value<String?> orderSnapshotJson = const Value.absent(),
                Value<String> orderStatusLocal = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> manualPaymentServerId = const Value.absent(),
                Value<String?> manualPaymentType = const Value.absent(),
                Value<String?> manualProviderName = const Value.absent(),
                Value<String?> manualProviderAccountName = const Value.absent(),
                Value<String?> manualProviderAccountNo = const Value.absent(),
                Value<String?> manualQrisImageUrl = const Value.absent(),
                Value<String?> manualQrisImageLocalPath = const Value.absent(),
                Value<String?> manualPaymentLabel = const Value.absent(),
                Value<String?> manualPaymentRawJson = const Value.absent(),
                Value<String> backendSyncStage = const Value.absent(),
                required DateTime createdAtLocal,
                required DateTime updatedAtLocal,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                localId: localId,
                serverId: serverId,
                clientOrderCode: clientOrderCode,
                serverOrderCode: serverOrderCode,
                partnerId: partnerId,
                partnerName: partnerName,
                tableServerId: tableServerId,
                tableNoSnapshot: tableNoSnapshot,
                customerName: customerName,
                paymentMethodSelected: paymentMethodSelected,
                paymentMethodEffective: paymentMethodEffective,
                subtotal: subtotal,
                discountValue: discountValue,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                grandTotal: grandTotal,
                paidAmountLocal: paidAmountLocal,
                changeAmountLocal: changeAmountLocal,
                cashierProofImageLocalPath: cashierProofImageLocalPath,
                paymentConfirmedAtLocal: paymentConfirmedAtLocal,
                latestPaymentServerId: latestPaymentServerId,
                orderSnapshotJson: orderSnapshotJson,
                orderStatusLocal: orderStatusLocal,
                syncStatus: syncStatus,
                lastError: lastError,
                manualPaymentServerId: manualPaymentServerId,
                manualPaymentType: manualPaymentType,
                manualProviderName: manualProviderName,
                manualProviderAccountName: manualProviderAccountName,
                manualProviderAccountNo: manualProviderAccountNo,
                manualQrisImageUrl: manualQrisImageUrl,
                manualQrisImageLocalPath: manualQrisImageLocalPath,
                manualPaymentLabel: manualPaymentLabel,
                manualPaymentRawJson: manualPaymentRawJson,
                backendSyncStage: backendSyncStage,
                createdAtLocal: createdAtLocal,
                updatedAtLocal: updatedAtLocal,
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

typedef $$LocalOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $LocalOrdersTable,
      LocalOrder,
      $$LocalOrdersTableFilterComposer,
      $$LocalOrdersTableOrderingComposer,
      $$LocalOrdersTableAnnotationComposer,
      $$LocalOrdersTableCreateCompanionBuilder,
      $$LocalOrdersTableUpdateCompanionBuilder,
      (LocalOrder, BaseReferences<_$CashierDb, $LocalOrdersTable, LocalOrder>),
      LocalOrder,
      PrefetchHooks Function()
    >;
typedef $$LocalOrderItemsTableCreateCompanionBuilder =
    LocalOrderItemsCompanion Function({
      required String localId,
      required String orderLocalId,
      Value<int?> serverOrderDetailId,
      required int productServerId,
      required String productNameSnapshot,
      Value<double> basePrice,
      Value<int?> promoId,
      Value<String?> promoType,
      Value<double?> promoAmount,
      Value<int?> categoryServerId,
      Value<String?> categoryNameSnapshot,
      Value<double> optionsPrice,
      required int qty,
      Value<String?> customerNote,
      Value<double> lineTotal,
      required DateTime createdAtLocal,
      Value<int> rowid,
    });
typedef $$LocalOrderItemsTableUpdateCompanionBuilder =
    LocalOrderItemsCompanion Function({
      Value<String> localId,
      Value<String> orderLocalId,
      Value<int?> serverOrderDetailId,
      Value<int> productServerId,
      Value<String> productNameSnapshot,
      Value<double> basePrice,
      Value<int?> promoId,
      Value<String?> promoType,
      Value<double?> promoAmount,
      Value<int?> categoryServerId,
      Value<String?> categoryNameSnapshot,
      Value<double> optionsPrice,
      Value<int> qty,
      Value<String?> customerNote,
      Value<double> lineTotal,
      Value<DateTime> createdAtLocal,
      Value<int> rowid,
    });

class $$LocalOrderItemsTableFilterComposer
    extends Composer<_$CashierDb, $LocalOrderItemsTable> {
  $$LocalOrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverOrderDetailId => $composableBuilder(
    column: $table.serverOrderDetailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
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

  ColumnFilters<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrderItemsTableOrderingComposer
    extends Composer<_$CashierDb, $LocalOrderItemsTable> {
  $$LocalOrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverOrderDetailId => $composableBuilder(
    column: $table.serverOrderDetailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
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

  ColumnOrderings<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrderItemsTableAnnotationComposer
    extends Composer<_$CashierDb, $LocalOrderItemsTable> {
  $$LocalOrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverOrderDetailId => $composableBuilder(
    column: $table.serverOrderDetailId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<int> get promoId =>
      $composableBuilder(column: $table.promoId, builder: (column) => column);

  GeneratedColumn<String> get promoType =>
      $composableBuilder(column: $table.promoType, builder: (column) => column);

  GeneratedColumn<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get optionsPrice => $composableBuilder(
    column: $table.optionsPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => column,
  );
}

class $$LocalOrderItemsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $LocalOrderItemsTable,
          LocalOrderItem,
          $$LocalOrderItemsTableFilterComposer,
          $$LocalOrderItemsTableOrderingComposer,
          $$LocalOrderItemsTableAnnotationComposer,
          $$LocalOrderItemsTableCreateCompanionBuilder,
          $$LocalOrderItemsTableUpdateCompanionBuilder,
          (
            LocalOrderItem,
            BaseReferences<_$CashierDb, $LocalOrderItemsTable, LocalOrderItem>,
          ),
          LocalOrderItem,
          PrefetchHooks Function()
        > {
  $$LocalOrderItemsTableTableManager(
    _$CashierDb db,
    $LocalOrderItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> orderLocalId = const Value.absent(),
                Value<int?> serverOrderDetailId = const Value.absent(),
                Value<int> productServerId = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<double> basePrice = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<double?> promoAmount = const Value.absent(),
                Value<int?> categoryServerId = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<double> optionsPrice = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
                Value<double> lineTotal = const Value.absent(),
                Value<DateTime> createdAtLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrderItemsCompanion(
                localId: localId,
                orderLocalId: orderLocalId,
                serverOrderDetailId: serverOrderDetailId,
                productServerId: productServerId,
                productNameSnapshot: productNameSnapshot,
                basePrice: basePrice,
                promoId: promoId,
                promoType: promoType,
                promoAmount: promoAmount,
                categoryServerId: categoryServerId,
                categoryNameSnapshot: categoryNameSnapshot,
                optionsPrice: optionsPrice,
                qty: qty,
                customerNote: customerNote,
                lineTotal: lineTotal,
                createdAtLocal: createdAtLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String orderLocalId,
                Value<int?> serverOrderDetailId = const Value.absent(),
                required int productServerId,
                required String productNameSnapshot,
                Value<double> basePrice = const Value.absent(),
                Value<int?> promoId = const Value.absent(),
                Value<String?> promoType = const Value.absent(),
                Value<double?> promoAmount = const Value.absent(),
                Value<int?> categoryServerId = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<double> optionsPrice = const Value.absent(),
                required int qty,
                Value<String?> customerNote = const Value.absent(),
                Value<double> lineTotal = const Value.absent(),
                required DateTime createdAtLocal,
                Value<int> rowid = const Value.absent(),
              }) => LocalOrderItemsCompanion.insert(
                localId: localId,
                orderLocalId: orderLocalId,
                serverOrderDetailId: serverOrderDetailId,
                productServerId: productServerId,
                productNameSnapshot: productNameSnapshot,
                basePrice: basePrice,
                promoId: promoId,
                promoType: promoType,
                promoAmount: promoAmount,
                categoryServerId: categoryServerId,
                categoryNameSnapshot: categoryNameSnapshot,
                optionsPrice: optionsPrice,
                qty: qty,
                customerNote: customerNote,
                lineTotal: lineTotal,
                createdAtLocal: createdAtLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $LocalOrderItemsTable,
      LocalOrderItem,
      $$LocalOrderItemsTableFilterComposer,
      $$LocalOrderItemsTableOrderingComposer,
      $$LocalOrderItemsTableAnnotationComposer,
      $$LocalOrderItemsTableCreateCompanionBuilder,
      $$LocalOrderItemsTableUpdateCompanionBuilder,
      (
        LocalOrderItem,
        BaseReferences<_$CashierDb, $LocalOrderItemsTable, LocalOrderItem>,
      ),
      LocalOrderItem,
      PrefetchHooks Function()
    >;
typedef $$LocalOrderItemOptionsTableCreateCompanionBuilder =
    LocalOrderItemOptionsCompanion Function({
      required String localId,
      required String orderItemLocalId,
      Value<int?> serverOrderDetailOptionId,
      required int optionServerId,
      Value<String?> parentNameSnapshot,
      required String optionNameSnapshot,
      Value<double> price,
      required DateTime createdAtLocal,
      Value<int> rowid,
    });
typedef $$LocalOrderItemOptionsTableUpdateCompanionBuilder =
    LocalOrderItemOptionsCompanion Function({
      Value<String> localId,
      Value<String> orderItemLocalId,
      Value<int?> serverOrderDetailOptionId,
      Value<int> optionServerId,
      Value<String?> parentNameSnapshot,
      Value<String> optionNameSnapshot,
      Value<double> price,
      Value<DateTime> createdAtLocal,
      Value<int> rowid,
    });

class $$LocalOrderItemOptionsTableFilterComposer
    extends Composer<_$CashierDb, $LocalOrderItemOptionsTable> {
  $$LocalOrderItemOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderItemLocalId => $composableBuilder(
    column: $table.orderItemLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverOrderDetailOptionId => $composableBuilder(
    column: $table.serverOrderDetailOptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get optionServerId => $composableBuilder(
    column: $table.optionServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentNameSnapshot => $composableBuilder(
    column: $table.parentNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionNameSnapshot => $composableBuilder(
    column: $table.optionNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrderItemOptionsTableOrderingComposer
    extends Composer<_$CashierDb, $LocalOrderItemOptionsTable> {
  $$LocalOrderItemOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderItemLocalId => $composableBuilder(
    column: $table.orderItemLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverOrderDetailOptionId => $composableBuilder(
    column: $table.serverOrderDetailOptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get optionServerId => $composableBuilder(
    column: $table.optionServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentNameSnapshot => $composableBuilder(
    column: $table.parentNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionNameSnapshot => $composableBuilder(
    column: $table.optionNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrderItemOptionsTableAnnotationComposer
    extends Composer<_$CashierDb, $LocalOrderItemOptionsTable> {
  $$LocalOrderItemOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get orderItemLocalId => $composableBuilder(
    column: $table.orderItemLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverOrderDetailOptionId => $composableBuilder(
    column: $table.serverOrderDetailOptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get optionServerId => $composableBuilder(
    column: $table.optionServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentNameSnapshot => $composableBuilder(
    column: $table.parentNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionNameSnapshot => $composableBuilder(
    column: $table.optionNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => column,
  );
}

class $$LocalOrderItemOptionsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $LocalOrderItemOptionsTable,
          LocalOrderItemOption,
          $$LocalOrderItemOptionsTableFilterComposer,
          $$LocalOrderItemOptionsTableOrderingComposer,
          $$LocalOrderItemOptionsTableAnnotationComposer,
          $$LocalOrderItemOptionsTableCreateCompanionBuilder,
          $$LocalOrderItemOptionsTableUpdateCompanionBuilder,
          (
            LocalOrderItemOption,
            BaseReferences<
              _$CashierDb,
              $LocalOrderItemOptionsTable,
              LocalOrderItemOption
            >,
          ),
          LocalOrderItemOption,
          PrefetchHooks Function()
        > {
  $$LocalOrderItemOptionsTableTableManager(
    _$CashierDb db,
    $LocalOrderItemOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrderItemOptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalOrderItemOptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalOrderItemOptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> orderItemLocalId = const Value.absent(),
                Value<int?> serverOrderDetailOptionId = const Value.absent(),
                Value<int> optionServerId = const Value.absent(),
                Value<String?> parentNameSnapshot = const Value.absent(),
                Value<String> optionNameSnapshot = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<DateTime> createdAtLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrderItemOptionsCompanion(
                localId: localId,
                orderItemLocalId: orderItemLocalId,
                serverOrderDetailOptionId: serverOrderDetailOptionId,
                optionServerId: optionServerId,
                parentNameSnapshot: parentNameSnapshot,
                optionNameSnapshot: optionNameSnapshot,
                price: price,
                createdAtLocal: createdAtLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String orderItemLocalId,
                Value<int?> serverOrderDetailOptionId = const Value.absent(),
                required int optionServerId,
                Value<String?> parentNameSnapshot = const Value.absent(),
                required String optionNameSnapshot,
                Value<double> price = const Value.absent(),
                required DateTime createdAtLocal,
                Value<int> rowid = const Value.absent(),
              }) => LocalOrderItemOptionsCompanion.insert(
                localId: localId,
                orderItemLocalId: orderItemLocalId,
                serverOrderDetailOptionId: serverOrderDetailOptionId,
                optionServerId: optionServerId,
                parentNameSnapshot: parentNameSnapshot,
                optionNameSnapshot: optionNameSnapshot,
                price: price,
                createdAtLocal: createdAtLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrderItemOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $LocalOrderItemOptionsTable,
      LocalOrderItemOption,
      $$LocalOrderItemOptionsTableFilterComposer,
      $$LocalOrderItemOptionsTableOrderingComposer,
      $$LocalOrderItemOptionsTableAnnotationComposer,
      $$LocalOrderItemOptionsTableCreateCompanionBuilder,
      $$LocalOrderItemOptionsTableUpdateCompanionBuilder,
      (
        LocalOrderItemOption,
        BaseReferences<
          _$CashierDb,
          $LocalOrderItemOptionsTable,
          LocalOrderItemOption
        >,
      ),
      LocalOrderItemOption,
      PrefetchHooks Function()
    >;
typedef $$LocalPaymentsTableCreateCompanionBuilder =
    LocalPaymentsCompanion Function({
      required String localId,
      required String orderLocalId,
      Value<int?> serverPaymentId,
      required String paymentType,
      Value<int?> manualPaymentServerId,
      Value<double> amountBeforePpn,
      Value<double> ppn,
      Value<double> paidAmount,
      Value<double> changeAmount,
      Value<String> paymentStatus,
      Value<String?> note,
      Value<String?> proofImageLocalPath,
      Value<bool> proofImageUploaded,
      required DateTime createdAtLocal,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$LocalPaymentsTableUpdateCompanionBuilder =
    LocalPaymentsCompanion Function({
      Value<String> localId,
      Value<String> orderLocalId,
      Value<int?> serverPaymentId,
      Value<String> paymentType,
      Value<int?> manualPaymentServerId,
      Value<double> amountBeforePpn,
      Value<double> ppn,
      Value<double> paidAmount,
      Value<double> changeAmount,
      Value<String> paymentStatus,
      Value<String?> note,
      Value<String?> proofImageLocalPath,
      Value<bool> proofImageUploaded,
      Value<DateTime> createdAtLocal,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$LocalPaymentsTableFilterComposer
    extends Composer<_$CashierDb, $LocalPaymentsTable> {
  $$LocalPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverPaymentId => $composableBuilder(
    column: $table.serverPaymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppn => $composableBuilder(
    column: $table.ppn,
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

  ColumnFilters<String> get proofImageLocalPath => $composableBuilder(
    column: $table.proofImageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get proofImageUploaded => $composableBuilder(
    column: $table.proofImageUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPaymentsTableOrderingComposer
    extends Composer<_$CashierDb, $LocalPaymentsTable> {
  $$LocalPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverPaymentId => $composableBuilder(
    column: $table.serverPaymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppn => $composableBuilder(
    column: $table.ppn,
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

  ColumnOrderings<String> get proofImageLocalPath => $composableBuilder(
    column: $table.proofImageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get proofImageUploaded => $composableBuilder(
    column: $table.proofImageUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPaymentsTableAnnotationComposer
    extends Composer<_$CashierDb, $LocalPaymentsTable> {
  $$LocalPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get orderLocalId => $composableBuilder(
    column: $table.orderLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverPaymentId => $composableBuilder(
    column: $table.serverPaymentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentType => $composableBuilder(
    column: $table.paymentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get manualPaymentServerId => $composableBuilder(
    column: $table.manualPaymentServerId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountBeforePpn => $composableBuilder(
    column: $table.amountBeforePpn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ppn =>
      $composableBuilder(column: $table.ppn, builder: (column) => column);

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

  GeneratedColumn<String> get proofImageLocalPath => $composableBuilder(
    column: $table.proofImageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get proofImageUploaded => $composableBuilder(
    column: $table.proofImageUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalPaymentsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $LocalPaymentsTable,
          LocalPayment,
          $$LocalPaymentsTableFilterComposer,
          $$LocalPaymentsTableOrderingComposer,
          $$LocalPaymentsTableAnnotationComposer,
          $$LocalPaymentsTableCreateCompanionBuilder,
          $$LocalPaymentsTableUpdateCompanionBuilder,
          (
            LocalPayment,
            BaseReferences<_$CashierDb, $LocalPaymentsTable, LocalPayment>,
          ),
          LocalPayment,
          PrefetchHooks Function()
        > {
  $$LocalPaymentsTableTableManager(_$CashierDb db, $LocalPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> orderLocalId = const Value.absent(),
                Value<int?> serverPaymentId = const Value.absent(),
                Value<String> paymentType = const Value.absent(),
                Value<int?> manualPaymentServerId = const Value.absent(),
                Value<double> amountBeforePpn = const Value.absent(),
                Value<double> ppn = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> proofImageLocalPath = const Value.absent(),
                Value<bool> proofImageUploaded = const Value.absent(),
                Value<DateTime> createdAtLocal = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPaymentsCompanion(
                localId: localId,
                orderLocalId: orderLocalId,
                serverPaymentId: serverPaymentId,
                paymentType: paymentType,
                manualPaymentServerId: manualPaymentServerId,
                amountBeforePpn: amountBeforePpn,
                ppn: ppn,
                paidAmount: paidAmount,
                changeAmount: changeAmount,
                paymentStatus: paymentStatus,
                note: note,
                proofImageLocalPath: proofImageLocalPath,
                proofImageUploaded: proofImageUploaded,
                createdAtLocal: createdAtLocal,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String orderLocalId,
                Value<int?> serverPaymentId = const Value.absent(),
                required String paymentType,
                Value<int?> manualPaymentServerId = const Value.absent(),
                Value<double> amountBeforePpn = const Value.absent(),
                Value<double> ppn = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> proofImageLocalPath = const Value.absent(),
                Value<bool> proofImageUploaded = const Value.absent(),
                required DateTime createdAtLocal,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPaymentsCompanion.insert(
                localId: localId,
                orderLocalId: orderLocalId,
                serverPaymentId: serverPaymentId,
                paymentType: paymentType,
                manualPaymentServerId: manualPaymentServerId,
                amountBeforePpn: amountBeforePpn,
                ppn: ppn,
                paidAmount: paidAmount,
                changeAmount: changeAmount,
                paymentStatus: paymentStatus,
                note: note,
                proofImageLocalPath: proofImageLocalPath,
                proofImageUploaded: proofImageUploaded,
                createdAtLocal: createdAtLocal,
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

typedef $$LocalPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $LocalPaymentsTable,
      LocalPayment,
      $$LocalPaymentsTableFilterComposer,
      $$LocalPaymentsTableOrderingComposer,
      $$LocalPaymentsTableAnnotationComposer,
      $$LocalPaymentsTableCreateCompanionBuilder,
      $$LocalPaymentsTableUpdateCompanionBuilder,
      (
        LocalPayment,
        BaseReferences<_$CashierDb, $LocalPaymentsTable, LocalPayment>,
      ),
      LocalPayment,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityLocalId,
      required String action,
      Value<int?> dependsOnQueueId,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime?> nextRetryAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityLocalId,
      Value<String> action,
      Value<int?> dependsOnQueueId,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$CashierDb, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dependsOnQueueId => $composableBuilder(
    column: $table.dependsOnQueueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
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

class $$SyncQueueTableOrderingComposer
    extends Composer<_$CashierDb, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dependsOnQueueId => $composableBuilder(
    column: $table.dependsOnQueueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
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

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$CashierDb, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get dependsOnQueueId => $composableBuilder(
    column: $table.dependsOnQueueId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$CashierDb, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$CashierDb db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityLocalId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<int?> dependsOnQueueId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityLocalId: entityLocalId,
                action: action,
                dependsOnQueueId: dependsOnQueueId,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityLocalId,
                required String action,
                Value<int?> dependsOnQueueId = const Value.absent(),
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityLocalId: entityLocalId,
                action: action,
                dependsOnQueueId: dependsOnQueueId,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$CashierDb, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$CachedPaymentOrdersTableCreateCompanionBuilder =
    CachedPaymentOrdersCompanion Function({
      Value<int> serverId,
      required String bookingOrderCode,
      required String customerName,
      Value<String?> tableNo,
      Value<String?> paymentRequestJson,
      Value<String?> latestPaymentJson,
      Value<String?> paymentMethod,
      required String orderStatus,
      Value<String?> detailJson,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<bool> isPendingDelete,
      Value<double> grandTotal,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      required DateTime cachedAt,
    });
typedef $$CachedPaymentOrdersTableUpdateCompanionBuilder =
    CachedPaymentOrdersCompanion Function({
      Value<int> serverId,
      Value<String> bookingOrderCode,
      Value<String> customerName,
      Value<String?> tableNo,
      Value<String?> paymentRequestJson,
      Value<String?> latestPaymentJson,
      Value<String?> paymentMethod,
      Value<String> orderStatus,
      Value<String?> detailJson,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<bool> isPendingDelete,
      Value<double> grandTotal,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime> cachedAt,
    });

class $$CachedPaymentOrdersTableFilterComposer
    extends Composer<_$CashierDb, $CachedPaymentOrdersTable> {
  $$CachedPaymentOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
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

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
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

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPaymentOrdersTableOrderingComposer
    extends Composer<_$CashierDb, $CachedPaymentOrdersTable> {
  $$CachedPaymentOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
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

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
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

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPaymentOrdersTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedPaymentOrdersTable> {
  $$CachedPaymentOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableNo =>
      $composableBuilder(column: $table.tableNo, builder: (column) => column);

  GeneratedColumn<String> get paymentRequestJson => $composableBuilder(
    column: $table.paymentRequestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestPaymentJson => $composableBuilder(
    column: $table.latestPaymentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedPaymentOrdersTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedPaymentOrdersTable,
          CachedPaymentOrder,
          $$CachedPaymentOrdersTableFilterComposer,
          $$CachedPaymentOrdersTableOrderingComposer,
          $$CachedPaymentOrdersTableAnnotationComposer,
          $$CachedPaymentOrdersTableCreateCompanionBuilder,
          $$CachedPaymentOrdersTableUpdateCompanionBuilder,
          (
            CachedPaymentOrder,
            BaseReferences<
              _$CashierDb,
              $CachedPaymentOrdersTable,
              CachedPaymentOrder
            >,
          ),
          CachedPaymentOrder,
          PrefetchHooks Function()
        > {
  $$CachedPaymentOrdersTableTableManager(
    _$CashierDb db,
    $CachedPaymentOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPaymentOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPaymentOrdersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPaymentOrdersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> bookingOrderCode = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> tableNo = const Value.absent(),
                Value<String?> paymentRequestJson = const Value.absent(),
                Value<String?> latestPaymentJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedPaymentOrdersCompanion(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                paymentRequestJson: paymentRequestJson,
                latestPaymentJson: latestPaymentJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                detailJson: detailJson,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                isPendingDelete: isPendingDelete,
                grandTotal: grandTotal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                required String bookingOrderCode,
                required String customerName,
                Value<String?> tableNo = const Value.absent(),
                Value<String?> paymentRequestJson = const Value.absent(),
                Value<String?> latestPaymentJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required String orderStatus,
                Value<String?> detailJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedPaymentOrdersCompanion.insert(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                paymentRequestJson: paymentRequestJson,
                latestPaymentJson: latestPaymentJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                detailJson: detailJson,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                isPendingDelete: isPendingDelete,
                grandTotal: grandTotal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPaymentOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedPaymentOrdersTable,
      CachedPaymentOrder,
      $$CachedPaymentOrdersTableFilterComposer,
      $$CachedPaymentOrdersTableOrderingComposer,
      $$CachedPaymentOrdersTableAnnotationComposer,
      $$CachedPaymentOrdersTableCreateCompanionBuilder,
      $$CachedPaymentOrdersTableUpdateCompanionBuilder,
      (
        CachedPaymentOrder,
        BaseReferences<
          _$CashierDb,
          $CachedPaymentOrdersTable,
          CachedPaymentOrder
        >,
      ),
      CachedPaymentOrder,
      PrefetchHooks Function()
    >;
typedef $$CachedProcessOrdersTableCreateCompanionBuilder =
    CachedProcessOrdersCompanion Function({
      Value<int> serverId,
      required String bookingOrderCode,
      required String customerName,
      Value<String?> tableNo,
      Value<String?> processRequestJson,
      Value<String?> latestProcessJson,
      Value<String?> detailJson,
      Value<String?> paymentMethod,
      required String orderStatus,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<String?> pendingAction,
      Value<bool> isSynced,
      Value<bool> deletedLocally,
      Value<DateTime?> syncedAt,
    });
typedef $$CachedProcessOrdersTableUpdateCompanionBuilder =
    CachedProcessOrdersCompanion Function({
      Value<int> serverId,
      Value<String> bookingOrderCode,
      Value<String> customerName,
      Value<String?> tableNo,
      Value<String?> processRequestJson,
      Value<String?> latestProcessJson,
      Value<String?> detailJson,
      Value<String?> paymentMethod,
      Value<String> orderStatus,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<String?> pendingAction,
      Value<bool> isSynced,
      Value<bool> deletedLocally,
      Value<DateTime?> syncedAt,
    });

class $$CachedProcessOrdersTableFilterComposer
    extends Composer<_$CashierDb, $CachedProcessOrdersTable> {
  $$CachedProcessOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processRequestJson => $composableBuilder(
    column: $table.processRequestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestProcessJson => $composableBuilder(
    column: $table.latestProcessJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingAction => $composableBuilder(
    column: $table.pendingAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProcessOrdersTableOrderingComposer
    extends Composer<_$CashierDb, $CachedProcessOrdersTable> {
  $$CachedProcessOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processRequestJson => $composableBuilder(
    column: $table.processRequestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestProcessJson => $composableBuilder(
    column: $table.latestProcessJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingAction => $composableBuilder(
    column: $table.pendingAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProcessOrdersTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedProcessOrdersTable> {
  $$CachedProcessOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableNo =>
      $composableBuilder(column: $table.tableNo, builder: (column) => column);

  GeneratedColumn<String> get processRequestJson => $composableBuilder(
    column: $table.processRequestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestProcessJson => $composableBuilder(
    column: $table.latestProcessJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingAction => $composableBuilder(
    column: $table.pendingAction,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedProcessOrdersTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedProcessOrdersTable,
          CachedProcessOrder,
          $$CachedProcessOrdersTableFilterComposer,
          $$CachedProcessOrdersTableOrderingComposer,
          $$CachedProcessOrdersTableAnnotationComposer,
          $$CachedProcessOrdersTableCreateCompanionBuilder,
          $$CachedProcessOrdersTableUpdateCompanionBuilder,
          (
            CachedProcessOrder,
            BaseReferences<
              _$CashierDb,
              $CachedProcessOrdersTable,
              CachedProcessOrder
            >,
          ),
          CachedProcessOrder,
          PrefetchHooks Function()
        > {
  $$CachedProcessOrdersTableTableManager(
    _$CashierDb db,
    $CachedProcessOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProcessOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProcessOrdersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedProcessOrdersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> bookingOrderCode = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> tableNo = const Value.absent(),
                Value<String?> processRequestJson = const Value.absent(),
                Value<String?> latestProcessJson = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<String?> pendingAction = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => CachedProcessOrdersCompanion(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                processRequestJson: processRequestJson,
                latestProcessJson: latestProcessJson,
                detailJson: detailJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                pendingAction: pendingAction,
                isSynced: isSynced,
                deletedLocally: deletedLocally,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                required String bookingOrderCode,
                required String customerName,
                Value<String?> tableNo = const Value.absent(),
                Value<String?> processRequestJson = const Value.absent(),
                Value<String?> latestProcessJson = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required String orderStatus,
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<String?> pendingAction = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => CachedProcessOrdersCompanion.insert(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                processRequestJson: processRequestJson,
                latestProcessJson: latestProcessJson,
                detailJson: detailJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                pendingAction: pendingAction,
                isSynced: isSynced,
                deletedLocally: deletedLocally,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProcessOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedProcessOrdersTable,
      CachedProcessOrder,
      $$CachedProcessOrdersTableFilterComposer,
      $$CachedProcessOrdersTableOrderingComposer,
      $$CachedProcessOrdersTableAnnotationComposer,
      $$CachedProcessOrdersTableCreateCompanionBuilder,
      $$CachedProcessOrdersTableUpdateCompanionBuilder,
      (
        CachedProcessOrder,
        BaseReferences<
          _$CashierDb,
          $CachedProcessOrdersTable,
          CachedProcessOrder
        >,
      ),
      CachedProcessOrder,
      PrefetchHooks Function()
    >;
typedef $$CachedPaymentOrderItemsTableCreateCompanionBuilder =
    CachedPaymentOrderItemsCompanion Function({
      Value<int> serverDetailId,
      required int orderServerId,
      Value<int?> productServerId,
      required String productName,
      Value<double> basePrice,
      Value<double> promoAmount,
      Value<int> qty,
      Value<String?> customerNote,
    });
typedef $$CachedPaymentOrderItemsTableUpdateCompanionBuilder =
    CachedPaymentOrderItemsCompanion Function({
      Value<int> serverDetailId,
      Value<int> orderServerId,
      Value<int?> productServerId,
      Value<String> productName,
      Value<double> basePrice,
      Value<double> promoAmount,
      Value<int> qty,
      Value<String?> customerNote,
    });

class $$CachedPaymentOrderItemsTableFilterComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemsTable> {
  $$CachedPaymentOrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverDetailId => $composableBuilder(
    column: $table.serverDetailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderServerId => $composableBuilder(
    column: $table.orderServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPaymentOrderItemsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemsTable> {
  $$CachedPaymentOrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverDetailId => $composableBuilder(
    column: $table.serverDetailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderServerId => $composableBuilder(
    column: $table.orderServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPaymentOrderItemsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemsTable> {
  $$CachedPaymentOrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverDetailId => $composableBuilder(
    column: $table.serverDetailId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderServerId => $composableBuilder(
    column: $table.orderServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productServerId => $composableBuilder(
    column: $table.productServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<double> get promoAmount => $composableBuilder(
    column: $table.promoAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => column,
  );
}

class $$CachedPaymentOrderItemsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedPaymentOrderItemsTable,
          CachedPaymentOrderItem,
          $$CachedPaymentOrderItemsTableFilterComposer,
          $$CachedPaymentOrderItemsTableOrderingComposer,
          $$CachedPaymentOrderItemsTableAnnotationComposer,
          $$CachedPaymentOrderItemsTableCreateCompanionBuilder,
          $$CachedPaymentOrderItemsTableUpdateCompanionBuilder,
          (
            CachedPaymentOrderItem,
            BaseReferences<
              _$CashierDb,
              $CachedPaymentOrderItemsTable,
              CachedPaymentOrderItem
            >,
          ),
          CachedPaymentOrderItem,
          PrefetchHooks Function()
        > {
  $$CachedPaymentOrderItemsTableTableManager(
    _$CashierDb db,
    $CachedPaymentOrderItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPaymentOrderItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedPaymentOrderItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPaymentOrderItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> serverDetailId = const Value.absent(),
                Value<int> orderServerId = const Value.absent(),
                Value<int?> productServerId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<double> basePrice = const Value.absent(),
                Value<double> promoAmount = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
              }) => CachedPaymentOrderItemsCompanion(
                serverDetailId: serverDetailId,
                orderServerId: orderServerId,
                productServerId: productServerId,
                productName: productName,
                basePrice: basePrice,
                promoAmount: promoAmount,
                qty: qty,
                customerNote: customerNote,
              ),
          createCompanionCallback:
              ({
                Value<int> serverDetailId = const Value.absent(),
                required int orderServerId,
                Value<int?> productServerId = const Value.absent(),
                required String productName,
                Value<double> basePrice = const Value.absent(),
                Value<double> promoAmount = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
              }) => CachedPaymentOrderItemsCompanion.insert(
                serverDetailId: serverDetailId,
                orderServerId: orderServerId,
                productServerId: productServerId,
                productName: productName,
                basePrice: basePrice,
                promoAmount: promoAmount,
                qty: qty,
                customerNote: customerNote,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPaymentOrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedPaymentOrderItemsTable,
      CachedPaymentOrderItem,
      $$CachedPaymentOrderItemsTableFilterComposer,
      $$CachedPaymentOrderItemsTableOrderingComposer,
      $$CachedPaymentOrderItemsTableAnnotationComposer,
      $$CachedPaymentOrderItemsTableCreateCompanionBuilder,
      $$CachedPaymentOrderItemsTableUpdateCompanionBuilder,
      (
        CachedPaymentOrderItem,
        BaseReferences<
          _$CashierDb,
          $CachedPaymentOrderItemsTable,
          CachedPaymentOrderItem
        >,
      ),
      CachedPaymentOrderItem,
      PrefetchHooks Function()
    >;
typedef $$CachedPaymentOrderItemOptionsTableCreateCompanionBuilder =
    CachedPaymentOrderItemOptionsCompanion Function({
      Value<int> serverDetailOptionId,
      required int orderDetailServerId,
      Value<String?> parentName,
      required String optionName,
      Value<double> price,
    });
typedef $$CachedPaymentOrderItemOptionsTableUpdateCompanionBuilder =
    CachedPaymentOrderItemOptionsCompanion Function({
      Value<int> serverDetailOptionId,
      Value<int> orderDetailServerId,
      Value<String?> parentName,
      Value<String> optionName,
      Value<double> price,
    });

class $$CachedPaymentOrderItemOptionsTableFilterComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemOptionsTable> {
  $$CachedPaymentOrderItemOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverDetailOptionId => $composableBuilder(
    column: $table.serverDetailOptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPaymentOrderItemOptionsTableOrderingComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemOptionsTable> {
  $$CachedPaymentOrderItemOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverDetailOptionId => $composableBuilder(
    column: $table.serverDetailOptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPaymentOrderItemOptionsTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedPaymentOrderItemOptionsTable> {
  $$CachedPaymentOrderItemOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverDetailOptionId => $composableBuilder(
    column: $table.serverDetailOptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderDetailServerId => $composableBuilder(
    column: $table.orderDetailServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);
}

class $$CachedPaymentOrderItemOptionsTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedPaymentOrderItemOptionsTable,
          CachedPaymentOrderItemOption,
          $$CachedPaymentOrderItemOptionsTableFilterComposer,
          $$CachedPaymentOrderItemOptionsTableOrderingComposer,
          $$CachedPaymentOrderItemOptionsTableAnnotationComposer,
          $$CachedPaymentOrderItemOptionsTableCreateCompanionBuilder,
          $$CachedPaymentOrderItemOptionsTableUpdateCompanionBuilder,
          (
            CachedPaymentOrderItemOption,
            BaseReferences<
              _$CashierDb,
              $CachedPaymentOrderItemOptionsTable,
              CachedPaymentOrderItemOption
            >,
          ),
          CachedPaymentOrderItemOption,
          PrefetchHooks Function()
        > {
  $$CachedPaymentOrderItemOptionsTableTableManager(
    _$CashierDb db,
    $CachedPaymentOrderItemOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPaymentOrderItemOptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedPaymentOrderItemOptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPaymentOrderItemOptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> serverDetailOptionId = const Value.absent(),
                Value<int> orderDetailServerId = const Value.absent(),
                Value<String?> parentName = const Value.absent(),
                Value<String> optionName = const Value.absent(),
                Value<double> price = const Value.absent(),
              }) => CachedPaymentOrderItemOptionsCompanion(
                serverDetailOptionId: serverDetailOptionId,
                orderDetailServerId: orderDetailServerId,
                parentName: parentName,
                optionName: optionName,
                price: price,
              ),
          createCompanionCallback:
              ({
                Value<int> serverDetailOptionId = const Value.absent(),
                required int orderDetailServerId,
                Value<String?> parentName = const Value.absent(),
                required String optionName,
                Value<double> price = const Value.absent(),
              }) => CachedPaymentOrderItemOptionsCompanion.insert(
                serverDetailOptionId: serverDetailOptionId,
                orderDetailServerId: orderDetailServerId,
                parentName: parentName,
                optionName: optionName,
                price: price,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPaymentOrderItemOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedPaymentOrderItemOptionsTable,
      CachedPaymentOrderItemOption,
      $$CachedPaymentOrderItemOptionsTableFilterComposer,
      $$CachedPaymentOrderItemOptionsTableOrderingComposer,
      $$CachedPaymentOrderItemOptionsTableAnnotationComposer,
      $$CachedPaymentOrderItemOptionsTableCreateCompanionBuilder,
      $$CachedPaymentOrderItemOptionsTableUpdateCompanionBuilder,
      (
        CachedPaymentOrderItemOption,
        BaseReferences<
          _$CashierDb,
          $CachedPaymentOrderItemOptionsTable,
          CachedPaymentOrderItemOption
        >,
      ),
      CachedPaymentOrderItemOption,
      PrefetchHooks Function()
    >;
typedef $$CachedDoneOrdersTableCreateCompanionBuilder =
    CachedDoneOrdersCompanion Function({
      Value<int> serverId,
      required String bookingOrderCode,
      required String customerName,
      Value<String?> tableNo,
      Value<String?> doneRequestJson,
      Value<String?> latestDoneJson,
      Value<String?> paymentMethod,
      required String orderStatus,
      Value<String?> detailJson,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<bool> isSynced,
      Value<bool> deletedLocally,
      Value<DateTime?> syncedAt,
    });
typedef $$CachedDoneOrdersTableUpdateCompanionBuilder =
    CachedDoneOrdersCompanion Function({
      Value<int> serverId,
      Value<String> bookingOrderCode,
      Value<String> customerName,
      Value<String?> tableNo,
      Value<String?> doneRequestJson,
      Value<String?> latestDoneJson,
      Value<String?> paymentMethod,
      Value<String> orderStatus,
      Value<String?> detailJson,
      Value<double> subtotal,
      Value<double> ppnPercent,
      Value<bool> isPpnActive,
      Value<bool> isSynced,
      Value<bool> deletedLocally,
      Value<DateTime?> syncedAt,
    });

class $$CachedDoneOrdersTableFilterComposer
    extends Composer<_$CashierDb, $CachedDoneOrdersTable> {
  $$CachedDoneOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doneRequestJson => $composableBuilder(
    column: $table.doneRequestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestDoneJson => $composableBuilder(
    column: $table.latestDoneJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDoneOrdersTableOrderingComposer
    extends Composer<_$CashierDb, $CachedDoneOrdersTable> {
  $$CachedDoneOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNo => $composableBuilder(
    column: $table.tableNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneRequestJson => $composableBuilder(
    column: $table.doneRequestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestDoneJson => $composableBuilder(
    column: $table.latestDoneJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDoneOrdersTableAnnotationComposer
    extends Composer<_$CashierDb, $CachedDoneOrdersTable> {
  $$CachedDoneOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get bookingOrderCode => $composableBuilder(
    column: $table.bookingOrderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableNo =>
      $composableBuilder(column: $table.tableNo, builder: (column) => column);

  GeneratedColumn<String> get doneRequestJson => $composableBuilder(
    column: $table.doneRequestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestDoneJson => $composableBuilder(
    column: $table.latestDoneJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get ppnPercent => $composableBuilder(
    column: $table.ppnPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPpnActive => $composableBuilder(
    column: $table.isPpnActive,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedDoneOrdersTableTableManager
    extends
        RootTableManager<
          _$CashierDb,
          $CachedDoneOrdersTable,
          CachedDoneOrder,
          $$CachedDoneOrdersTableFilterComposer,
          $$CachedDoneOrdersTableOrderingComposer,
          $$CachedDoneOrdersTableAnnotationComposer,
          $$CachedDoneOrdersTableCreateCompanionBuilder,
          $$CachedDoneOrdersTableUpdateCompanionBuilder,
          (
            CachedDoneOrder,
            BaseReferences<
              _$CashierDb,
              $CachedDoneOrdersTable,
              CachedDoneOrder
            >,
          ),
          CachedDoneOrder,
          PrefetchHooks Function()
        > {
  $$CachedDoneOrdersTableTableManager(
    _$CashierDb db,
    $CachedDoneOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDoneOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDoneOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDoneOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> bookingOrderCode = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> tableNo = const Value.absent(),
                Value<String?> doneRequestJson = const Value.absent(),
                Value<String?> latestDoneJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => CachedDoneOrdersCompanion(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                doneRequestJson: doneRequestJson,
                latestDoneJson: latestDoneJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                detailJson: detailJson,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                isSynced: isSynced,
                deletedLocally: deletedLocally,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                required String bookingOrderCode,
                required String customerName,
                Value<String?> tableNo = const Value.absent(),
                Value<String?> doneRequestJson = const Value.absent(),
                Value<String?> latestDoneJson = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                required String orderStatus,
                Value<String?> detailJson = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> ppnPercent = const Value.absent(),
                Value<bool> isPpnActive = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => CachedDoneOrdersCompanion.insert(
                serverId: serverId,
                bookingOrderCode: bookingOrderCode,
                customerName: customerName,
                tableNo: tableNo,
                doneRequestJson: doneRequestJson,
                latestDoneJson: latestDoneJson,
                paymentMethod: paymentMethod,
                orderStatus: orderStatus,
                detailJson: detailJson,
                subtotal: subtotal,
                ppnPercent: ppnPercent,
                isPpnActive: isPpnActive,
                isSynced: isSynced,
                deletedLocally: deletedLocally,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDoneOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$CashierDb,
      $CachedDoneOrdersTable,
      CachedDoneOrder,
      $$CachedDoneOrdersTableFilterComposer,
      $$CachedDoneOrdersTableOrderingComposer,
      $$CachedDoneOrdersTableAnnotationComposer,
      $$CachedDoneOrdersTableCreateCompanionBuilder,
      $$CachedDoneOrdersTableUpdateCompanionBuilder,
      (
        CachedDoneOrder,
        BaseReferences<_$CashierDb, $CachedDoneOrdersTable, CachedDoneOrder>,
      ),
      CachedDoneOrder,
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
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$LocalOrderItemsTableTableManager get localOrderItems =>
      $$LocalOrderItemsTableTableManager(_db, _db.localOrderItems);
  $$LocalOrderItemOptionsTableTableManager get localOrderItemOptions =>
      $$LocalOrderItemOptionsTableTableManager(_db, _db.localOrderItemOptions);
  $$LocalPaymentsTableTableManager get localPayments =>
      $$LocalPaymentsTableTableManager(_db, _db.localPayments);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CachedPaymentOrdersTableTableManager get cachedPaymentOrders =>
      $$CachedPaymentOrdersTableTableManager(_db, _db.cachedPaymentOrders);
  $$CachedProcessOrdersTableTableManager get cachedProcessOrders =>
      $$CachedProcessOrdersTableTableManager(_db, _db.cachedProcessOrders);
  $$CachedPaymentOrderItemsTableTableManager get cachedPaymentOrderItems =>
      $$CachedPaymentOrderItemsTableTableManager(
        _db,
        _db.cachedPaymentOrderItems,
      );
  $$CachedPaymentOrderItemOptionsTableTableManager
  get cachedPaymentOrderItemOptions =>
      $$CachedPaymentOrderItemOptionsTableTableManager(
        _db,
        _db.cachedPaymentOrderItemOptions,
      );
  $$CachedDoneOrdersTableTableManager get cachedDoneOrders =>
      $$CachedDoneOrdersTableTableManager(_db, _db.cachedDoneOrders);
}
