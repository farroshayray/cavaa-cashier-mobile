import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _storeName;
  List<Map<String, dynamic>> _tables = [];
  List<String> _classes = [];
  String _filterClass = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterClass == 'all') return _tables;
    return _tables
        .where((t) => (t['table_class']?.toString() ?? '') == _filterClass)
        .toList();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      final data = await ownerApiOf(context).listTables();
      final list = data['tables'];
      final classes = data['table_classes'];
      setState(() {
        _tables = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _classes = classes is List
            ? classes.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : [];
        _storeName = data['selected_store_name']?.toString();
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat daftar meja');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? table}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TableEditorSheet(
        table: table,
        existingClasses: _classes,
      ),
    );
    if (changed == true && mounted) {
      await _load(silent: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> table) async {
    final id = int.tryParse('${table['id']}') ?? 0;
    if (id <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus meja?'),
        content: Text(
          'Hapus meja ${table['table_no'] ?? ''} '
          '(${table['table_class'] ?? '-'})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ownerApiOf(context).deleteTable(id);
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meja dihapus')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menghapus meja',
          ),
        ),
      );
    }
  }

  Future<void> _showBarcode(Map<String, dynamic> table) async {
    final id = int.tryParse('${table['id']}') ?? 0;
    if (id <= 0) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _brand),
      ),
    );

    try {
      final data = await ownerApiOf(context).getTableBarcode(id);
      if (!mounted) return;
      Navigator.of(context).pop(); // loading

      final b64 = data['barcode_png_base64']?.toString() ?? '';
      if (b64.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR tidak tersedia')),
        );
        return;
      }

      final bytes = base64Decode(b64);
      await showDialog<void>(
        context: context,
        builder: (ctx) => _BarcodeDialog(
          bytes: bytes,
          tableNo: table['table_no']?.toString() ?? '-',
          tableClass: table['table_class']?.toString() ?? '-',
          qrUrl: data['qr_url']?.toString(),
          storeName: _storeName ?? table['store_name']?.toString() ?? 'Toko',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal generate QR meja')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeLabel = _storeName ?? 'Toko terpilih';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'QR Meja',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Meja',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: () => _load(silent: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: _brand,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                      storeLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_tables.length} meja · buat, edit, dan generate QR',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_classes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('Semua (${_tables.length})'),
                                selected: _filterClass == 'all',
                                selectedColor: _brand.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _filterClass == 'all'
                                      ? _brand
                                      : Colors.black87,
                                ),
                                onSelected: (_) =>
                                    setState(() => _filterClass = 'all'),
                              ),
                            ),
                            ..._classes.map((c) {
                              final count = _tables
                                  .where(
                                    (t) =>
                                        (t['table_class']?.toString() ?? '') ==
                                        c,
                                  )
                                  .length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('$c ($count)'),
                                  selected: _filterClass == c,
                                  selectedColor: _brand.withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _filterClass == c
                                        ? _brand
                                        : Colors.black87,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _filterClass = c),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  if (_error != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  if (_filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_restaurant_outlined,
                                size: 48,
                                color: _brand.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada meja',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tambah meja untuk generate QR order pelanggan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final table = _filtered[index];
                          return _TableCard(
                            table: table,
                            onEdit: () => _openEditor(table: table),
                            onQr: () => _showBarcode(table),
                            onDelete: () => _confirmDelete(table),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.onEdit,
    required this.onQr,
    required this.onDelete,
  });

  final Map<String, dynamic> table;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final available = (table['status']?.toString() ?? '') == 'available';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_rounded,
                    color: _brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meja ${table['table_no'] ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${table['table_class'] ?? '-'}'
                        ' · ${table['table_code'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? const Color(0xFF1B7F4E).withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          available ? 'Available' : 'Not available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: available
                                ? const Color(0xFF1B7F4E)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onQr,
                  tooltip: 'Lihat QR',
                  style: IconButton.styleFrom(foregroundColor: _brand),
                  icon: const Icon(Icons.qr_code_2_rounded),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'qr') onQr();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'qr', child: Text('Generate QR')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarcodeDialog extends StatelessWidget {
  const _BarcodeDialog({
    required this.bytes,
    required this.tableNo,
    required this.tableClass,
    required this.storeName,
    this.qrUrl,
  });

  final Uint8List bytes;
  final String tableNo;
  final String tableClass;
  final String storeName;
  final String? qrUrl;

  Future<void> _share(BuildContext context) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/qr-meja-${tableNo.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'QR Meja $tableNo · $storeName',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Meja $tableNo',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$storeName · $tableClass',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
            if ((qrUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                qrUrl!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _share(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Bagikan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableEditorSheet extends StatefulWidget {
  const _TableEditorSheet({
    required this.existingClasses,
    this.table,
  });

  final Map<String, dynamic>? table;
  final List<String> existingClasses;

  @override
  State<_TableEditorSheet> createState() => _TableEditorSheetState();
}

class _TableEditorSheetState extends State<_TableEditorSheet> {
  late final TextEditingController _tableNo;
  late final TextEditingController _description;
  late final TextEditingController _newClass;
  late String _status;
  String? _selectedClass;
  bool _useNewClass = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.table != null;

  @override
  void initState() {
    super.initState();
    final t = widget.table;
    _tableNo = TextEditingController(text: t?['table_no']?.toString() ?? '');
    _description =
        TextEditingController(text: t?['description']?.toString() ?? '');
    _newClass = TextEditingController();
    _status = t?['status']?.toString() ?? 'available';
    final existing = t?['table_class']?.toString();
    if (existing != null &&
        existing.isNotEmpty &&
        widget.existingClasses.contains(existing)) {
      _selectedClass = existing;
    } else if (existing != null && existing.isNotEmpty) {
      _useNewClass = true;
      _newClass.text = existing;
    } else if (widget.existingClasses.isNotEmpty) {
      _selectedClass = widget.existingClasses.first;
    } else {
      _useNewClass = true;
    }
  }

  @override
  void dispose() {
    _tableNo.dispose();
    _description.dispose();
    _newClass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tableNo.text.trim().isEmpty) {
      setState(() => _error = 'Nomor meja wajib diisi');
      return;
    }

    final tableClass = _useNewClass
        ? _newClass.text.trim()
        : (_selectedClass ?? '').trim();
    if (tableClass.isEmpty) {
      setState(() => _error = 'Kelas meja wajib diisi');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      if (_isEdit) {
        final id = int.tryParse('${widget.table!['id']}') ?? 0;
        await api.updateTable(
          id: id,
          tableNo: _tableNo.text.trim(),
          tableClass: _useNewClass ? tableClass : tableClass,
          newTableClass: _useNewClass ? tableClass : null,
          description: _description.text.trim(),
          status: _status,
        );
      } else {
        await api.createTable(
          tableNo: _tableNo.text.trim(),
          tableClass: tableClass,
          newTableClass: _useNewClass ? tableClass : null,
          description: _description.text.trim(),
          status: _status,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan meja';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan meja');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit meja' : 'Tambah meja',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tableNo,
                      decoration: InputDecoration(
                        labelText: 'Nomor meja',
                        hintText: 'Contoh: 1 / A1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _useNewClass,
                      activeTrackColor: _brand.withValues(alpha: 0.45),
                      activeThumbColor: _brand,
                      title: const Text(
                        'Buat kelas baru',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onChanged: (v) => setState(() => _useNewClass = v),
                    ),
                    if (_useNewClass)
                      TextField(
                        controller: _newClass,
                        decoration: InputDecoration(
                          labelText: 'Nama kelas',
                          hintText: 'Contoh: Indoor / VIP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                    else if (widget.existingClasses.isNotEmpty)
                      DropdownButtonFormField<String>(
                        key: ValueKey('class-$_selectedClass'),
                        initialValue: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Kelas meja',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: widget.existingClasses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClass = v),
                      )
                    else
                      Text(
                        'Belum ada kelas. Aktifkan "Buat kelas baru".',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$_status'),
                      initialValue: _status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'not_available',
                          child: Text('Not available'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? 'available'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Simpan Meja',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
