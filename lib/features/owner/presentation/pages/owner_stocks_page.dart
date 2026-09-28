import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class OwnerStocksPage extends StatefulWidget {
  const OwnerStocksPage({super.key});

  @override
  State<OwnerStocksPage> createState() => _OwnerStocksPageState();
}

class _OwnerStocksPageState extends State<OwnerStocksPage> {
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _units = [];
  String _location = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({String? location}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ownerApiOf(context).listStocks(
        location: location ?? (_location.isEmpty ? null : _location),
      );
      if (!mounted) return;
      final stocks = (data['stocks'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final locations = (data['locations'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final units = (data['units'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _stocks = stocks;
        _locations = locations;
        _units = units;
        _location = data['location']?.toString() ?? _location;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(e);
      });
    }
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Gagal memuat stok';
  }

  String get _locationName {
    for (final loc in _locations) {
      if (loc['id']?.toString() == _location) {
        return loc['name']?.toString() ?? 'Lokasi';
      }
    }
    return 'Lokasi';
  }

  Future<void> _addIngredient() async {
    final name = TextEditingController();
    int? unitId = _units.isEmpty ? null : int.tryParse('${_units.first['id']}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Tambah bahan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _field('Nama bahan'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: unitId,
                    decoration: _field('Satuan'),
                    items: [
                      for (final unit in _units)
                        DropdownMenuItem(
                          value: int.tryParse('${unit['id']}'),
                          child: Text(unit['name']?.toString() ?? '-'),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => unitId = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bahan yang sama ikut dibuat di gudang dan setiap toko.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: _primaryButton(compact: true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;
    if (name.text.trim().isEmpty || unitId == null) {
      _snack('Nama dan satuan wajib diisi');
      return;
    }
    try {
      await ownerApiOf(context).createStock(
        stockName: name.text.trim(),
        unitId: unitId!,
      );
      if (!mounted) return;
      _snack('Bahan ditambahkan ke gudang dan setiap toko');
      await _load();
    } on DioException catch (e) {
      _snack(_message(e));
    }
  }

  Future<void> _delete(Map<String, dynamic> stock) async {
    final id = int.tryParse('${stock['id']}');
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus bahan?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          '“${stock['stock_name']}” akan dihapus di semua toko.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ownerApiOf(context).deleteStock(id);
      if (!mounted) return;
      await _load();
    } on DioException catch (e) {
      _snack(_message(e));
    }
  }

  Future<void> _movement(String type) async {
    if (_stocks.isEmpty) {
      _snack('Belum ada bahan di lokasi ini');
      return;
    }
    final qty = TextEditingController();
    final price = TextEditingController();
    var stock = _stocks.first;
    var direction = 'in';
    var locationTo = _locations
        .map((e) => e['id']?.toString() ?? '')
        .firstWhere((id) => id.isNotEmpty && id != _location, orElse: () => '');
    final title = type == 'in'
        ? 'Stok masuk'
        : type == 'transfer'
            ? 'Transfer'
            : 'Penyesuaian';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              final unitName = stock['display_unit_name']?.toString() ?? '';
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _locationName,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: int.tryParse('${stock['id']}'),
                    decoration: _field('Bahan'),
                    items: [
                      for (final item in _stocks)
                        DropdownMenuItem(
                          value: int.tryParse('${item['id']}'),
                          child: Text(item['stock_name']?.toString() ?? '-'),
                        ),
                    ],
                    onChanged: (id) {
                      Map<String, dynamic>? next;
                      for (final item in _stocks) {
                        if (int.tryParse('${item['id']}') == id) next = item;
                      }
                      if (next != null) setLocal(() => stock = next!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _field(
                      'Jumlah${unitName.isEmpty ? '' : ' ($unitName)'}',
                    ),
                  ),
                  if (type == 'in') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: _field('Total harga beli (opsional)'),
                    ),
                  ],
                  if (type == 'adjustment') ...[
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _brand.withValues(alpha: 0.12),
                        selectedForegroundColor: _brand,
                      ),
                      segments: const [
                        ButtonSegment(value: 'in', label: Text('Tambah'), icon: Icon(Icons.add_rounded)),
                        ButtonSegment(value: 'out', label: Text('Kurangi'), icon: Icon(Icons.remove_rounded)),
                      ],
                      selected: {direction},
                      onSelectionChanged: (v) => setLocal(() => direction = v.first),
                    ),
                  ],
                  if (type == 'transfer') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: locationTo.isEmpty ? null : locationTo,
                      decoration: _field('Lokasi tujuan'),
                      items: [
                        for (final loc in _locations)
                          if ((loc['id']?.toString() ?? '') != _location)
                            DropdownMenuItem(
                              value: loc['id']?.toString(),
                              child: Text(loc['name']?.toString() ?? '-'),
                            ),
                      ],
                      onChanged: (v) => setLocal(() => locationTo = v ?? ''),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: _primaryButton(),
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (saved != true || !mounted) return;
    final amount = num.tryParse(qty.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _snack('Jumlah wajib diisi');
      return;
    }
    final unitId = int.tryParse('${stock['display_unit_id']}');
    final stockId = int.tryParse('${stock['id']}');
    if (unitId == null || stockId == null) {
      _snack('Satuan bahan belum diatur');
      return;
    }
    final body = <String, dynamic>{
      'movement_type': type,
      'notes': '',
      'items': [
        {
          'stock_id': '$stockId',
          'unit_id': unitId,
          'quantity': amount,
          if (type == 'in') 'unit_price': num.tryParse(price.text.trim()) ?? 0,
          if (type == 'adjustment') 'direction': direction,
        },
      ],
    };
    if (type == 'in') {
      body['location_to'] = _location;
      body['category'] = 'purchase';
    } else if (type == 'adjustment') {
      body['location'] = _location;
      body['category'] = 'audit_adjustment';
    } else {
      if (locationTo.isEmpty) {
        _snack('Pilih lokasi tujuan');
        return;
      }
      body['location_from'] = _location;
      body['location_to'] = locationTo;
      body['category'] = 'transfer';
    }
    try {
      await ownerApiOf(context).submitStockMovement(body);
      if (!mounted) return;
      _snack('Mutasi stok tercatat');
      await _load();
    } on DioException catch (e) {
      _snack(_message(e));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _qty(dynamic value) {
    if (value is num) {
      final text = value.toStringAsFixed(2);
      return text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Stok', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: () => _load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  if (_locations.isNotEmpty) _locationPicker(),
                  const SizedBox(height: 14),
                  _actionRow(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'Bahan',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_stocks.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_stocks.isEmpty)
                    _emptyState()
                  else
                    ..._stocks.map(_stockCard),
                ],
              ),
            ),
    );
  }

  Widget _locationPicker() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _locations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final loc = _locations[index];
          final id = loc['id']?.toString() ?? '';
          final selected = id == _location;
          return ChoiceChip(
            label: Text(loc['name']?.toString() ?? '-'),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
            selectedColor: _brand,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? _brand : Colors.black.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            onSelected: (_) {
              if (id.isEmpty || id == _location) return;
              setState(() => _location = id);
              _load(location: id);
            },
          );
        },
      ),
    );
  }

  Widget _actionRow() {
    const actions = [
      (id: 'add', icon: Icons.add_rounded, label: 'Bahan'),
      (id: 'in', icon: Icons.south_rounded, label: 'Masuk'),
      (id: 'adjustment', icon: Icons.tune_rounded, label: 'Sesuaikan'),
      (id: 'transfer', icon: Icons.swap_horiz_rounded, label: 'Transfer'),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (actions[i].id == 'add') {
                    _addIngredient();
                  } else {
                    _movement(actions[i].id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(actions[i].icon, color: _brand, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actions[i].label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stockCard(Map<String, dynamic> stock) {
    final unit = stock['display_unit_name']?.toString() ?? '';
    final available = _qty(stock['available_quantity']);
    final physical = _qty(stock['quantity']);
    final empty = (num.tryParse(available) ?? 0) <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: empty
                    ? const Color(0xFFFEE4E2)
                    : const Color(0xFFE8F6EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: empty ? const Color(0xFFB42318) : const Color(0xFF0B6E4F),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock['stock_name']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empty ? 'Habis' : 'Tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      color: empty
                          ? const Color(0xFFB42318)
                          : Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  if (!empty && physical != available)
                    Text(
                      'Fisik $physical $unit'.trim(),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  available,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: empty ? const Color(0xFFB42318) : Colors.black,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: () => _delete(stock),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _brand),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada bahan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambah bahan dulu, lalu catat stok masuk di lokasi ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _field(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
    ),
  );
}

ButtonStyle _primaryButton({bool compact = false}) {
  return FilledButton.styleFrom(
    backgroundColor: _brand,
    foregroundColor: Colors.white,
    minimumSize: compact ? null : const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
  );
}
