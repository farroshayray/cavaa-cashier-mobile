import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/config/env.dart';
import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

String? resolveCategoryImageUrl(dynamic imagesOrPath) {
  String? path;
  if (imagesOrPath is String) {
    path = imagesOrPath;
  } else if (imagesOrPath is Map) {
    path = imagesOrPath['path']?.toString();
  }
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = path.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/$clean';
}

/// Opens category manager and returns refreshed list when closed.
Future<List<Map<String, dynamic>>?> openCategoryManager(
  BuildContext context,
) async {
  return Navigator.of(context).push<List<Map<String, dynamic>>>(
    MaterialPageRoute(builder: (_) => const CategoriesPage()),
  );
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _loading = true;
  bool _refreshing = false;
  bool _reordering = false;
  String? _error;
  String _query = '';
  List<Map<String, dynamic>> _categories = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false, String? q}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      final data = await ownerApiOf(context).listCategories(q: q ?? _query);
      final list = data['categories'];
      setState(() {
        _categories = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat kategori');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? category}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryEditorSheet(category: category),
    );
    if (changed == true && mounted) {
      await _load(silent: true, q: '');
      _search.clear();
      _query = '';
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> category) async {
    final id = int.tryParse('${category['id'] ?? ''}');
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          'Hapus “${category['name'] ?? category['category_name'] ?? 'kategori'}”? '
          'Kategori yang masih dipakai produk tidak bisa dihapus.',
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
      await ownerApiOf(context).deleteCategory(id);
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori dihapus')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menghapus kategori',
          ),
        ),
      );
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_query.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kosongkan pencarian dulu untuk mengubah urutan'),
        ),
      );
      return;
    }
    final next = [..._categories];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    setState(() {
      _categories = next;
      _reordering = true;
    });

    try {
      final orders = <Map<String, dynamic>>[];
      for (var i = 0; i < next.length; i++) {
        final id = int.tryParse('${next[i]['id'] ?? ''}');
        if (id == null) continue;
        orders.add({'id': id, 'order': i + 1});
      }
      final data = await ownerApiOf(context).reorderCategories(orders);
      final list = data['categories'];
      if (list is List && mounted) {
        setState(() {
          _categories = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan urutan')),
        );
        await _load(silent: true);
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  void _popWithResult() {
    Navigator.of(context).pop(_categories);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text(
            'Kelola Kategori',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithResult,
          ),
          actions: [
            if (_refreshing || _reordering)
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
          onPressed: _loading ? null : () => _openEditor(),
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Tambah kategori',
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFAE1504),
                                    Color(0xFF7A0E03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pengelompokan produk',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.98),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Susun kategori agar menu kasir rapi. '
                                          'Tahan & geser untuk ubah urutan.',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.78),
                                            fontSize: 12.5,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${_categories.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Cari kategori…',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _search.clear();
                                          _query = '';
                                          _load(silent: true, q: '');
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              onSubmitted: (v) {
                                _query = v.trim();
                                _load(silent: true, q: _query);
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_categories.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  color: _brand,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _query.isEmpty
                                    ? 'Belum ada kategori'
                                    : 'Tidak ada hasil',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _query.isEmpty
                                    ? 'Tambah kategori seperti “Makanan”, “Minuman”, atau “Snack”.'
                                    : 'Coba kata kunci lain.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverReorderableList(
                          itemCount: _categories.length,
                          onReorderItem: _onReorder,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, _) {
                                final t = Curves.easeInOut.transform(
                                  animation.value,
                                );
                                return Material(
                                  elevation: 2 + (6 * t),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.transparent,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.2),
                                  child: child,
                                );
                              },
                            );
                          },
                          itemBuilder: (context, index) {
                            final c = _categories[index];
                            final name = c['name']?.toString() ??
                                c['category_name']?.toString() ??
                                '-';
                            final desc = c['description']?.toString() ?? '';
                            final imageUrl = resolveCategoryImageUrl(
                              c['images'] ?? c['image_path'],
                            );
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('cat-${c['id']}-$index'),
                              index: index,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      4,
                                      8,
                                    ),
                                    onTap: () => _openEditor(category: c),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.drag_indicator_rounded,
                                          color: Colors.black
                                              .withValues(alpha: 0.28),
                                        ),
                                        const SizedBox(width: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: imageUrl == null
                                              ? Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: _brand.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style:
                                                          const TextStyle(
                                                        color: _brand,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      desc.isEmpty
                                          ? 'Urutan ${index + 1} · Ketuk untuk edit'
                                          : desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      onPressed: () => _confirmDelete(c),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: _brand,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.category});

  final Map<String, dynamic>? category;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String? _existingImageUrl;
  String? _pickedPath;
  bool _removeImage = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.category != null;
  int? get _id => int.tryParse('${widget.category?['id'] ?? ''}');

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(
      text: c?['name']?.toString() ?? c?['category_name']?.toString() ?? '',
    );
    _desc = TextEditingController(text: c?['description']?.toString() ?? '');
    _existingImageUrl = resolveCategoryImageUrl(
      c?['images'] ?? c?['image_path'],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _pickedPath = file.path;
      _removeImage = false;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama kategori wajib diisi');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      if (_isEdit && _id != null) {
        await api.updateCategory(
          id: _id!,
          name: name,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          imagePath: _pickedPath,
          removeImage: _removeImage && _pickedPath == null,
        );
      } else {
        await api.createCategory(
          name: name,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          imagePath: _pickedPath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan kategori';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan kategori');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final showExisting =
        !_removeImage && _pickedPath == null && _existingImageUrl != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isEdit ? 'Edit kategori' : 'Tambah kategori',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nama kategori dipakai di produk dan tampilan kasir.',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _pickedPath != null
                            ? Image.file(
                                File(_pickedPath!),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : showExisting
                                ? CachedNetworkImage(
                                    imageUrl: _existingImageUrl!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 96,
                                    height: 96,
                                    color: _brand.withValues(alpha: 0.08),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      color: _brand,
                                      size: 34,
                                    ),
                                  ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: _brand,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showExisting || _pickedPath != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _pickedPath = null;
                              _removeImage = true;
                            }),
                    child: const Text('Hapus gambar'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama kategori',
                    hintText: 'Contoh: Minuman',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desc,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
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
                            _isEdit ? 'Simpan Perubahan' : 'Simpan Kategori',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category dropdown + "Kelola kategori" action for product forms.
class CategorySelectWithManage extends StatelessWidget {
  const CategorySelectWithManage({
    super.key,
    required this.categories,
    required this.categoryId,
    required this.categoryNameController,
    required this.onChanged,
    required this.onCategoriesUpdated,
    this.enabled = true,
  });

  final List<Map<String, dynamic>> categories;
  final int? categoryId;
  final TextEditingController categoryNameController;
  final ValueChanged<int?> onChanged;
  final ValueChanged<List<Map<String, dynamic>>> onCategoriesUpdated;
  final bool enabled;

  Future<void> _manage(BuildContext context) async {
    final result = await openCategoryManager(context);
    if (result == null) return;
    onCategoriesUpdated(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = categories.isNotEmpty;
    final validId = categoryId != null &&
            categories.any((c) => int.tryParse('${c['id']}') == categoryId)
        ? categoryId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? () => _manage(context) : null,
              style: TextButton.styleFrom(
                foregroundColor: _brand,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text(
                'Kelola kategori',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (hasCategories)
          DropdownButtonFormField<int>(
            key: ValueKey(
              'cat-dd-${categories.map((c) => c['id']).join('-')}-$validId',
            ),
            initialValue: validId,
            decoration: const InputDecoration(
              hintText: 'Pilih kategori',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((c) {
                  final id = int.tryParse('${c['id']}');
                  if (id == null) return null;
                  final name =
                      c['name']?.toString() ?? c['category_name']?.toString();
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name ?? '-'),
                  );
                })
                .whereType<DropdownMenuItem<int>>()
                .toList(),
            onChanged: enabled
                ? (v) {
                    onChanged(v);
                    final match = categories.firstWhere(
                      (c) => int.tryParse('${c['id']}') == v,
                      orElse: () => {},
                    );
                    categoryNameController.text =
                        match['name']?.toString() ??
                            match['category_name']?.toString() ??
                            'Umum';
                  }
                : null,
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada kategori.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat kategori dulu, atau isi nama manual di bawah.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryNameController,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Nama kategori baru',
                    hintText: 'Contoh: Umum',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
