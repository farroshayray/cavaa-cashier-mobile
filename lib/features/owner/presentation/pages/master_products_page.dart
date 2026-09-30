import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';
import 'product_form_shared.dart';
import 'categories_page.dart';
import 'promotions_page.dart';
import '../widgets/dock_inset.dart';

const _brand = productBrand;
const _catalogAccent = productCatalogAccent;
const _bg = Color(0xFFF6F7F9);

class MasterProductsPage extends StatefulWidget {
  const MasterProductsPage({
    super.key,
    this.embedded = false,
    this.onChanged,
  });

  /// Tanpa Scaffold/AppBar/FAB — untuk di-embed di hub Produk.
  final bool embedded;

  /// Dipanggil setelah create/edit/delete sukses (supaya hub reload assignable).
  final VoidCallback? onChanged;

  @override
  State<MasterProductsPage> createState() => MasterProductsPageState();
}

class MasterProductsPageState extends State<MasterProductsPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;

  List<Map<String, dynamic>> get _filteredProducts {
    final selectedId = _selectedCategoryId;
    if (selectedId == null) return _products;
    return _products
        .where((p) => productCategoryIdOf(p) == selectedId)
        .toList();
  }

  List<({int id, String name, int count})> get _populatedCategories =>
      populatedProductCategories(
        products: _products,
        categories: _categories,
      );

  void _ensureValidCategorySelection() {
    final selected = _selectedCategoryId;
    if (selected == null) return;
    if (!_populatedCategories.any((c) => c.id == selected)) {
      _selectedCategoryId = null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> reload({bool silent = true}) => _load(silent: silent);

  Future<void> openCreate() => _openEditor();

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
      final data = await ownerApiOf(context).listMasterProducts();
      final list = data['products'];
      final cats = data['categories'];
      setState(() {
        _products = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _categories = cats is List
            ? cats
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _ensureValidCategorySelection();
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat katalog');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? product}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MasterProductEditorPage(product: product),
      ),
    );
    if (changed == true && mounted) {
      await context.read<AuthProvider>().refreshOwner();
      await _load(silent: true);
      widget.onChanged?.call();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final id = int.tryParse('${product['id'] ?? ''}');
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus dari katalog?'),
        content: Text(
          'Hapus “${product['name'] ?? 'produk'}” dari katalog? '
          'Produk di toko yang terhubung tidak ikut terhapus.',
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
      await ownerApiOf(context).deleteMasterProduct(id);
      await _load(silent: true);
      widget.onChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item katalog dihapus')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menghapus',
          ),
        ),
      );
    }
  }

  Widget _buildListBody({required EdgeInsets padding}) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _catalogAccent),
      );
    }
    return RefreshIndicator(
      color: _catalogAccent,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: padding,
        children: [
          if (!widget.embedded)
            Text(
              'Template produk bersama — edit di sini ikut ke toko yang memakai.',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: 12.5,
              ),
            ),
          if (_error != null) ...[
            if (!widget.embedded) const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          Text(
            'Katalog (${_filteredProducts.length})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (_populatedCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ProductCategoryTab(
                      label: 'Semua',
                      count: _products.length,
                      selected: _selectedCategoryId == null,
                      accent: _catalogAccent,
                      onTap: () =>
                          setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  ..._populatedCategories.map((c) {
                    final selected = c.id == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ProductCategoryTab(
                        label: c.name,
                        count: c.count,
                        selected: selected,
                        accent: _catalogAccent,
                        onTap: () =>
                            setState(() => _selectedCategoryId = c.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_products.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                'Belum ada item di katalog. Buat dulu, lalu aktifkan di Menu toko.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            )
          else if (_filteredProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                'Tidak ada item di kategori ini.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            ..._filteredProducts.map((p) {
              final thumb = resolveProductImageUrl(p['pictures']);
              final cat = p['category'];
              final catName = cat is Map ? cat['name']?.toString() : null;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () => _openEditor(product: p),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: thumb == null
                        ? Container(
                            width: 48,
                            height: 48,
                            color: _catalogAccent.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: _catalogAccent,
                            ),
                          )
                        : Image.network(
                            thumb,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['name']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _catalogAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Katalog',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _catalogAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          'Rp ${formatProductPrice(p['price'])}',
                          if (catName != null) catName,
                          if ((p['product_code']?.toString() ?? '').isNotEmpty)
                            p['product_code'].toString(),
                        ].join(' · '),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        catalogUsedInStoresLabel(p),
                        style: TextStyle(
                          fontSize: 12,
                          color: _catalogAccent.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    onPressed: () => _confirmDelete(p),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: _catalogAccent,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Stack(
        children: [
          _buildListBody(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100)
                .withBottomInset(context),
          ),
          if (_refreshing)
            const Positioned(
              top: 0,
              right: 16,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _catalogAccent,
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Katalog',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _catalogAccent,
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
      floatingActionButton: DockAwareFab(
        child: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _openEditor(),
          backgroundColor: _catalogAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah katalog'),
        ),
      ),
      body: _buildListBody(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100)
            .withBottomInset(context),
      ),
    );
  }
}

class MasterProductEditorPage extends StatefulWidget {
  const MasterProductEditorPage({super.key, this.product});

  final Map<String, dynamic>? product;

  @override
  State<MasterProductEditorPage> createState() =>
      _MasterProductEditorPageState();
}

class _MasterProductEditorPageState extends State<MasterProductEditorPage> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController(text: 'Umum');
  final _desc = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _promotions = [];
  List<MenuOptionGroup> _groups = [];
  List<Map<String, dynamic>> _existingImages = [];
  final List<String> _pickedImages = [];
  List<({int id, String name})> _usedInStores = [];
  int? _categoryId;
  int? _promotionId;
  bool _applyPrice = false;
  bool _applyPromo = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.product != null;
  int? get _id => int.tryParse('${widget.product?['id'] ?? ''}');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      Map<String, dynamic> data;
      if (_isEdit && _id != null) {
        data = await ownerApiOf(context).getMasterProduct(_id!);
      } else {
        data = await ownerApiOf(context).listMasterProducts();
      }
      final product = data['product'] is Map
          ? Map<String, dynamic>.from(data['product'] as Map)
          : widget.product;
      final cats = data['categories'];
      final promos = data['promotions'];
      setState(() {
        _categories = cats is List
            ? cats
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _promotions = promos is List
            ? promos
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        if (product != null) {
          _name.text = product['name']?.toString() ?? '';
          _price.text = product['price'] is num
              ? (product['price'] as num).toStringAsFixed(0)
              : (product['price']?.toString() ?? '');
          final cat = product['category'];
          _categoryId = product['category_id'] is int
              ? product['category_id'] as int
              : int.tryParse('${product['category_id'] ?? ''}');
          _category.text = cat is Map
              ? (cat['name']?.toString() ?? 'Umum')
              : 'Umum';
          _desc.text = product['description']?.toString() ?? '';
          _promotionId = product['promo_id'] is int
              ? product['promo_id'] as int
              : int.tryParse('${product['promo_id'] ?? ''}');
          _existingImages = pictureMaps(product['pictures']);
          _usedInStores = catalogUsedInStores(product);
          final opts = product['menu_options'];
          _groups = opts is List
              ? opts
                  .whereType<Map>()
                  .map(
                    (e) =>
                        MenuOptionGroup.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : [];
        } else {
          _usedInStores = [];
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat data produk';
        });
      }
    }
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text.replaceAll('.', '').trim());
    if (_name.text.trim().isEmpty || price == null) {
      setState(() => _error = 'Nama dan harga wajib diisi');
      return;
    }
    for (final g in _groups) {
      if (g.name.trim().isEmpty) {
        setState(() => _error = 'Nama grup opsi wajib diisi');
        return;
      }
      for (final o in g.options) {
        if (o.name.trim().isEmpty) {
          setState(() => _error = 'Nama opsi wajib diisi');
          return;
        }
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      final menuOptions = _groups.map((e) => e.toJson()).toList();
      if (_isEdit && _id != null) {
        await api.updateMasterProduct(
          id: _id!,
          name: _name.text.trim(),
          price: price,
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          categoryId: _categoryId,
          categoryName: _category.text.trim().isEmpty
              ? 'Umum'
              : _category.text.trim(),
          promotionId: _promotionId,
          clearPromotion: _promotionId == null,
          menuOptions: menuOptions,
          imagePaths: _pickedImages.isEmpty ? null : _pickedImages,
          keepImageFilenames: _existingImages
              .map((e) => e['filename']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList(),
          applyPriceAllOutlets: _applyPrice,
          applyPromotionAllOutlets: _applyPromo,
        );
      } else {
        await api.createMasterProduct(
          name: _name.text.trim(),
          price: price,
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          categoryId: _categoryId,
          categoryName: _category.text.trim().isEmpty
              ? 'Umum'
              : _category.text.trim(),
          promotionId: _promotionId,
          menuOptions: menuOptions,
          imagePaths: _pickedImages.isEmpty ? null : _pickedImages,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Master produk diperbarui' : 'Master produk dibuat',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Master Produk' : 'Tambah Master Produk',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
              children: [
                if (_isEdit) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _catalogAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _catalogAccent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dipakai di toko',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _catalogAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_usedInStores.isEmpty)
                          Text(
                            'Belum dipakai toko mana pun. Aktifkan dari Menu toko.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _usedInStores
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _catalogAccent
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _catalogAccent,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Nama produk',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CategorySelectWithManage(
                        categories: _categories,
                        categoryId: _categoryId,
                        categoryNameController: _category,
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _categoryId = v),
                        onCategoriesUpdated: (list) {
                          setState(() {
                            _categories = list;
                            if (_categoryId != null &&
                                !_categories.any(
                                  (c) =>
                                      int.tryParse('${c['id']}') ==
                                      _categoryId,
                                )) {
                              _categoryId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      PromotionSelectWithManage(
                        promotions: _promotions,
                        promotionId: _promotionId,
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _promotionId = v),
                        onPromotionsUpdated: (list) {
                          setState(() {
                            _promotions = list;
                            if (_promotionId != null &&
                                !_promotions.any(
                                  (p) =>
                                      int.tryParse('${p['id']}') ==
                                      _promotionId,
                                )) {
                              _promotionId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _desc,
                        enabled: !_saving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ProductImagePickerRow(
                        existing: _existingImages,
                        pickedPaths: _pickedImages,
                        enabled: !_saving,
                        onPick: () async {
                          final path = await pickProductImage();
                          if (path == null) return;
                          setState(() => _pickedImages.add(path));
                        },
                        onRemoveExisting: (i) =>
                            setState(() => _existingImages.removeAt(i)),
                        onRemovePicked: (i) =>
                            setState(() => _pickedImages.removeAt(i)),
                      ),
                      const SizedBox(height: 16),
                      ProductMenuOptionsEditor(
                        groups: _groups,
                        onChanged: (next) => setState(() => _groups = next),
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: _brand,
                          title: const Text(
                            'Terapkan harga ke semua toko',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          value: _applyPrice,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _applyPrice = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: _brand,
                          title: const Text(
                            'Terapkan promo ke semua toko',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          value: _applyPromo,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _applyPromo = v),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 14),
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
                                  _isEdit ? 'Simpan Perubahan' : 'Simpan Master',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
