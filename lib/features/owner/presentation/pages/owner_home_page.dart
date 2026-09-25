import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/services/push_notification_service.dart';
import '/features/auth/data/models/owner_model.dart';
import '/features/auth/presentation/auth_provider.dart';
import '/features/auth/presentation/pages/login_page.dart';
import '/features/cashier/presentation/pages/cashier_home_page.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';
import '/core/network/dio_client.dart';
import '/core/services/connectivity_status_provider.dart';
import '../../data/owner_api.dart';
import 'create_store_page.dart';
import 'create_product_page.dart';
import 'payment_methods_page.dart';
import 'employees_page.dart';
import 'store_settings_page.dart';
import 'tables_page.dart';
import 'owner_cash_book_page.dart';
import 'promotions_page.dart';
import 'owner_account_page.dart';
import 'owner_addons_page.dart';
import '../widgets/owner_mobile_carousel.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage>
    with WidgetsBindingObserver {
  bool _routingChecked = false;
  bool _selectingStore = false;
  List<Map<String, dynamic>> _carousels = [];
  StreamSubscription<Map<String, dynamic>>? _billingNotifSub;
  int _pendingCashBooks = 0;
  String _cashBookStoreName = '';
  List<Map<String, dynamic>> _otherCashBookStores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _billingNotifSub = PushNotificationService.instance.onMessageReceived.listen(
      (data) {
        final type = (data['type'] ?? '').toString();
        if (type == 'billing_approved' || type == 'billing_rejected') {
          if (!mounted) return;
          context.read<AuthProvider>().refreshOwner();
          return;
        }
        if (type != 'new_order') return;
        if ((data['order_by'] ?? '').toString().toUpperCase() == 'CASHIER') {
          return;
        }
        if (!mounted) return;
        context.read<NotificationsProvider>().pushFromFcm(data);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsProvider>().loadFromStorage();
      }
      _checkOnboarding();
      _loadCarousels();
      _loadPendingCashBooks();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationsProvider>().loadFromStorage();
      _loadPendingCashBooks();
    }
  }

  Future<void> _loadPendingCashBooks() async {
    try {
      final summary = await ownerApiOf(context).cashierShiftSummary();
      final pending = summary['pending'];
      final others = summary['other_stores'];
      if (!mounted) return;
      setState(() {
        _pendingCashBooks = pending is List ? pending.length : 0;
        _cashBookStoreName = summary['store_name']?.toString() ?? '';
        _otherCashBookStores = others is List
            ? others
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _billingNotifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCarousels() async {
    try {
      final data = await ownerApiOf(context).listCarousels();
      final list = data['carousels'];
      if (!mounted) return;
      setState(() {
        _carousels = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    } catch (_) {
      // Keep silent; carousel is optional enrichment.
    }
  }

  Future<void> _checkOnboarding() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshOwner();
    } catch (_) {}

    if (!mounted) return;

    // Auto-push wizard only for brand-new owners without any store.
    final force = auth.owner?.forceOnboarding == true ||
        (auth.owner?.onboarding?.stores.isEmpty ?? true);
    final step = auth.owner?.onboarding?.nextStep ?? 'ready';
    if (force && step != 'ready' && !_routingChecked) {
      _routingChecked = true;
      await _openStep(step, replace: false);
    }
  }

  Future<void> _openStep(String step, {bool replace = false}) async {
    Widget? page;
    switch (step) {
      case 'create_store':
        page = const CreateStorePage();
        break;
      case 'create_product':
        page = const CreateProductPage();
        break;
      case 'create_master_product':
        page = const CreateProductPage();
        break;
      case 'create_payment_method':
        page = const PaymentMethodsPage();
        break;
      case 'create_table':
        page = const TablesPage();
        break;
      case 'create_employee':
        page = const EmployeesPage();
        break;
      default:
        return;
    }

    final route = MaterialPageRoute(builder: (_) => page!);
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
    if (mounted) {
      await context.read<AuthProvider>().refreshOwner();
      setState(() {});
    }
  }

  Future<void> _enterCashier() async {
    final auth = context.read<AuthProvider>();
    final storeId = auth.owner?.onboarding?.selectedStoreId ??
        auth.owner?.selectedPartnerId;
    final ok = await auth.enterCashierAsOwner(storeId: storeId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Gagal masuk kasir')),
      );
      return;
    }

    // Reset connectivity pessimism before loading cashier menu.
    try {
      final conn = context.read<ConnectivityStatusProvider>();
      if (conn.hasNetwork) {
        await conn.checkServerReachability();
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CashierHomePage()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _onStoreSelected(int? storeId) async {
    if (storeId == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.owner?.selectedPartnerId == storeId ||
        auth.owner?.onboarding?.selectedStoreId == storeId) {
      return;
    }

    setState(() => _selectingStore = true);
    final ok = await auth.selectStore(storeId);
    if (!mounted) return;
    setState(() => _selectingStore = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Gagal memilih toko')),
      );
      return;
    }
    await _loadPendingCashBooks();
  }

  String _stepLabel(String step) {
    switch (step) {
      case 'create_store':
        return 'Buat toko Anda';
      case 'create_product':
        return 'Tambahkan produk toko';
      case 'create_master_product':
        return 'Tambahkan produk toko';
      case 'create_payment_method':
        return 'Buat metode pembayaran';
      case 'create_table':
        return 'Buat meja';
      case 'create_employee':
        return 'Buat pegawai kasir';
      default:
        return step;
    }
  }

  Future<void> _openAddonsPaywall(
    String message, {
    String? highlightFeatureKey,
    String? highlightAddonCode,
  }) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fitur berbayar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _brand),
            child: const Text('Lihat Add-on'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OwnerAddonsPage(
            highlightFeatureKey: highlightFeatureKey,
            highlightAddonCode: highlightAddonCode,
          ),
        ),
      );
      if (mounted) await context.read<AuthProvider>().refreshOwner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final owner = auth.owner;
    final onboarding = owner?.onboarding;
    final nextStep = onboarding?.nextStep ?? 'ready';
    final stores = onboarding?.stores ?? const <OwnerStore>[];
    final selectedId =
        onboarding?.selectedStoreId ?? owner?.selectedPartnerId;
    final hasStore = stores.isNotEmpty;
    final forceOnboarding = owner?.forceOnboarding == true || !hasStore;
    final width = MediaQuery.sizeOf(context).width;
    // Phone: 4 per row keeps launcher denser; tablet/desktop scale up.
    final crossAxisCount = width >= 900
        ? 6
        : width >= 600
            ? 5
            : 4;
    final iconSize = width < 600 ? 54.0 : 62.0;
    final iconGlyphSize = width < 600 ? 24.0 : 28.0;
    final labelSize = width < 600 ? 11.5 : 12.5;
    final unreadOrders = context.watch<NotificationsProvider>().unread;

    final canPromo = owner?.hasFeature('products_promotions') ?? false;
    final canScanTable = owner?.hasFeature('feature_scan_table') ?? false;

    final menus = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.store_mall_directory_rounded,
        title: 'Toko',
        enabled: hasStore,
        onTap: hasStore
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StoreSettingsPage(),
                  ),
                ).then((_) => auth.refreshOwner())
            : null,
      ),
      _MenuItemData(
        icon: Icons.point_of_sale_rounded,
        title: 'Kasir',
        highlighted: true,
        enabled: hasStore,
        badgeCount: unreadOrders,
        onTap: hasStore ? _enterCashier : null,
      ),
      _MenuItemData(
        icon: Icons.shopping_bag_rounded,
        title: 'Produk\nToko',
        enabled: hasStore,
        onTap: hasStore
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProductPage()),
                ).then((_) => auth.refreshOwner())
            : null,
      ),
      _MenuItemData(
        icon: Icons.local_offer_rounded,
        title: 'Promosi',
        onTap: () {
          if (!canPromo) {
            _openAddonsPaywall(
              'Promosi menu memerlukan add-on atau paket yang mendukung.',
              highlightFeatureKey: 'products_promotions',
              highlightAddonCode: 'promotions',
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PromotionsPage()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.badge_rounded,
        title: 'Pegawai',
        enabled: hasStore,
        onTap: hasStore
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmployeesPage()),
                ).then((_) => auth.refreshOwner())
            : null,
      ),
      _MenuItemData(
        icon: canScanTable
            ? Icons.qr_code_2_rounded
            : Icons.table_restaurant_rounded,
        title: canScanTable ? 'QR\nMeja' : 'Meja',
        enabled: hasStore,
        onTap: hasStore
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TablesPage()),
                )
            : null,
      ),
      _MenuItemData(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Buku\nkasir',
        enabled: hasStore,
        badgeCount: _pendingCashBooks,
        onTap: hasStore
            ? () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OwnerCashBookPage(),
                  ),
                );
                if (mounted) _loadPendingCashBooks();
              }
            : null,
      ),
      _MenuItemData(
        icon: Icons.card_membership_rounded,
        title: 'Paket',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OwnerAddonsPage()),
        ).then((_) => auth.refreshOwner()),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Owner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OwnerAccountPage()),
            ),
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Akun',
          ),
          IconButton(
            onPressed: auth.isLoading ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _brand,
        onRefresh: () async {
          await auth.refreshOwner();
          await _loadCarousels();
          await _loadPendingCashBooks();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _OwnerHeader(
                  name: owner?.name ?? 'Owner',
                  email: owner?.email ?? '',
                  onAccount: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OwnerAccountPage()),
                  ),
                  stores: stores,
                  selectedStoreId: selectedId,
                  selecting: _selectingStore || auth.isLoading,
                  canCreateStore: owner?.canCreateStore ??
                      onboarding?.canCreateStore ??
                      true,
                  onStoreSelected: _onStoreSelected,
                  onCreateStore: () => _openStep('create_store'),
                ),
              ),
            ),
            if (_pendingCashBooks > 0 || _otherCashBookStores.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _CashBookNotice(
                    activeCount: _pendingCashBooks,
                    storeName: _cashBookStoreName,
                    otherStores: _otherCashBookStores,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OwnerCashBookPage(),
                        ),
                      );
                      if (mounted) _loadPendingCashBooks();
                    },
                  ),
                ),
              ),
            if (!forceOnboarding && nextStep != 'ready')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _SetupBanner(
                    label: _stepLabel(nextStep),
                    onTap: () => _openStep(nextStep),
                  ),
                ),
              ),
            if (_carousels.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                sliver: SliverToBoxAdapter(
                  child: OwnerMobileCarousel(items: _carousels),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MenuIconButton(
                    item: menus[index],
                    iconSize: iconSize,
                    iconGlyphSize: iconGlyphSize,
                    labelSize: labelSize,
                  ),
                  childCount: menus.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.title,
    this.onTap,
    this.enabled = true,
    this.highlighted = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool enabled;
  final bool highlighted;
  final int badgeCount;
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({
    required this.name,
    required this.email,
    required this.onAccount,
    required this.stores,
    required this.selectedStoreId,
    required this.selecting,
    required this.canCreateStore,
    required this.onStoreSelected,
    required this.onCreateStore,
  });

  final String name;
  final String email;
  final VoidCallback onAccount;
  final List<OwnerStore> stores;
  final int? selectedStoreId;
  final bool selecting;
  final bool canCreateStore;
  final ValueChanged<int?> onStoreSelected;
  final VoidCallback onCreateStore;

  @override
  Widget build(BuildContext context) {
    final validSelected = stores.any((s) => s.id == selectedStoreId)
        ? selectedStoreId
        : (stores.isNotEmpty ? stores.first.id : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brand.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onAccount,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _brand,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _brand),
              ],
            ),
            ),
            const SizedBox(height: 14),
            Text(
              'Toko aktif',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            if (stores.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onCreateStore,
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text(
                    'Buat toko pertama',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brand,
                    side: BorderSide(color: _brand.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('store-$validSelected'),
                      initialValue: validSelected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.storefront_rounded,
                          color: _brand,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _brand,
                            width: 1.3,
                          ),
                        ),
                      ),
                      items: stores
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: selecting ? null : onStoreSelected,
                    ),
                  ),
                  if (canCreateStore) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: selecting ? null : onCreateStore,
                      style: IconButton.styleFrom(
                        backgroundColor: _brand.withValues(alpha: 0.10),
                        foregroundColor: _brand,
                      ),
                      tooltip: 'Tambah toko',
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ],
              ),
            if (selecting) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(
                minHeight: 2,
                color: _brand,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CashBookNotice extends StatelessWidget {
  const _CashBookNotice({
    required this.activeCount,
    required this.storeName,
    required this.otherStores,
    required this.onTap,
  });

  final int activeCount;
  final String storeName;
  final List<Map<String, dynamic>> otherStores;
  final VoidCallback onTap;

  String get _othersLine {
    final parts = otherStores.map((store) {
      final name = store['name']?.toString() ?? 'Toko';
      final count = int.tryParse('${store['pending_count']}') ?? 0;
      return '$name ($count)';
    }).join(', ');
    if (activeCount > 0) return 'Juga menunggu di: $parts';
    return 'Buku kasir menunggu di: $parts';
  }

  @override
  Widget build(BuildContext context) {
    final store = storeName.trim().isEmpty ? 'toko ini' : storeName.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0D7B0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: _brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeCount > 0)
                        Text(
                          '$activeCount buku kasir $store menunggu persetujuan',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      if (otherStores.isNotEmpty) ...[
                        if (activeCount > 0) const SizedBox(height: 4),
                        Text(
                          _othersLine,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _brand.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  const _SetupBanner({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _brand.withValues(alpha: 0.16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: _brand,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lanjutkan setup',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _brand.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.item,
    this.iconSize = 62,
    this.iconGlyphSize = 28,
    this.labelSize = 12.5,
  });

  final _MenuItemData item;
  final double iconSize;
  final double iconGlyphSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled && item.onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? item.onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: item.highlighted
                              ? _brand
                              : _brand.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          boxShadow: item.highlighted
                              ? [
                                  BoxShadow(
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    color: _brand.withValues(alpha: 0.28),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          item.icon,
                          size: iconGlyphSize,
                          color: item.highlighted ? Colors.white : _brand,
                        ),
                      ),
                      if (item.badgeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _brand, width: 1.5),
                            ),
                            child: Text(
                              item.badgeCount > 99
                                  ? '99+'
                                  : '${item.badgeCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _brand,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: labelSize,
                    height: 1.15,
                    color: item.highlighted ? _brand : Colors.black87,
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

OwnerApi ownerApiOf(BuildContext context) {
  return OwnerApi(context.read<DioClient>());
}
