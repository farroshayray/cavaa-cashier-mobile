import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'owner_cash_book_detail_page.dart';
import 'owner_home_page.dart';
import '../widgets/dock_inset.dart';

class OwnerCashBookPage extends StatefulWidget {
  const OwnerCashBookPage({super.key});

  @override
  State<OwnerCashBookPage> createState() => _OwnerCashBookPageState();
}

class _OwnerCashBookPageState extends State<OwnerCashBookPage> {
  static const _brand = Color(0xFFAE1504);
  static const _bg = Color(0xFFF6F7F9);

  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _deciding = false;
  String? _error;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _dateParam {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '${_date.year}-$month-$day';
  }

  String get _dateLabel {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '$day/$month/${_date.year}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary =
          await ownerApiOf(context).cashierShiftSummary(date: _dateParam);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Rekap buku kasir gagal dimuat.';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    await _load();
  }

  Future<void> _openDetail(int id) async {
    if (id <= 0) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCashBookDetailPage(shiftId: id),
      ),
    );
  }

  Future<void> _decide(int id, bool approve) async {
    if (_deciding || id <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Setujui selisih?' : 'Minta hitung ulang?'),
        content: Text(
          approve
              ? 'Selisih kasir akan disetujui dan ditutup.'
              : 'Kasir akan diminta menghitung ulang uang tunai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _brand),
            child: Text(approve ? 'Setujui' : 'Hitung ulang'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deciding = true);
    try {
      final api = ownerApiOf(context);
      if (approve) {
        await api.approveCashierShift(id);
      } else {
        await api.rejectCashierShift(id);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses keputusan.')),
      );
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  Future<void> _switchStore(int storeId) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.selectStore(storeId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Gagal memilih toko')),
      );
      return;
    }
    await _load();
  }

  String _money(dynamic value) {
    final n = (num.tryParse('$value') ?? 0).round();
    final raw = n.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return n < 0 ? '-$buffer' : buffer.toString();
  }

  int _asInt(dynamic value) => (num.tryParse('$value') ?? 0).round();

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Hitung ulang';
      case 'open':
      case 'opened':
        return 'Berjalan';
      case 'closed':
        return 'Ditutup';
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
        return const Color(0xFFB45309);
      case 'approved':
      case 'closed':
        return const Color(0xFF047857);
      case 'rejected':
        return _brand;
      case 'open':
      case 'opened':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = (_summary?['pending'] as List?) ?? const [];
    final shifts = (_summary?['shifts'] as List?) ?? const [];
    final others = (_summary?['other_stores'] as List?) ?? const [];
    final storeName = _summary?['store_name']?.toString() ?? '';
    final qrTotal = _summary?['customer_qr_total'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Buku kasir',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading && _summary == null
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
                children: [
                  _HeroHeader(
                    storeName: storeName.isEmpty ? 'Toko aktif' : storeName,
                    dateLabel: _dateLabel,
                    isToday: _isToday,
                    pendingCount: pending.length,
                    onPickDate: _pickDate,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _error!, onRetry: _load),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _OtherStoresNotice(
                      others: others,
                      onSwitch: _switchStore,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.hourglass_top_rounded,
                          label: 'Menunggu',
                          value: '${pending.length}',
                          accent: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Shift',
                          value: '${shifts.length}',
                          accent: const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.qr_code_2_rounded,
                          label: 'QR',
                          value: _money(qrTotal),
                          accent: _brand,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.pending_actions_rounded,
                    title: 'Menunggu persetujuan',
                  ),
                  const SizedBox(height: 10),
                  if (pending.isEmpty)
                    const _EmptyCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Tidak ada yang menunggu',
                      subtitle:
                          'Semua selisih kasir untuk toko ini sudah diproses.',
                    )
                  else
                    for (final raw in pending)
                      if (raw is Map) ...[
                        _PendingCard(
                          row: Map<String, dynamic>.from(raw),
                          money: _money,
                          asInt: _asInt,
                          busy: _deciding,
                          onOpen: _openDetail,
                          onApprove: (id) => _decide(id, true),
                          onReject: (id) => _decide(id, false),
                        ),
                        const SizedBox(height: 10),
                      ],
                  const SizedBox(height: 12),
                  _SectionTitle(
                    icon: Icons.menu_book_rounded,
                    title: 'Rekap $_dateLabel',
                  ),
                  const SizedBox(height: 10),
                  if (shifts.isEmpty)
                    const _EmptyCard(
                      icon: Icons.inbox_outlined,
                      title: 'Belum ada buku kasir',
                      subtitle:
                          'Shift yang dibuka pada tanggal ini akan muncul di sini.',
                    )
                  else
                    for (final raw in shifts)
                      if (raw is Map) ...[
                        _ShiftCard(
                          row: Map<String, dynamic>.from(raw),
                          money: _money,
                          asInt: _asInt,
                          statusLabel: _statusLabel,
                          statusColor: _statusColor,
                          onOpen: _openDetail,
                        ),
                        const SizedBox(height: 10),
                      ],
                ],
              ),
            ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.storeName,
    required this.dateLabel,
    required this.isToday,
    required this.pendingCount,
    required this.onPickDate,
  });

  final String storeName;
  final String dateLabel;
  final bool isToday;
  final int pendingCount;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAE1504).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rekap shift & persetujuan selisih',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$pendingCount menunggu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isToday ? 'Hari ini · $dateLabel' : dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFAE1504)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFAE1504)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _OtherStoresNotice extends StatelessWidget {
  const _OtherStoresNotice({
    required this.others,
    required this.onSwitch,
  });

  final List<dynamic> others;
  final ValueChanged<int> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_rounded, color: Color(0xFFB45309), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toko lain menunggu persetujuan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final raw in others)
                if (raw is Map)
                  ActionChip(
                    avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      '${raw['name']} (${raw['pending_count']})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    onPressed: () {
                      final id = int.tryParse('${raw['id']}') ?? 0;
                      if (id > 0) onSwitch(id);
                    },
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.row,
    required this.money,
    required this.asInt,
    required this.busy,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final String Function(dynamic) money;
  final int Function(dynamic) asInt;
  final bool busy;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onApprove;
  final ValueChanged<int> onReject;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse('${row['id']}') ?? 0;
    final store = row['store_name']?.toString() ?? '';
    final employee = row['employee_name']?.toString() ?? '-';
    final variance = asInt(row['variance']);
    final varianceColor =
        variance == 0 ? const Color(0xFF047857) : const Color(0xFFAE1504);
    final trimmed = employee.trim();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpen(id),
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFFE4E1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFFAE1504),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (store.isNotEmpty)
                      Text(
                        store,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: varianceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Selisih Rp ${money(variance)}',
                  style: TextStyle(
                    color: varianceColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MoneyMini(
                  label: 'Seharusnya',
                  value: 'Rp ${money(row['expected_cash'])}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyMini(
                  label: 'Dihitung',
                  value: 'Rp ${money(row['counted_cash'])}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => onReject(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Hitung ulang'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => onApprove(id),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAE1504),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.row,
    required this.money,
    required this.asInt,
    required this.statusLabel,
    required this.statusColor,
    required this.onOpen,
  });

  final Map<String, dynamic> row;
  final String Function(dynamic) money;
  final int Function(dynamic) asInt;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse('${row['id']}') ?? 0;
    final store = row['store_name']?.toString() ?? '';
    final employee = row['employee_name']?.toString() ?? '-';
    final status = row['status']?.toString() ?? '';
    final color = statusColor(status);
    final variance = asInt(row['variance']);
    final trimmed = employee.trim();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpen(id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF3F4F6),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (store.isNotEmpty)
                          Text(
                            store,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MoneyMini(
                      label: 'Modal',
                      value: 'Rp ${money(row['opening_cash'])}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MoneyMini(
                      label: 'Tunai',
                      value: 'Rp ${money(row['cash_net'])}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MoneyMini(
                      label: 'Non-tunai',
                      value: 'Rp ${money(row['non_cash_total'])}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MoneyMini(
                      label: 'Selisih',
                      value: 'Rp ${money(variance)}',
                      valueColor: variance == 0
                          ? const Color(0xFF047857)
                          : const Color(0xFFAE1504),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyMini extends StatelessWidget {
  const _MoneyMini({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
