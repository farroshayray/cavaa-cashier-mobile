import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _dayLabels = {
  'mon': 'Sen',
  'tue': 'Sel',
  'wed': 'Rab',
  'thu': 'Kam',
  'fri': 'Jum',
  'sat': 'Sab',
  'sun': 'Min',
};

String _formatMoney(num n) {
  return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String _formatDateTime(DateTime? dt) {
  if (dt == null) return 'Pilih tanggal & jam';
  final local = dt.toLocal();
  return '${_pad2(local.day)}/${_pad2(local.month)}/${local.year}, '
      '${_pad2(local.hour)}:${_pad2(local.minute)}';
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool hasValue;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                        color: hasValue
                            ? const Color(0xFF0F172A)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String _query = '';
  String? _typeFilter; // percentage | amount | null
  List<Map<String, dynamic>> _promotions = [];
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
      final data = await ownerApiOf(context).listPromotions(
        q: _query,
        type: _typeFilter,
      );
      final list = data['promotions'];
      setState(() {
        _promotions = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat promosi');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? promo}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PromotionEditorPage(promotion: promo),
      ),
    );
    if (changed == true && mounted) await _load(silent: true);
  }

  Future<void> _confirmDelete(Map<String, dynamic> promo) async {
    final id = int.tryParse('${promo['id'] ?? ''}');
    if (id == null) return;
    final name =
        promo['name']?.toString() ?? promo['promotion_name']?.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus promosi?'),
        content: Text('Hapus “$name”? Produk yang memakai promo ini akan kehilangan tautan promo.'),
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
      await ownerApiOf(context).deletePromotion(id);
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promosi dihapus')),
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'inactive':
        return const Color(0xFF64748B);
      case 'upcoming':
        return const Color(0xFF1D4ED8);
      case 'expired':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF0B6E4F);
    }
  }

  String _valueLabel(Map<String, dynamic> p) {
    final type = p['promotion_type']?.toString() ?? '';
    final value = p['promotion_value'];
    final n = value is num ? value : num.tryParse('$value') ?? 0;
    if (type == 'percentage') return '${n.toStringAsFixed(0)}%';
    return 'Rp ${_formatMoney(n)}';
  }

  String _daysLabel(dynamic raw) {
    if (raw is! List || raw.isEmpty) return 'Setiap hari';
    final keys = raw.map((e) => e.toString()).toList();
    if (keys.length >= 7) return 'Setiap hari';
    return keys.map((k) => _dayLabels[k] ?? k).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Promosi',
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
        onPressed: _loading ? null : () => _openEditor(),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah promo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diskon & penawaran',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.98),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buat promo persen atau nominal, atur jadwal, lalu pasang ke produk.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
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
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_promotions.length}',
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
                      hintText: 'Cari nama atau kode promo…',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                _query = '';
                                _load(silent: true);
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
                      _load(silent: true);
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _typeFilter == null,
                        onTap: () {
                          setState(() => _typeFilter = null);
                          _load(silent: true);
                        },
                      ),
                      _FilterChip(
                        label: 'Persen',
                        selected: _typeFilter == 'percentage',
                        onTap: () {
                          setState(() => _typeFilter = 'percentage');
                          _load(silent: true);
                        },
                      ),
                      _FilterChip(
                        label: 'Nominal',
                        selected: _typeFilter == 'amount',
                        onTap: () {
                          setState(() => _typeFilter = 'amount');
                          _load(silent: true);
                        },
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  if (_promotions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.local_offer_outlined,
                              color: _brand,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _query.isEmpty && _typeFilter == null
                                ? 'Belum ada promosi'
                                : 'Tidak ada hasil',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _query.isEmpty && _typeFilter == null
                                ? 'Tambah promo diskon persen atau potongan harga tetap.'
                                : 'Coba ubah filter atau kata kunci.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._promotions.map((p) {
                      final status = p['status']?.toString() ?? 'active';
                      final statusLabel =
                          p['status_label']?.toString() ?? 'Aktif';
                      final color = _statusColor(status);
                      final type = p['promotion_type']?.toString() ?? '';
                      final code = p['promotion_code']?.toString() ?? '';
                      final name = p['name']?.toString() ??
                          p['promotion_name']?.toString() ??
                          '-';
                      final usesExpiry = p['uses_expiry'] == true;
                      final start = p['start_date']?.toString();
                      final end = p['end_date']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              color: Colors.black.withValues(alpha: 0.03),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openEditor(promo: p),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    type == 'percentage'
                                        ? Icons.percent_rounded
                                        : Icons.payments_outlined,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          _valueLabel(p),
                                          if (code.isNotEmpty) code,
                                          _daysLabel(p['active_days']),
                                        ].join(' · '),
                                        style: TextStyle(
                                          color: Colors.black
                                              .withValues(alpha: 0.55),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      if (usesExpiry &&
                                          (start != null || end != null)) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${start ?? '…'} → ${end ?? '…'}',
                                          style: TextStyle(
                                            color: Colors.black
                                                .withValues(alpha: 0.45),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _confirmDelete(p),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: _brand,
                                  ),
                                ),
                              ],
                            ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _brand.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? _brand : const Color(0xFF334155),
      ),
      side: BorderSide(
        color: selected
            ? _brand.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.08),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class PromotionEditorPage extends StatefulWidget {
  const PromotionEditorPage({super.key, this.promotion});

  final Map<String, dynamic>? promotion;

  @override
  State<PromotionEditorPage> createState() => _PromotionEditorPageState();
}

