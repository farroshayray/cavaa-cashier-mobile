import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'master_products_page.dart';
import 'owner_home_page.dart';
import 'product_form_shared.dart';
import 'categories_page.dart';

const _brand = productBrand;
const _bg = Color(0xFFF6F7F9);

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _masters = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _promotions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final api = ownerApiOf(context);
      final results = await Future.wait([
        api.listProducts(),
        api.listMasterProducts(),
      ]);

      final storeData = results[0];
      final masterData = results[1];
      final storeList = storeData['products'];
      final masterList = masterData['products'];
      final cats = storeData['categories'] ?? masterData['categories'];
      final promos = storeData['promotions'] ?? masterData['promotions'];

      setState(() {
        _products = storeList is List
            ? storeList
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _masters = masterList is List
            ? masterList
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
        _promotions = promos is List
            ? promos
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat produk toko');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Set<int> get _assignedMasterIds => _products
      .map((p) => int.tryParse('${p['master_product_id'] ?? ''}'))
      .whereType<int>()
      .toSet();

  List<Map<String, dynamic>> get _assignableMasters {
    final assigned = _assignedMasterIds;
    return _masters.where((m) {
      final id = int.tryParse('${m['id'] ?? ''}');
      return id != null && !assigned.contains(id);
    }).toList();
  }

  Future<void> _openEditor({Map<String, dynamic>? product}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StoreProductEditorPage(
          product: product,
          assignableMasters: _assignableMasters,
          categories: _categories,
          promotions: _promotions,
        ),
      ),
    );
    if (changed == true && mounted) {
      await context.read<AuthProvider>().refreshOwner();
      await _load(silent: true);
    }
  }

  Future<void> _openMasterManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MasterProductsPage()),
    );
    if (mounted) await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<AuthProvider>().owner;
    final selectedId =
        owner?.onboarding?.selectedStoreId ?? owner?.selectedPartnerId;
    final matchedStores = owner?.onboarding?.stores
            .where((s) => s.id == selectedId)
            .toList() ??
        const [];
    final storeName =
        matchedStores.isNotEmpty ? matchedStores.first.name : 'Toko terpilih';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Produk Toko',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
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
        label: const Text('Tambah produk'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: () => _load(silent: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    'Toko: $storeName',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openMasterManager,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: BorderSide(color: _brand.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text(
                      'Kelola Master Produk',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buat produk baru, ambil dari katalog, atau ketuk produk untuk edit.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Produk di toko (${_products.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
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
                        'Belum ada produk. Ketuk “Tambah produk” atau kelola master dulu.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  else
                    ..._products.map((p) {
                      final cat = p['category'];
                      final catName =
                          cat is Map ? cat['name']?.toString() : null;
                      final thumb = resolveProductImageUrl(p['pictures']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _openEditor(product: p),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: thumb == null
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    color: _brand.withValues(alpha: 0.08),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: _brand,
                                    ),
                                  )
                                : Image.network(
                                    thumb,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          title: Text(
                            p['name']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [
                              'Rp ${formatProductPrice(p['price'])}',
                              if (catName != null) catName,
                              if ((p['product_code']?.toString() ?? '')
                                  .isNotEmpty)
                                p['product_code'].toString(),
                            ].join(' · '),
                          ),
                          trailing: Icon(
                            (p['is_active'] == true || p['is_active'] == 1)
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_filled_rounded,
                            color: (p['is_active'] == true ||
                                    p['is_active'] == 1)
                                ? const Color(0xFF0B6E4F)
                                : Colors.black38,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class StoreProductEditorPage extends StatefulWidget {
  const StoreProductEditorPage({
    super.key,
    this.product,
    required this.assignableMasters,
    required this.categories,
    required this.promotions,
  });

  final Map<String, dynamic>? product;
  final List<Map<String, dynamic>> assignableMasters;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> promotions;

  @override
  State<StoreProductEditorPage> createState() => _StoreProductEditorPageState();
}

class _StoreProductEditorPageState extends State<StoreProductEditorPage> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController(text: 'Umum');
  final _desc = TextEditingController();
  final _code = TextEditingController();

  Map<String, dynamic>? _selectedMaster;
  List<MenuOptionGroup> _groups = [];
  List<Map<String, dynamic>> _existingImages = [];
  final List<String> _pickedImages = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _promotions = [];

  int? _categoryId;
  int? _promotionId;
  bool _alwaysAvailable = true;
  bool _isActive = true;
  bool _isHot = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.product != null;
  bool get _fromCatalog => _selectedMaster != null;
  bool get _identityLocked => _isEdit || _fromCatalog;
  int? get _productId => int.tryParse('${widget.product?['id'] ?? ''}');

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
    _promotions = [...widget.promotions];
    if (_isEdit) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _desc.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final id = _productId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await ownerApiOf(context).getProduct(id);
      final product = data['product'] is Map
          ? Map<String, dynamic>.from(data['product'] as Map)
          : Map<String, dynamic>.from(widget.product!);
      final cats = data['categories'];
      final promos = data['promotions'];
      _applyProduct(product);
      setState(() {
        if (cats is List) {
          _categories = cats
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (promos is List) {
          _promotions = promos
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        _loading = false;
      });
    } catch (_) {
      if (widget.product != null) _applyProduct(widget.product!);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyProduct(Map<String, dynamic> product) {
    final cat = product['category'];
    _name.text = product['name']?.toString() ?? '';
    _price.text = product['price'] is num
        ? (product['price'] as num).toStringAsFixed(0)
        : (product['price']?.toString() ?? '');
    _category.text =
        cat is Map ? (cat['name']?.toString() ?? 'Umum') : 'Umum';
    _categoryId = cat is Map
        ? int.tryParse('${cat['id'] ?? ''}')
        : int.tryParse('${product['category_id'] ?? ''}');
    _desc.text = product['description']?.toString() ?? '';
    _code.text = product['product_code']?.toString() ?? '';
    _promotionId = product['promo_id'] is int
        ? product['promo_id'] as int
        : int.tryParse('${product['promo_id'] ?? ''}');
    _alwaysAvailable =
        product['always_available'] == true || product['always_available'] == 1;
    _isActive = product['is_active'] == true || product['is_active'] == 1;
    _isHot =
        product['is_hot_product'] == true || product['is_hot_product'] == 1;
    _existingImages = pictureMaps(product['pictures']);
    final opts = product['menu_options'];
    _groups = opts is List
        ? opts
            .whereType<Map>()
            .map((e) => MenuOptionGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : [];
  }

  void _applyMaster(Map<String, dynamic> master) {
    final cat = master['category'];
    setState(() {
      _selectedMaster = master;
      _name.text = master['name']?.toString() ?? '';
      _price.text = master['price'] is num
          ? (master['price'] as num).toStringAsFixed(0)
          : (master['price']?.toString() ?? '');
      _category.text =
          cat is Map ? (cat['name']?.toString() ?? 'Umum') : 'Umum';
      _categoryId = master['category_id'] is int
          ? master['category_id'] as int
          : int.tryParse('${master['category_id'] ?? ''}');
      _desc.text = master['description']?.toString() ?? '';
      _code.text = master['product_code']?.toString() ?? '';
      _promotionId = master['promo_id'] is int
          ? master['promo_id'] as int
          : int.tryParse('${master['promo_id'] ?? ''}');
      _existingImages = pictureMaps(master['pictures']);
      final opts = master['menu_options'];
      _groups = opts is List
          ? opts
              .whereType<Map>()
              .map(
                (e) => MenuOptionGroup.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : [];
      _pickedImages.clear();
      _error = null;
    });
  }

  void _clearMaster() {
    setState(() {
      _selectedMaster = null;
      _name.clear();
      _price.clear();
      _category.text = 'Umum';
      _categoryId = null;
      _desc.clear();
      _code.clear();
      _promotionId = null;
      _groups = [];
      _existingImages = [];
      _pickedImages.clear();
      _error = null;
    });
  }

  Future<void> _pickFromCatalog() async {
    final masters = widget.assignableMasters;
    if (masters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada katalog yang bisa diambil. Buat produk baru atau kelola master dulu.',
          ),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Ambil dari katalog',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: masters.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = masters[i];
                    return ListTile(
                      title: Text(
                        m['name']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Rp ${formatProductPrice(m['price'])}'
                        '${(m['product_code']?.toString() ?? '').isNotEmpty ? ' · ${m['product_code']}' : ''}',
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
      if (selected != null) {
      // Prefer full detail if available from list; else fetch.
      final id = int.tryParse('${selected['id'] ?? ''}');
      if (id != null &&
          (selected['menu_options'] == null ||
              selected['menu_options'] is! List)) {
        try {
          final data = await ownerApiOf(context).getMasterProduct(id);
          if (!mounted) return;
          final product = data['product'];
          if (product is Map) {
            _applyMaster(Map<String, dynamic>.from(product));
            return;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      _applyMaster(selected);
    }
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text.replaceAll('.', '').trim());
    if (!_identityLocked && _name.text.trim().isEmpty) {
      setState(() => _error = 'Nama produk wajib diisi');
      return;
    }
    if (price == null) {
      setState(() => _error = 'Harga wajib diisi');
      return;
    }
    if (!_identityLocked) {
      for (final g in _groups) {
        if (g.name.trim().isEmpty) {
          setState(() => _error = 'Nama grup opsi wajib diisi');
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
      if (_isEdit && _productId != null) {
        final optionSettings = <Map<String, dynamic>>[];
        for (final g in _groups) {
          for (final o in g.options) {
            if (o.optionId == null) continue;
            optionSettings.add({
              'option_id': o.optionId,
              'always_available': o.alwaysAvailable,
            });
          }
        }
        await api.updateProduct(
          id: _productId!,
          price: price,
          alwaysAvailable: _alwaysAvailable,
          isActive: _isActive,
          isHotProduct: _isHot,
          promotionId: _promotionId,
          clearPromotion: _promotionId == null,
          optionSettings: optionSettings,
        );
      } else if (_fromCatalog) {
        final masterId = int.tryParse('${_selectedMaster!['id'] ?? ''}');
        if (masterId == null) {
          setState(() {
            _error = 'Produk katalog tidak valid';
            _saving = false;
          });
          return;
        }
        await api.assignProductsToStore(
          [masterId],
          price: price,
          alwaysAvailable: _alwaysAvailable,
          isActive: _isActive,
          isHotProduct: _isHot,
          promotionId: _promotionId,
        );
      } else {
        await api.createProduct(
          name: _name.text.trim(),
          price: price,
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          categoryId: _categoryId,
          categoryName: _category.text.trim().isEmpty
              ? 'Umum'
              : _category.text.trim(),
          promotionId: _promotionId,
          alwaysAvailable: _alwaysAvailable,
          isActive: _isActive,
          isHotProduct: _isHot,
          menuOptions: _groups.map((e) => e.toJson()).toList(),
          imagePaths: _pickedImages.isEmpty ? null : _pickedImages,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Produk toko diperbarui'
                : _fromCatalog
                    ? 'Produk dari katalog ditambahkan'
                    : 'Produk berhasil dibuat',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan produk';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan produk');
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
          _isEdit ? 'Edit Produk Toko' : 'Tambah Produk Toko',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (!_isEdit) ...[
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickFromCatalog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: BorderSide(color: _brand.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text(
                      'Ambil dari katalog',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_fromCatalog) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _brand.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: _brand),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dari katalog: ${_selectedMaster!['name'] ?? '-'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _brand,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _saving ? null : _clearMaster,
                            child: const Text('Lepas'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
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
                        enabled: !_identityLocked && !_saving,
                        decoration: InputDecoration(
                          labelText: 'Nama produk',
                          border: const OutlineInputBorder(),
                          helperText: _identityLocked
                              ? 'Terkunci (dari master)'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_identityLocked)
                        TextField(
                          controller: _category,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                            helperText: 'Terkunci (dari master)',
                          ),
                        )
                      else
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
                      if (_identityLocked) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _code,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Kode produk',
                            border: OutlineInputBorder(),
                            helperText: 'Terkunci',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga toko',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: _promotionId,
                        decoration: const InputDecoration(
                          labelText: 'Promo (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tanpa promo'),
                          ),
                          ..._promotions.map((p) {
                            final id = int.tryParse('${p['id']}');
                            return DropdownMenuItem<int?>(
                              value: id,
                              child: Text(p['name']?.toString() ?? '-'),
                            );
                          }),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _promotionId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _desc,
                        enabled: !_identityLocked && !_saving,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          border: const OutlineInputBorder(),
                          helperText: _identityLocked
                              ? 'Terkunci (dari master)'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!_identityLocked)
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
                        )
                      else if (_existingImages.isNotEmpty) ...[
                        const Text(
                          'Gambar (dari master)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ProductImagePickerRow(
                          existing: _existingImages,
                          pickedPaths: const [],
                          enabled: false,
                          onPick: () {},
                          onRemoveExisting: (_) {},
                          onRemovePicked: (_) {},
                        ),
                      ],
                      const SizedBox(height: 12),
                      ProductMenuOptionsEditor(
                        groups: _groups,
                        readOnly: _identityLocked,
                        showOptionStock: _isEdit,
                        onChanged: (next) => setState(() => _groups = next),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _brand,
                        title: const Text(
                          'Selalu tersedia',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: _alwaysAvailable,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _alwaysAvailable = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _brand,
                        title: const Text(
                          'Aktif di toko ini',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: _isActive,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _isActive = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: _brand,
                        title: const Text(
                          'Produk unggulan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: _isHot,
                        onChanged:
                            _saving ? null : (v) => setState(() => _isHot = v),
                      ),
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
                                  _isEdit
                                      ? 'Simpan Perubahan'
                                      : _fromCatalog
                                          ? 'Tambahkan ke Toko'
                                          : 'Simpan Produk',
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
