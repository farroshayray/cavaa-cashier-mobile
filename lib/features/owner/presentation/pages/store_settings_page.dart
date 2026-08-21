import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';
import 'payment_methods_page.dart';
import 'store_image_crop_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

String? resolveStoreImageUrl(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.path.contains('/storage/')) {
      final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
      final q = uri.hasQuery ? '?${uri.query}' : '';
      return '$base${uri.path}$q';
    }
    return value;
  }
  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = value.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/storage/$clean';
}

/// Settings for the currently selected store (like web outlet edit).
class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _contactPerson = TextEditingController();
  final _contactPhone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _instagram = TextEditingController();
  final _gmaps = TextEditingController();
  final _wifiUser = TextEditingController();
  final _wifiPass = TextEditingController();
  final _ppn = TextEditingController(text: '0');

  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _storeId;
  String? _storeSlug;
  String? _partnerCode;

  bool _isActive = true;
  bool _isCashierActive = true;
  bool _isOpenbill = false;
  bool _isWifiShown = false;
  bool _isPpnActive = false;
  int _cashRoundingUnit = 0;

  List<Map<String, dynamic>> _paymentMethods = [];
  Set<int> _selectedPaymentIds = {};

  final _picker = ImagePicker();
  String? _logoUrl;
  String? _backgroundUrl;
  String? _logoPath;
  String? _backgroundPath;
  bool _removeLogo = false;
  bool _removeBackground = false;

  /// All sections start collapsed.
  final Set<String> _expandedSections = {};

  void _toggleSection(String key) {
    setState(() {
      if (_expandedSections.contains(key)) {
        _expandedSections.remove(key);
      } else {
        _expandedSections.add(key);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _province.dispose();
    _contactPerson.dispose();
    _contactPhone.dispose();
    _whatsapp.dispose();
    _instagram.dispose();
    _gmaps.dispose();
    _wifiUser.dispose();
    _wifiPass.dispose();
    _ppn.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final storeId = auth.owner?.onboarding?.selectedStoreId ??
        auth.owner?.selectedPartnerId;

    if (storeId == null) {
      setState(() {
        _loading = false;
        _error = 'Belum ada toko terpilih. Pilih toko di menu utama dulu.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _storeId = storeId;
    });

    try {
      final data = await ownerApiOf(context).getStore(storeId);
      final store = data['store'];
      final methods = data['payment_methods'];
      final assigned = data['assigned_payment_method_ids'];

      if (store is! Map) {
        throw Exception('Invalid store payload');
      }

      final s = Map<String, dynamic>.from(store);
      _name.text = s['name']?.toString() ?? '';
      _address.text = s['address']?.toString() ?? '';
      _city.text = s['city']?.toString() ?? '';
      _province.text = s['province']?.toString() ?? '';
      _contactPerson.text = s['contact_person']?.toString() ?? '';
      _contactPhone.text = s['contact_phone']?.toString() ?? '';
      _whatsapp.text = s['whatsapp']?.toString() ?? '';
      _instagram.text = s['instagram']?.toString() ?? '';
      _gmaps.text = s['gmaps_url']?.toString() ?? '';
      _wifiUser.text = s['user_wifi']?.toString() ?? '';
      _wifiPass.text = s['pass_wifi']?.toString() ?? '';
      _ppn.text = '${s['ppn'] ?? 0}';
      _storeSlug = s['slug']?.toString();
      _partnerCode = s['partner_code']?.toString();
      _logoUrl = resolveStoreImageUrl(
        s['logo_url']?.toString() ?? s['logo']?.toString(),
      );
      _backgroundUrl = resolveStoreImageUrl(
        s['background_url']?.toString() ??
            s['background_picture']?.toString(),
      );
      _logoPath = null;
      _backgroundPath = null;
      _removeLogo = false;
      _removeBackground = false;

      setState(() {
        _isActive = s['is_active'] == true || s['is_active'] == 1;
        _isCashierActive =
            s['is_cashier_active'] == true || s['is_cashier_active'] == 1;
        _isOpenbill = s['is_openbill'] == true || s['is_openbill'] == 1;
        _isWifiShown =
            s['is_wifi_shown'] == true || s['is_wifi_shown'] == 1;
        _isPpnActive =
            s['is_ppn_active'] == true || s['is_ppn_active'] == 1;
        _cashRoundingUnit =
            int.tryParse('${s['cash_rounding_unit'] ?? 0}') ?? 0;
        _paymentMethods = methods is List
            ? methods
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _selectedPaymentIds = assigned is List
            ? assigned
                .map((e) => int.tryParse('$e') ?? 0)
                .where((e) => e > 0)
                .toSet()
            : <int>{};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat pengaturan toko';
      });
    }
  }

  Future<void> _refreshPaymentMethods() async {
    if (_storeId == null) return;
    try {
      final data = await ownerApiOf(context).getStore(_storeId!);
      final methods = data['payment_methods'];
      final list = methods is List
          ? methods
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      final availableIds = list
          .map((m) => int.tryParse('${m['id']}') ?? 0)
          .where((id) => id > 0)
          .toSet();
      if (!mounted) return;
      setState(() {
        _paymentMethods = list;
        _selectedPaymentIds =
            _selectedPaymentIds.where(availableIds.contains).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat ulang metode bayar')),
      );
    }
  }

  Future<void> _openManagePaymentMethods() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
    );
    if (!mounted) return;
    await context.read<AuthProvider>().refreshOwner();
    await _refreshPaymentMethods();
  }

  Future<String?> _pickAndCrop({
    required String title,
    required double aspectRatio,
    required int maxWidth,
    required int maxHeight,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null || !mounted) return null;

    final croppedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => StoreImageCropPage(
          sourcePath: picked.path,
          title: title,
          aspectRatio: aspectRatio,
          outputWidth: maxWidth,
          outputHeight: maxHeight,
        ),
      ),
    );
    return croppedPath;
  }

  Future<void> _pickLogo() async {
    final path = await _pickAndCrop(
      title: 'Crop Logo (1:1)',
      aspectRatio: 1,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (path == null || !mounted) return;
    setState(() {
      _logoPath = path;
      _removeLogo = false;
    });
  }

  Future<void> _pickBackground() async {
    final path = await _pickAndCrop(
      title: 'Crop Background (16:9)',
      aspectRatio: 16 / 9,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (path == null || !mounted) return;
    setState(() {
      _backgroundPath = path;
      _removeBackground = false;
    });
  }

  Future<void> _save() async {
    if (_storeId == null) return;
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Nama dan alamat wajib diisi');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ownerApiOf(context).updateStore(
        storeId: _storeId!,
        name: _name.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        province: _province.text.trim(),
        isActive: _isActive,
        isCashierActive: _isCashierActive,
        isOpenbill: _isOpenbill,
        userWifi: _wifiUser.text.trim(),
        passWifi: _wifiPass.text.trim(),
        isWifiShown: _isWifiShown,
        isPpnActive: _isPpnActive,
        ppn: num.tryParse(_ppn.text.trim()) ?? 0,
        cashRoundingUnit: _cashRoundingUnit,
        contactPerson: _contactPerson.text.trim(),
        contactPhone: _contactPhone.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        gmapsUrl: _gmaps.text.trim(),
        instagram: _instagram.text.trim(),
        manualPaymentIds: _selectedPaymentIds.toList(),
        logoPath: _logoPath,
        backgroundPath: _backgroundPath,
        removeLogo: _removeLogo && _logoPath == null,
        removeBackground: _removeBackground && _backgroundPath == null,
      );
      await context.read<AuthProvider>().refreshOwner();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan toko disimpan')),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan pengaturan';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan pengaturan');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _paymentTypeLabel(String? type) {
    switch (type) {
      case 'manual_ewallet':
        return 'E-Wallet';
      case 'manual_qris':
        return 'QRIS';
      case 'manual_tf':
        return 'Transfer Bank';
      default:
        return 'Transfer';
    }
  }

  IconData _paymentTypeIcon(String type) {
    switch (type) {
      case 'manual_ewallet':
        return Icons.account_balance_wallet_rounded;
      case 'manual_qris':
        return Icons.qr_code_2_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _paymentTypeColor(String type) {
    switch (type) {
      case 'manual_ewallet':
        return const Color(0xFF0B6E4F);
      case 'manual_qris':
        return const Color(0xFF1D4ED8);
      default:
        return _brand;
    }
  }

  List<Widget> _buildGroupedPaymentMethods() {
    const order = ['manual_tf', 'manual_ewallet', 'manual_qris'];
    final widgets = <Widget>[];

    for (final type in order) {
      final items = _paymentMethods
          .where((m) => (m['payment_type']?.toString() ?? '') == type)
          .toList();
      if (items.isEmpty) continue;

      final color = _paymentTypeColor(type);
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 14));
      }
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(_paymentTypeIcon(type), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _paymentTypeLabel(type),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 4));
      for (final m in items) {
        final id = int.tryParse('${m['id']}') ?? 0;
        widgets.add(
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedPaymentIds.contains(id),
            activeColor: _brand,
            title: Text(
              m['provider_name']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              m['provider_account_name']?.toString() ?? '-',
            ),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedPaymentIds.add(id);
                } else {
                  _selectedPaymentIds.remove(id);
                }
              });
            },
          ),
        );
      }
    }

    // Any unknown payment_type still shown under "Lainnya".
    final known = order.toSet();
    final others = _paymentMethods
        .where((m) => !known.contains(m['payment_type']?.toString() ?? ''))
        .toList();
    if (others.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(
        Text(
          'Lainnya',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      );
      for (final m in others) {
        final id = int.tryParse('${m['id']}') ?? 0;
        widgets.add(
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedPaymentIds.contains(id),
            activeColor: _brand,
            title: Text(
              m['provider_name']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${_paymentTypeLabel(m['payment_type']?.toString())}'
              ' · ${m['provider_account_name'] ?? '-'}',
            ),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedPaymentIds.add(id);
                } else {
                  _selectedPaymentIds.remove(id);
                }
              });
            },
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Toko',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving || _loading || _storeId == null ? null : _save,
            child: Text(
              'Simpan',
              style: TextStyle(
                color: _saving || _loading || _storeId == null
                    ? Colors.white54
                    : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _storeId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error ?? 'Belum ada toko terpilih.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _SectionCard(
                      title: 'Informasi toko',
                      subtitle: [
                        if ((_partnerCode ?? '').isNotEmpty)
                          'Kode: $_partnerCode',
                        if ((_storeSlug ?? '').isNotEmpty) 'Slug: $_storeSlug',
                      ].join(' · '),
                      expanded: _expandedSections.contains('info'),
                      onToggle: () => _toggleSection('info'),
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Nama toko',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _address,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _city,
                            decoration: const InputDecoration(
                              labelText: 'Kota',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _province,
                            decoration: const InputDecoration(
                              labelText: 'Provinsi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Logo & background',
                      subtitle: 'Crop sama seperti web: logo 1:1 (800×800), background 16:9 (1920×1080)',
                      expanded: _expandedSections.contains('branding'),
                      onToggle: () => _toggleSection('branding'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Logo toko',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rasio 1:1 · output 800×800',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: _StoreImagePreview(
                              width: 140,
                              height: 140,
                              borderRadius: 70,
                              localPath: _removeLogo ? null : _logoPath,
                              networkUrl: _removeLogo ? null : _logoUrl,
                              placeholderIcon: Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickLogo,
                                  icon: const Icon(Icons.crop_rounded),
                                  label: const Text('Pilih & crop'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _saving ||
                                        (_logoPath == null &&
                                            (_logoUrl == null || _logoUrl!.isEmpty))
                                    ? null
                                    : () => setState(() {
                                          _logoPath = null;
                                          _removeLogo = true;
                                        }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Background',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rasio 16:9 · output 1920×1080',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StoreImagePreview(
                            width: double.infinity,
                            height: 160,
                            borderRadius: 14,
                            localPath:
                                _removeBackground ? null : _backgroundPath,
                            networkUrl:
                                _removeBackground ? null : _backgroundUrl,
                            placeholderIcon: Icons.image_outlined,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickBackground,
                                  icon: const Icon(Icons.crop_rounded),
                                  label: const Text('Pilih & crop'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _saving ||
                                        (_backgroundPath == null &&
                                            (_backgroundUrl == null ||
                                                _backgroundUrl!.isEmpty))
                                    ? null
                                    : () => setState(() {
                                          _backgroundPath = null;
                                          _removeBackground = true;
                                        }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Kontak & sosial',
                      expanded: _expandedSections.contains('contact'),
                      onToggle: () => _toggleSection('contact'),
                      child: Column(
                        children: [
                          TextField(
                            controller: _contactPerson,
                            decoration: const InputDecoration(
                              labelText: 'Contact person',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contactPhone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'No. telepon',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _whatsapp,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _instagram,
                            decoration: const InputDecoration(
                              labelText: 'Instagram',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _gmaps,
                            decoration: const InputDecoration(
                              labelText: 'Link Google Maps',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Status operasional',
                      expanded: _expandedSections.contains('status'),
                      onToggle: () => _toggleSection('status'),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isActive,
                            activeTrackColor: _brand.withValues(alpha: 0.45),
                            activeThumbColor: _brand,
                            title: const Text(
                              'Toko aktif',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isCashierActive,
                            activeTrackColor: _brand.withValues(alpha: 0.45),
                            activeThumbColor: _brand,
                            title: const Text(
                              'Kasir aktif',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onChanged: (v) =>
                                setState(() => _isCashierActive = v),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isOpenbill,
                            activeTrackColor: _brand.withValues(alpha: 0.45),
                            activeThumbColor: _brand,
                            title: const Text(
                              'Open bill',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onChanged: (v) => setState(() => _isOpenbill = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Pajak & pembulatan',
                      expanded: _expandedSections.contains('tax'),
                      onToggle: () => _toggleSection('tax'),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isPpnActive,
                            activeTrackColor: _brand.withValues(alpha: 0.45),
                            activeThumbColor: _brand,
                            title: const Text(
                              'Aktifkan PPN',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onChanged: (v) => setState(() => _isPpnActive = v),
                          ),
                          if (_isPpnActive) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ppn,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'PPN (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: ValueKey('rounding-$_cashRoundingUnit'),
                            initialValue: _cashRoundingUnit,
                            decoration: const InputDecoration(
                              labelText: 'Pembulatan cash',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Tidak ada'),
                              ),
                              DropdownMenuItem(
                                value: 100,
                                child: Text('Rp 100'),
                              ),
                              DropdownMenuItem(
                                value: 500,
                                child: Text('Rp 500'),
                              ),
                              DropdownMenuItem(
                                value: 1000,
                                child: Text('Rp 1.000'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _cashRoundingUnit = v ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'WiFi toko',
                      expanded: _expandedSections.contains('wifi'),
                      onToggle: () => _toggleSection('wifi'),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isWifiShown,
                            activeTrackColor: _brand.withValues(alpha: 0.45),
                            activeThumbColor: _brand,
                            title: const Text(
                              'Tampilkan WiFi di struk/QR',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onChanged: (v) =>
                                setState(() => _isWifiShown = v),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _wifiUser,
                            decoration: const InputDecoration(
                              labelText: 'SSID / nama WiFi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _wifiPass,
                            decoration: const InputDecoration(
                              labelText: 'Password WiFi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Metode bayar toko ini',
                      subtitle:
                          'Pilih metode dari katalog owner untuk outlet ini.',
                      expanded: _expandedSections.contains('payments'),
                      onToggle: () => _toggleSection('payments'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : _openManagePaymentMethods,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _brand,
                                side: BorderSide(
                                  color: _brand.withValues(alpha: 0.35),
                                ),
                              ),
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text(
                                'Kelola Metode Bayar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_paymentMethods.isEmpty)
                            Text(
                              'Belum ada metode bayar. Ketuk “Kelola Metode Bayar” untuk menambah.',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            )
                          else
                            ..._buildGroupedPaymentMethods(),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
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
                            : const Text(
                                'Simpan Pengaturan',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.expanded,
    required this.onToggle,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if ((subtitle ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: child,
                ),
              ],
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _StoreImagePreview extends StatelessWidget {
  const _StoreImagePreview({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholderIcon,
    this.localPath,
    this.networkUrl,
  });

  final double width;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;
  final String? localPath;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (localPath != null && localPath!.isNotEmpty) {
      child = Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        width: width == double.infinity ? null : width,
        height: height,
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: networkUrl!,
        fit: BoxFit.cover,
        width: width == double.infinity ? null : width,
        height: height,
        placeholder: (_, __) => Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _brand),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _placeholder() {
    return Container(
      color: _brand.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: _brand.withValues(alpha: 0.55), size: 36),
    );
  }
}