class _PromotionEditorPageState extends State<PromotionEditorPage> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _desc = TextEditingController();

  String _type = 'percentage';
  bool _usesExpiry = false;
  bool _isActive = true;
  DateTime? _start;
  DateTime? _end;
  final Set<String> _days = {};
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.promotion != null;
  int? get _id => int.tryParse('${widget.promotion?['id'] ?? ''}');

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    if (p != null) {
      _name.text =
          p['name']?.toString() ?? p['promotion_name']?.toString() ?? '';
      _type = p['promotion_type']?.toString() == 'amount'
          ? 'amount'
          : 'percentage';
      final v = p['promotion_value'];
      _value.text = v is num
          ? (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString())
          : (v?.toString() ?? '');
      _desc.text = p['description']?.toString() ?? '';
      _usesExpiry = p['uses_expiry'] == true;
      _isActive = p['is_active'] == true || p['is_active'] == 1;
      _start = _parseDt(p['start_date_iso'] ?? p['start_date']);
      _end = _parseDt(p['end_date_iso'] ?? p['end_date']);
      final days = p['active_days'];
      if (days is List) {
        _days.addAll(days.map((e) => e.toString()));
      }
    }
  }

  DateTime? _parseDt(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  String _fmt(DateTime? dt) => _formatDateTime(dt);

  Future<void> _save() async {
    final name = _name.text.trim();
    final value = num.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (name.isEmpty) {
      setState(() => _error = 'Nama promo wajib diisi');
      return;
    }
    if (value == null) {
      setState(() => _error = 'Nilai promo wajib diisi');
      return;
    }
    if (_type == 'percentage' && (value < 1 || value > 100)) {
      setState(() => _error = 'Persentase harus 1–100');
      return;
    }
    if (_usesExpiry) {
      if (_start == null || _end == null) {
        setState(() => _error = 'Lengkapi tanggal mulai dan selesai');
        return;
      }
      if (!_end!.isAfter(_start!)) {
        setState(() => _error = 'Tanggal selesai harus setelah mulai');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      final days = _days.isEmpty ? null : _dayKeys.where(_days.contains).toList();
      if (_isEdit && _id != null) {
        await api.updatePromotion(
          id: _id!,
          name: name,
          type: _type,
          value: value,
          usesExpiry: _usesExpiry,
          startDate: _start,
          endDate: _end,
          activeDays: days,
          isActive: _isActive,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        );
      } else {
        await api.createPromotion(
          name: name,
          type: _type,
          value: value,
          usesExpiry: _usesExpiry,
          startDate: _start,
          endDate: _end,
          activeDays: days,
          isActive: _isActive,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Promosi diperbarui' : 'Promosi dibuat'),
        ),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal menyimpan promosi';
      });
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan promosi');
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
          _isEdit ? 'Edit Promosi' : 'Tambah Promosi',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Nama promo',
                    hintText: 'Contoh: Diskon Weekend',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Jenis diskon',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TypeCard(
                        selected: _type == 'percentage',
                        icon: Icons.percent_rounded,
                        title: 'Persen',
                        subtitle: 'Mis. 10%',
                        onTap: _saving
                            ? null
                            : () => setState(() => _type = 'percentage'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeCard(
                        selected: _type == 'amount',
                        icon: Icons.payments_outlined,
                        title: 'Nominal',
                        subtitle: 'Mis. Rp 5.000',
                        onTap: _saving
                            ? null
                            : () => setState(() => _type = 'amount'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _value,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _type == 'percentage'
                        ? 'Nilai persen (1–100)'
                        : 'Nilai nominal (Rp)',
                    border: const OutlineInputBorder(),
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
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: _brand,
                  title: const Text(
                    'Aktifkan promo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Nonaktif = tidak dipakai kasir'),
                  value: _isActive,
                  onChanged:
                      _saving ? null : (v) => setState(() => _isActive = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: _brand,
                  title: const Text(
                    'Pakai masa berlaku',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Batasi dengan tanggal mulai & selesai'),
                  value: _usesExpiry,
                  onChanged:
                      _saving ? null : (v) => setState(() => _usesExpiry = v),
                ),
                if (_usesExpiry) ...[
                  const SizedBox(height: 4),
                  _DateTimeField(
                    label: 'Mulai',
                    value: _start != null ? _fmt(_start) : 'Pilih tanggal & jam',
                    hasValue: _start != null,
                    enabled: !_saving,
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                  const SizedBox(height: 8),
                  _DateTimeField(
                    label: 'Selesai',
                    value: _end != null ? _fmt(_end) : 'Pilih tanggal & jam',
                    hasValue: _end != null,
                    enabled: !_saving,
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Hari aktif',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kosongkan = berlaku setiap hari',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dayKeys.map((d) {
                    final selected = _days.contains(d);
                    return FilterChip(
                      label: Text(_dayLabels[d]!),
                      selected: selected,
                      onSelected: _saving
                          ? null
                          : (v) {
                              setState(() {
                                if (v) {
                                  _days.add(d);
                                } else {
                                  _days.remove(d);
                                }
                              });
                            },
                      selectedColor: _brand.withValues(alpha: 0.12),
                      checkmarkColor: _brand,
                      side: BorderSide(
                        color: selected
                            ? _brand.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    );
                  }).toList(),
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
                        : Text(
                            _isEdit ? 'Simpan Perubahan' : 'Simpan Promo',
                            style: const TextStyle(fontWeight: FontWeight.w800),
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _brand.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _brand.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? _brand : const Color(0xFF64748B)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? _brand : const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
