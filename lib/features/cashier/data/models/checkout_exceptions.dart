class StockConflictItem {
  const StockConflictItem({
    required this.type,
    required this.name,
    required this.requested,
    required this.available,
    this.id,
    this.productId,
    this.productName,
    this.optionId,
    this.stockId,
    this.stockType,
    this.unit,
    this.groupName,
  });

  final String type;
  final String name;
  final num requested;
  final num available;
  final int? id;
  final int? productId;
  final String? productName;
  final int? optionId;
  final int? stockId;
  final String? stockType;
  final String? unit;
  final String? groupName;

  factory StockConflictItem.fromJson(Map<String, dynamic> json, String type) {
    return StockConflictItem(
      type: type,
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      productName: json['product_name']?.toString(),
      optionId: _parseInt(json['option_id']),
      stockId: _parseInt(json['stock_id'] ?? json['raw_material_id']),
      name: (json['name'] ?? json['stock_name'] ?? '-').toString(),
      requested: _parseNum(json['requested']),
      available: _parseNum(json['available']),
      stockType: json['stock_type']?.toString(),
      unit: json['unit']?.toString(),
      groupName: json['group_name']?.toString(),
    );
  }

  String get label {
    final scope = switch (type) {
      'product' => 'Produk',
      'option' => 'Opsi',
      'raw_material' => 'Bahan baku',
      _ => 'Stok',
    };
    final unitText = unit == null || unit!.isEmpty ? '' : ' $unit';
    final groupText =
        groupName == null || groupName!.isEmpty ? '' : ' ($groupName)';
    final productText = type == 'option' &&
            productName != null &&
            productName!.trim().isNotEmpty
        ? ' untuk ${productName!.trim()}'
        : '';
    return '$scope: $name$groupText$productText, diminta ${_fmt(requested)}$unitText, tersedia ${_fmt(available)}$unitText';
  }
}

class StockInsufficientException implements Exception {
  StockInsufficientException({
    required this.message,
    required this.raw,
    required this.products,
    required this.options,
    required this.rawMaterials,
  });

  final String message;
  final Map<String, dynamic> raw;
  final List<StockConflictItem> products;
  final List<StockConflictItem> options;
  final List<StockConflictItem> rawMaterials;

  factory StockInsufficientException.fromResponse(Map<String, dynamic> json) {
    final insufficient = json['insufficient'];
    final map = insufficient is Map
        ? Map<String, dynamic>.from(insufficient)
        : <String, dynamic>{};

    return StockInsufficientException(
      message: (json['message'] ?? 'Beberapa stok tidak mencukupi.').toString(),
      raw: json,
      products: _parseItems(map['products'], 'product'),
      options: _parseItems(map['options'], 'option'),
      rawMaterials: _parseItems(map['raw_materials'], 'raw_material'),
    );
  }

  List<StockConflictItem> get allItems => [
        ...products,
        ...options,
        ...rawMaterials,
      ];

  @override
  String toString() => message;
}

List<StockConflictItem> _parseItems(dynamic value, String type) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => StockConflictItem.fromJson(
            Map<String, dynamic>.from(item),
            type,
          ))
      .toList();
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

String _fmt(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
