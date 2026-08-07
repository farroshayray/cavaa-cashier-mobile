import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<Map<String, dynamic>> _methods = [];

  /// Sections start collapsed; user expands as needed.
  final Set<String> _expandedTypes = {};

  static const _sections = <String>[
    'manual_tf',
    'manual_ewallet',
    'manual_qris',
  ];

  List<Map<String, dynamic>> _byType(String type) {
    return _methods
        .where((m) => (m['payment_type']?.toString() ?? '') == type)
        .toList();
  }

  void _toggleSection(String type) {
    setState(() {
      if (_expandedTypes.contains(type)) {
        _expandedTypes.remove(type);
      } else {
        _expandedTypes.add(type);
      }
    });
  }

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
      final data = await ownerApiOf(context).listPaymentMethods();
      final list = data['payment_methods'];
      setState(() {
        _methods = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _error = null;
        // Keep current expand/collapse state on refresh.
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat metode pembayaran');
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

  Future<void> _openEditor({
    Map<String, dynamic>? method,
    String? prefillType,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentEditorSheet(
        method: method,
        prefillType: prefillType,
      ),
    );
    if (changed == true && mounted) {
      await context.read<AuthProvider>().refreshOwner();
      await _load(silent: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> method) async {
    final id = int.tryParse('${method['id']}') ?? 0;
    if (id <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus metode?'),
        content: Text(
          'Hapus ${method['provider_name'] ?? 'metode ini'}? '
          'Tindakan ini tidak dapat dibatalkan.',
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
      await ownerApiOf(context).deletePaymentMethod(id);
      await context.read<AuthProvider>().refreshOwner();
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metode pembayaran dihapus')),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Metode Bayar',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
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
          'Tambah',
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
                      child: _HeaderCard(count: _methods.length),
                    ),
                  ),
                  if (_error != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final type = _sections[index];
                          final items = _byType(type);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _sections.length - 1 ? 0 : 12,
                            ),
                            child: _PaymentTypeSection(
                              type: type,
                              methods: items,
                              expanded: _expandedTypes.contains(type),
                              onToggle: () => _toggleSection(type),
                              onAdd: () => _openEditor(prefillType: type),
                              onEdit: (method) => _openEditor(method: method),
                              onDelete: _confirmDelete,
                            ),
                          );
                        },
                        childCount: _sections.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katalog pembayaran owner',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.98),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? 'Kelola metode Transfer, E-Wallet, dan QRIS di bawah.'
                      : '$count metode tersimpan di katalog',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeSection extends StatelessWidget {
  const _PaymentTypeSection({
    required this.type,
    required this.methods,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String type;
  final List<Map<String, dynamic>> methods;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(type);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, color: meta.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            methods.isEmpty
                                ? 'Belum ada metode'
                                : '${methods.length} metode',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onAdd,
                      tooltip: 'Tambah ${meta.label}',
                      style: IconButton.styleFrom(
                        foregroundColor: meta.color,
                        backgroundColor: meta.color.withValues(alpha: 0.10),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                    ),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(width: 6),
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
                if (methods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Belum ada ${meta.label.toLowerCase()}.',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onAdd,
                          style: TextButton.styleFrom(foregroundColor: meta.color),
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < methods.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _PaymentMethodCard(
                            method: methods[i],
                            compact: true,
                            onEdit: () => onEdit(methods[i]),
                            onDelete: () => onDelete(methods[i]),
                          ),
                        ],
                      ],
                    ),
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

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final Map<String, dynamic> method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = method['payment_type']?.toString() ?? '';
    final meta = _typeMeta(type);
    final active = method['is_active'] == true || method['is_active'] == 1;
    final qrisUrl = _resolveQrisUrl(method);

    return Material(
      color: compact ? const Color(0xFFF8F9FB) : Colors.white,
      borderRadius: BorderRadius.circular(compact ? 14 : 18),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 12 : 14, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(meta.icon, color: meta.color),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              method['provider_name']?.toString() ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1B7F4E)
                                      .withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              active ? 'Aktif' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? const Color(0xFF1B7F4E)
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: meta.color,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        method['provider_account_name']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                      if (type != 'manual_qris' &&
                          (method['provider_account_no']
                                  ?.toString()
                                  .isNotEmpty ??
                              false)) ...[
                        const SizedBox(height: 2),
                        Text(
                          method['provider_account_no'].toString(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black.withValues(alpha: 0.45),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      if (type == 'manual_qris' && qrisUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: qrisUrl,
                            height: compact ? 72 : 88,
                            width: compact ? 72 : 88,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              height: compact ? 72 : 88,
                              width: compact ? 72 : 88,
                              color: Colors.black.withValues(alpha: 0.04),
                            ),
                            errorWidget: (_, _, _) => Container(
                              height: compact ? 72 : 88,
                              width: compact ? 72 : 88,
                              color: Colors.black.withValues(alpha: 0.04),
                              child: const Icon(Icons.qr_code_2_rounded),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
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

class _TypeMeta {
  const _TypeMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_TypeMeta _typeMeta(String type) {
  switch (type) {
    case 'manual_ewallet':
      return const _TypeMeta(
        label: 'E-Wallet',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF0B6E4F),
      );
    case 'manual_qris':
      return const _TypeMeta(
        label: 'QRIS',
        icon: Icons.qr_code_2_rounded,
        color: Color(0xFF1D4ED8),
      );
    case 'manual_tf':
    default:
      return const _TypeMeta(
        label: 'Transfer Bank',
        icon: Icons.account_balance_rounded,
        color: _brand,
      );
  }
}

String? _resolveQrisUrl(Map<String, dynamic> method) {
  final full = method['qris_image_full_url']?.toString();
  if (full != null && full.isNotEmpty) return full;

  final path = method['qris_image_url']?.toString();
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = path.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/storage/$clean';
}

class _PaymentEditorSheet extends StatefulWidget {
  const _PaymentEditorSheet({this.method, this.prefillType});

  final Map<String, dynamic>? method;
  final String? prefillType;

  @override
  State<_PaymentEditorSheet> createState() => _PaymentEditorSheetState();
}

class _PaymentEditorSheetState extends State<_PaymentEditorSheet> {
  late final TextEditingController _providerName;
  late final TextEditingController _accountName;
  late final TextEditingController _accountNo;
  late final TextEditingController _additionalInfo;
  late String _type;
  late bool _isActive;
  String? _existingQrisUrl;
  String? _pickedImagePath;
  bool _removeQris = false;
  bool _saving = false;
  String? _error;
  final _picker = ImagePicker();

  bool get _isEdit =>
      widget.method != null && widget.method!['id'] != null;

  @override
  void initState() {
    super.initState();
    final m = _isEdit ? widget.method : null;
    _type = m?['payment_type']?.toString() ??
        widget.prefillType ??
        'manual_tf';
    _providerName = TextEditingController(
      text: m?['provider_name']?.toString() ?? '',
    );
    _accountName = TextEditingController(
      text: m?['provider_account_name']?.toString() ?? '',
    );
    _accountNo = TextEditingController(
      text: m?['provider_account_no']?.toString() ?? '',
    );
    _additionalInfo = TextEditingController(
      text: m?['additional_info']?.toString() ?? '',
    );
    _isActive = m == null
        ? true
        : (m['is_active'] == true || m['is_active'] == 1);
    _existingQrisUrl = m == null ? null : _resolveQrisUrl(m);
  }

  @override
  void dispose() {
    _providerName.dispose();
    _accountName.dispose();
    _accountNo.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() {
      _pickedImagePath = file.path;
      _removeQris = false;
    });
  }

  Future<void> _save() async {
    if (_providerName.text.trim().isEmpty ||
        _accountName.text.trim().isEmpty) {
      setState(() => _error = 'Provider dan nama akun wajib diisi');
      return;
    }
    if (_type != 'manual_qris' && _accountNo.text.trim().isEmpty) {
      setState(() => _error = 'Nomor rekening / akun wajib diisi');
      return;
    }
    if (_type == 'manual_qris') {
      final hasImage = (_pickedImagePath?.isNotEmpty ?? false) ||
          ((_existingQrisUrl?.isNotEmpty ?? false) && !_removeQris);
      if (!hasImage) {
        setState(() => _error = 'Gambar QRIS wajib diupload');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      if (_isEdit) {
        final id = int.tryParse('${widget.method!['id']}') ?? 0;
        await api.updatePaymentMethod(
          id: id,
          paymentType: _type,
          providerName: _providerName.text.trim(),
          providerAccountName: _accountName.text.trim(),
          providerAccountNo:
              _type == 'manual_qris' ? null : _accountNo.text.trim(),
          additionalInfo: _additionalInfo.text.trim().isEmpty
              ? null
              : _additionalInfo.text.trim(),
          imagePath: _pickedImagePath,
          isActive: _isActive,
          removeQris: _removeQris,
        );
      } else {
        await api.createPaymentMethod(
          paymentType: _type,
          providerName: _providerName.text.trim(),
          providerAccountName: _accountName.text.trim(),
          providerAccountNo:
              _type == 'manual_qris' ? null : _accountNo.text.trim(),
          additionalInfo: _additionalInfo.text.trim().isEmpty
              ? null
              : _additionalInfo.text.trim(),
          imagePath: _pickedImagePath,
          isActive: _isActive,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan metode pembayaran';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan metode pembayaran');
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
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
                      _isEdit ? 'Edit metode bayar' : 'Tambah metode bayar',
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
                    const Text(
                      'Tipe pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            selected: _type == 'manual_tf',
                            label: 'Transfer',
                            icon: Icons.account_balance_rounded,
                            onTap: () => setState(() => _type = 'manual_tf'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            selected: _type == 'manual_ewallet',
                            label: 'E-Wallet',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () =>
                                setState(() => _type = 'manual_ewallet'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            selected: _type == 'manual_qris',
                            label: 'QRIS',
                            icon: Icons.qr_code_2_rounded,
                            onTap: () => setState(() => _type = 'manual_qris'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _providerName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _type == 'manual_tf'
                            ? 'Nama bank'
                            : _type == 'manual_ewallet'
                                ? 'Nama e-wallet'
                                : 'Nama provider QRIS',
                        hintText: _type == 'manual_tf'
                            ? 'Contoh: BCA'
                            : _type == 'manual_ewallet'
                                ? 'Contoh: GoPay'
                                : 'Contoh: QRIS Merchant',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accountName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nama akun / penerima',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (_type != 'manual_qris') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _accountNo,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: _type == 'manual_tf'
                              ? 'Nomor rekening'
                              : 'Nomor akun / HP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                    if (_type == 'manual_qris') ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Gambar QRIS',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _QrisImagePicker(
                        localPath: _pickedImagePath,
                        networkUrl: _removeQris ? null : _existingQrisUrl,
                        onPick: _pickImage,
                        onRemove: () {
                          setState(() {
                            _pickedImagePath = null;
                            _removeQris = true;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _additionalInfo,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      activeTrackColor: _brand.withValues(alpha: 0.45),
                      activeThumbColor: _brand,
                      title: const Text(
                        'Aktifkan metode ini',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Tampil untuk digunakan di kasir'
                            : 'Disembunyikan sementara',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 12),
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
                                _isEdit ? 'Simpan Perubahan' : 'Simpan Metode',
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _brand : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrisImagePicker extends StatelessWidget {
  const _QrisImagePicker({
    required this.onPick,
    required this.onRemove,
    this.localPath,
    this.networkUrl,
  });

  final String? localPath;
  final String? networkUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && localPath!.isNotEmpty;
    final hasNetwork = networkUrl != null && networkUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.4,
          child: Material(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: hasLocal
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(localPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : hasNetwork
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: networkUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const _QrisPlaceholder(),
                            ),
                          )
                        : const _QrisPlaceholder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hasLocal || hasNetwork ? 'Ganti gambar' : 'Pilih gambar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brand,
                  side: BorderSide(color: _brand.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasLocal || hasNetwork) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Hapus gambar',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _QrisPlaceholder extends StatelessWidget {
  const _QrisPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 42,
            color: _brand.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload gambar QRIS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
