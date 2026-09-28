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
    final draft = await Navigator.of(context).push<_MovementDraft>(
      MaterialPageRoute(
        builder: (_) => _StockMovementPage(
          type: type,
          locationName: _locationName,
          stocks: _stocks,
          locations: _locations
              .where((loc) => (loc['id']?.toString() ?? '') != _location)
              .map((loc) => Map<String, dynamic>.from(loc))
              .toList(),
        ),
      ),
    );
    if (draft == null || !mounted) return;
    final body = <String, dynamic>{
      'movement_type': type,
      'notes': '',
      'items': draft.items,
    };
    if (type == 'in') {
      body['location_to'] = _location;
      body['category'] = 'purchase';
    } else if (type == 'adjustment') {
      body['location'] = _location;
      body['category'] = 'audit_adjustment';
    } else if (type == 'out') {
      body['location_from'] = _location;
      body['category'] = draft.outCategory;
    } else if (type == 'opname') {
      body['location'] = _location;
    } else {
      body['location_from'] = _location;
      body['location_to'] = draft.locationTo;
      body['category'] = 'transfer';
    }
    try {
      await ownerApiOf(context).submitStockMovement(body);
      if (!mounted) return;
      _snack(draft.items.length == 1
          ? 'Mutasi stok tercatat'
          : '${draft.items.length} bahan tercatat');
      await _load();
    } on DioException catch (e) {
      _snack(_message(e));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(dynamic value) {
    final number = value is num ? value.round() : int.tryParse('$value') ?? 0;
    final text = number.abs().toString();
    final buffer = StringBuffer(number < 0 ? '-' : '');
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }
    return 'Rp $buffer';
  }

  String _qty(dynamic value) {
    if (value is num) {
      final text = value.toStringAsFixed(2);
      return text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value?.toString() ?? '0';
  }

  Future<void> _setMinimum(Map<String, dynamic> stock) async {
    final current = stock['min_quantity'];
    final input = TextEditingController(
      text: current == null ? '' : _qty(current),
    );
    final unit = stock['display_unit_name']?.toString() ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stok minimum', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: input,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _field('Minimum${unit.isEmpty ? '' : ' ($unit)'}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: _primaryButton(),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final raw = input.text.trim().replaceAll(',', '.');
    final id = int.tryParse('${stock['id']}');
    final unitId = int.tryParse('${stock['display_unit_id']}');
    if (id == null) return;
    try {
      await ownerApiOf(context).setStockMinimum(
        id: id,
        quantity: raw.isEmpty ? null : num.tryParse(raw),
        unitId: unitId,
      );
      if (!mounted) return;
      await _load();
    } on DioException catch (e) {
      _snack(_message(e));
    }
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
      (id: 'out', icon: Icons.north_rounded, label: 'Keluar'),
      (id: 'adjustment', icon: Icons.tune_rounded, label: 'Sesuaikan'),
      (id: 'opname', icon: Icons.fact_check_rounded, label: 'Opname'),
      (id: 'transfer', icon: Icons.swap_horiz_rounded, label: 'Transfer'),
    ];
    Widget tile(int i) {
      return Expanded(
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
      );
    }

    return Column(
      children: [
        Row(children: [tile(0), const SizedBox(width: 8), tile(1), const SizedBox(width: 8), tile(2)]),
        const SizedBox(height: 8),
        Row(children: [tile(3), const SizedBox(width: 8), tile(4), const SizedBox(width: 8), tile(5)]),
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
                  const SizedBox(height: 4),
                  Text(
                    'Rata-rata ${_money(stock['average_price'])}${unit.isEmpty ? '' : '/$unit'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    'Nilai ${_money(stock['inventory_value'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  if (stock['below_minimum'] == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Di bawah stok minimum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB42318),
                        ),
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
              onPressed: () => _setMinimum(stock),
              icon: Icon(
                Icons.flag_outlined,
                color: stock['below_minimum'] == true
                    ? const Color(0xFFB42318)
                    : Colors.black.withValues(alpha: 0.35),
              ),
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

class _MovementDraft {
  const _MovementDraft({
    required this.items,
    required this.outCategory,
    required this.locationTo,
  });

  final List<Map<String, dynamic>> items;
  final String outCategory;
  final String locationTo;
}

class _MoveLine {
  int? stockId;
  final qty = TextEditingController();
  final price = TextEditingController();

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class _StockMovementPage extends StatefulWidget {
  const _StockMovementPage({
    required this.type,
    required this.locationName,
    required this.stocks,
    required this.locations,
  });

  final String type;
  final String locationName;
  final List<Map<String, dynamic>> stocks;
  final List<Map<String, dynamic>> locations;

  @override
  State<_StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<_StockMovementPage> {
  final _lines = <_MoveLine>[_MoveLine()];
  var _direction = 'in';
  var _outCategory = 'damaged';
  var _locationTo = '';

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.type) {
        'in' => 'Stok masuk',
        'transfer' => 'Transfer',
        'out' => 'Stok keluar',
        'opname' => 'Stok opname',
        _ => 'Penyesuaian',
      };

  String get _hint => switch (widget.type) {
        'in' => 'Isi jumlah dan total belanja untuk tiap bahan.',
        'opname' => 'Isi hasil hitung fisik tiap bahan.',
        'out' => 'Alasan keluar berlaku untuk semua bahan di bawah.',
        'adjustment' => 'Arah penyesuaian berlaku untuk semua bahan di bawah.',
        _ => 'Pilih lokasi tujuan, lalu isi bahan yang dipindahkan.',
      };

  bool get _showPurchase =>
      widget.type == 'in' || (widget.type == 'adjustment' && _direction == 'in');

  Map<String, dynamic>? _stockById(int? id) {
    for (final stock in widget.stocks) {
      if (int.tryParse('${stock['id']}') == id) return stock;
    }
    return null;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save() {
    if (widget.type == 'transfer' && _locationTo.isEmpty) {
      _snack('Pilih lokasi tujuan');
      return;
    }
    final items = <Map<String, dynamic>>[];
    final seen = <int>{};
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final qtyText = line.qty.text.trim();
      final priceText = line.price.text.trim();
      final blank = line.stockId == null && qtyText.isEmpty && priceText.isEmpty;
      if (blank && _lines.length > 1) continue;
      final label = 'Bahan ${i + 1}';
      if (line.stockId == null) {
        _snack('$label belum dipilih');
        return;
      }
      if (!seen.add(line.stockId!)) {
        _snack('$label sudah ada di daftar');
        return;
      }
      final amount = num.tryParse(qtyText.replaceAll(',', '.'));
      if (amount == null || (widget.type == 'opname' ? amount < 0 : amount <= 0)) {
        _snack('Jumlah $label belum diisi');
        return;
      }
      final unitId = int.tryParse('${_stockById(line.stockId)?['display_unit_id']}');
      if (unitId == null) {
        _snack('Satuan $label belum diatur');
        return;
      }
      items.add({
        'stock_id': '${line.stockId}',
        'unit_id': unitId,
        'quantity': amount,
        if (_showPurchase) 'unit_price': num.tryParse(priceText) ?? 0,
        if (widget.type == 'adjustment') 'direction': _direction,
      });
    }
    if (items.isEmpty) {
      _snack('Tambah minimal satu bahan');
      return;
    }
    Navigator.pop(
      context,
      _MovementDraft(
        items: items,
        outCategory: _outCategory,
        locationTo: _locationTo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            widget.locationName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(_hint, style: TextStyle(color: Colors.black.withValues(alpha: 0.55))),
          if (widget.type == 'out') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _outCategory,
              decoration: _field('Alasan keluar'),
              items: const [
                DropdownMenuItem(value: 'damaged', child: Text('Rusak')),
                DropdownMenuItem(value: 'expired', child: Text('Kedaluwarsa')),
                DropdownMenuItem(value: 'internal_use', child: Text('Pemakaian internal')),
              ],
              onChanged: (value) => setState(() => _outCategory = value ?? 'damaged'),
            ),
          ],
          if (widget.type == 'adjustment') ...[
            const SizedBox(height: 14),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _brand.withValues(alpha: 0.12),
                selectedForegroundColor: _brand,
              ),
              segments: const [
                ButtonSegment(value: 'in', label: Text('Tambah'), icon: Icon(Icons.add_rounded)),
                ButtonSegment(value: 'out', label: Text('Kurangi'), icon: Icon(Icons.remove_rounded)),
              ],
              selected: {_direction},
              onSelectionChanged: (value) => setState(() => _direction = value.first),
            ),
          ],
          if (widget.type == 'transfer') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _locationTo.isEmpty ? null : _locationTo,
              decoration: _field('Lokasi tujuan'),
              items: [
                for (final loc in widget.locations)
                  DropdownMenuItem(
                    value: loc['id']?.toString(),
                    child: Text(loc['name']?.toString() ?? '-'),
                  ),
              ],
              onChanged: (value) => setState(() => _locationTo = value ?? ''),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < _lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _MoveLineCard(
              index: i,
              line: _lines[i],
              stocks: widget.stocks,
              takenIds: {
                for (final other in _lines)
                  if (!identical(other, _lines[i]) && other.stockId != null) other.stockId!,
              },
              showPurchase: _showPurchase,
              quantityLabel: widget.type == 'opname' ? 'Hasil hitung' : 'Jumlah',
              canRemove: _lines.length > 1,
              onChanged: () => setState(() {}),
              onRemove: () {
                final line = _lines.removeAt(i);
                line.dispose();
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _lines.add(_MoveLine())),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brand,
              side: BorderSide(color: _brand.withValues(alpha: 0.35)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah bahan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            style: _primaryButton(),
            child: Text('Simpan ${_lines.length} bahan'),
          ),
        ],
      ),
    );
  }
}

class _MoveLineCard extends StatelessWidget {
  const _MoveLineCard({
    required this.index,
    required this.line,
    required this.stocks,
    required this.takenIds,
    required this.showPurchase,
    required this.quantityLabel,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _MoveLine line;
  final List<Map<String, dynamic>> stocks;
  final Set<int> takenIds;
  final bool showPurchase;
  final String quantityLabel;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  Map<String, dynamic>? get _stock {
    for (final stock in stocks) {
      if (int.tryParse('${stock['id']}') == line.stockId) return stock;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stock;
    final unit = stock?['display_unit_name']?.toString() ?? '';
    final qtyValue = num.tryParse(line.qty.text.trim().replaceAll(',', '.')) ?? 0;
    final totalBuy = num.tryParse(line.price.text.trim().replaceAll(',', '.')) ?? 0;
    final perUnit = qtyValue > 0 ? totalBuy / qtyValue : 0;
    final choices = [
      for (final item in stocks)
        if (!takenIds.contains(int.tryParse('${item['id']}')))
          item,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _brand),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stock?['stock_name']?.toString().trim().isNotEmpty == true
                      ? stock!['stock_name'].toString()
                      : 'Bahan ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: _brand),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(line.stockId),
            isExpanded: true,
            initialValue: line.stockId,
            decoration: _field('Bahan'),
            items: [
              for (final item in choices)
                DropdownMenuItem(
                  value: int.tryParse('${item['id']}'),
                  child: Text(
                    item['stock_name']?.toString() ?? '-',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              line.stockId = id;
              onChanged();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: line.qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: _field(
              unit.isEmpty ? quantityLabel : '$quantityLabel ($unit)',
            ),
          ),
          if (showPurchase) ...[
            const SizedBox(height: 10),
            TextField(
              controller: line.price,
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
              decoration: _field('Total harga beli (opsional)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga per ${unit.isEmpty ? 'satuan' : unit}: ${_rupiah(perUnit)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _rupiah(dynamic value) {
  final number = value is num ? value.round() : int.tryParse('$value') ?? 0;
  final text = number.abs().toString();
  final buffer = StringBuffer(number < 0 ? '-' : '');
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
    buffer.write(text[i]);
  }
  return 'Rp $buffer';
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
