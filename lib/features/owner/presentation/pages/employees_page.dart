import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'employee_editor_page.dart';
import 'owner_home_page.dart';
import '../widgets/owner_setup_progress.dart';
import '../widgets/dock_inset.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key, this.showSetupProgress = false});

  final bool showSetupProgress;

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _storeName;
  int? _selectedStoreId;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _availableMenus = [];
  List<Map<String, dynamic>> _workScheduleProfiles = [];
  List<String> _allowedRoles = const ['CASHIER'];
  int _activeCount = 0;
  int _inactiveCount = 0;

  String? _filterRole;
  String _filterStatus = 'all';
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
      final data = await ownerApiOf(context).listEmployees(
        role: _filterRole,
        status: _filterStatus == 'all' ? null : _filterStatus,
        q: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );

      final list = data['employees'];
      final stores = data['stores'];
      final roles = data['allowed_roles'];
      final categories = data['categories'];
      final menus = data['available_menus'];
      final profiles = data['work_schedule_profiles'];

      setState(() {
        _employees = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _stores = stores is List
            ? stores
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _categories = categories is List
            ? categories
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _availableMenus = menus is List
            ? menus
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _workScheduleProfiles = profiles is List
            ? profiles
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _allowedRoles = roles is List
            ? roles.map((e) => e.toString()).toList()
            : const ['CASHIER'];
        _activeCount = int.tryParse('${data['active_count'] ?? 0}') ?? 0;
        _inactiveCount = int.tryParse('${data['inactive_count'] ?? 0}') ?? 0;
        _selectedStoreId =
            int.tryParse('${data['selected_store_id'] ?? ''}');
        _storeName = data['selected_store_name']?.toString();
        _error = null;
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (mounted) {
        setState(() {
          _error = data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Gagal memuat data pegawai';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data pegawai');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? employee}) async {
    if (_stores.isEmpty || _selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih toko dulu sebelum mengelola pegawai'),
        ),
      );
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EmployeeEditorPage(
          employee: employee,
          stores: _stores,
          allowedRoles: _allowedRoles,
          defaultPartnerId: _selectedStoreId!,
          categories: _categories,
          availableMenus: _availableMenus,
          workScheduleProfiles: _workScheduleProfiles,
        ),
      ),
    );
    if (changed == true && mounted) {
      await context.read<AuthProvider>().refreshOwner();
      await _load(silent: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> employee) async {
    if (employee['is_owner_cashier'] == true) return;
    final id = int.tryParse('${employee['id']}') ?? 0;
    if (id <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pegawai?'),
        content: Text(
          'Hapus ${employee['name'] ?? 'pegawai ini'}? '
          'Akun login akan dinonaktifkan permanen.',
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

    final api = ownerApiOf(context);
    final auth = context.read<AuthProvider>();
    try {
      await api.deleteEmployee(id);
      await auth.refreshOwner();
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pegawai dihapus')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menghapus pegawai',
          ),
        ),
      );
    }
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'CASHIER':
        return 'Kasir';
      case 'KITCHEN':
        return 'Kitchen';
      case 'MANAGER':
        return 'Manager';
      case 'SUPERVISOR':
        return 'Supervisor';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'CASHIER':
        return _brand;
      case 'KITCHEN':
        return const Color(0xFFB45309);
      case 'MANAGER':
        return const Color(0xFF1D4ED8);
      case 'SUPERVISOR':
        return const Color(0xFF0B6E4F);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pegawai',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (_storeName != null && _storeName!.isNotEmpty)
              Text(
                _storeName!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
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
      floatingActionButton: DockAwareFab(
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'Tambah',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
                  if (widget.showSetupProgress)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: OwnerSetupStepHeader(stepKey: 'create_employee'),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
                                    'Tim toko',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.98),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _storeName != null && _storeName!.isNotEmpty
                                        ? 'Kelola kasir & peran di $_storeName'
                                        : 'Kelola kasir, kitchen, manager, dan supervisor.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.78),
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _HeroStat(
                              value: '$_activeCount',
                              label: 'Aktif',
                            ),
                            const SizedBox(width: 8),
                            _HeroStat(
                              value: '${_activeCount + _inactiveCount}',
                              label: 'Total',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _load(silent: true),
                            decoration: InputDecoration(
                              hintText: 'Cari nama, username, email…',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _search.text.trim().isEmpty
                                  ? IconButton(
                                      onPressed: () => _load(silent: true),
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        _search.clear();
                                        setState(() {});
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
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            key: ValueKey('role-$_filterRole'),
                            initialValue: _filterRole,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              filled: true,
                              fillColor: Colors.white,
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
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Semua role'),
                              ),
                              ..._allowedRoles.map(
                                (r) => DropdownMenuItem<String?>(
                                  value: r,
                                  child: Text(_roleLabel(r)),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterRole = v);
                              _load(silent: true);
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB)
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _StatusSegmentTab(
                                  label: 'Semua',
                                  selected: _filterStatus == 'all',
                                  onTap: () {
                                    setState(() => _filterStatus = 'all');
                                    _load(silent: true);
                                  },
                                ),
                                _StatusSegmentTab(
                                  label: 'Aktif',
                                  selected: _filterStatus == 'active',
                                  onTap: () {
                                    setState(() => _filterStatus = 'active');
                                    _load(silent: true);
                                  },
                                ),
                                _StatusSegmentTab(
                                  label: 'Nonaktif',
                                  selected: _filterStatus == 'inactive',
                                  onTap: () {
                                    setState(() => _filterStatus = 'inactive');
                                    _load(silent: true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  if (_employees.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(32).withBottomInset(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: _brand,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Belum ada pegawai',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tambah kasir, kitchen, manager, atau supervisor untuk toko ini.',
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100)
                          .withBottomInset(context),
                      sliver: SliverList.separated(
                        itemCount: _employees.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final e = _employees[index];
                          final role = e['role']?.toString() ?? '-';
                          final ownerCashier = e['is_owner_cashier'] == true;
                          final active =
                              e['is_active'] == true || e['is_active'] == 1;
                          final imageUrl = resolveEmployeeImageUrl(e['image']);
                          final initial = (e['name']?.toString() ?? '?')
                              .characters
                              .first
                              .toUpperCase();
                          final roleColor = _roleColor(role);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: ownerCashier
                                    ? null
                                    : () => _openEditor(employee: e),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 12, 4, 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: imageUrl == null
                                              ? ColoredBox(
                                                  color: roleColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      initial,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 16,
                                                        color: roleColor,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 48,
                                                  height: 48,
                                                  placeholder: (_, __) =>
                                                      ColoredBox(
                                                    color: roleColor.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        initial,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: roleColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget: (_, __, ___) =>
                                                      ColoredBox(
                                                    color: roleColor.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        initial,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: roleColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e['name']?.toString() ?? '-',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (!ownerCashier) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                [
                                                  if ((e['user_name']
                                                              ?.toString() ??
                                                          '')
                                                      .isNotEmpty)
                                                    '@${e['user_name']}',
                                                  if ((e['email']?.toString() ??
                                                          '')
                                                      .isNotEmpty)
                                                    e['email'].toString(),
                                                ].join(' · '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                _MiniBadge(
                                                  label: _roleLabel(role),
                                                  color: roleColor,
                                                  filled: true,
                                                ),
                                                if (ownerCashier)
                                                  const _MiniBadge(
                                                    label: 'Owner Kasir',
                                                    color: Color(0xFF6D28D9),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Icon(
                                              active
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                      .pause_circle_filled_rounded,
                                              size: 20,
                                              color: active
                                                  ? const Color(0xFF0B6E4F)
                                                  : Colors.black38,
                                            ),
                                          ),
                                          if (!ownerCashier)
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              onSelected: (v) {
                                                if (v == 'edit') {
                                                  _openEditor(employee: e);
                                                }
                                                if (v == 'delete') {
                                                  _confirmDelete(e);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
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
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSegmentTab extends StatelessWidget {
  const _StatusSegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: selected ? _brand : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? color : const Color(0xFF475569),
        ),
      ),
    );
  }
}
