import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '/core/services/push_notification_service.dart';
import '/features/auth/data/models/owner_model.dart';
import '/features/auth/presentation/auth_provider.dart';
import '/features/auth/presentation/pages/login_page.dart';
import '/features/cashier/presentation/pages/cashier_home_page.dart';
import '/features/cashier/presentation/pages/reports/reports_page.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';
import '/core/network/dio_client.dart';
import '/core/services/connectivity_status_provider.dart';
import '../../data/owner_api.dart';
import '../../data/welcome_gift_store.dart';
import 'welcome_gift_dialog.dart';
import 'setup_complete_dialog.dart';
import '../widgets/owner_setup_progress.dart';
import 'create_store_page.dart';
import 'create_product_page.dart';
import 'owner_stocks_page.dart';
import 'payment_methods_page.dart';
import 'employees_page.dart';
import 'store_settings_page.dart';
import 'tables_page.dart';
import 'owner_cash_book_page.dart';
import 'promotions_page.dart';
import 'owner_account_page.dart';
import 'owner_addons_page.dart';
import 'owner_cavaa_points_page.dart';
import '../widgets/owner_mobile_carousel.dart';
import '../widgets/dock_inset.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

enum _BarPage { none, report, account }

class _OpenSection {
  const _OpenSection({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;
}

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key, this.initialStep});

  final String? initialStep;

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage>
    with WidgetsBindingObserver {
  bool _routingChecked = false;
  bool _giftShown = false;
  bool _setupCompleteShown = false;
  bool _selectingStore = false;
  List<Map<String, dynamic>> _carousels = [];
  StreamSubscription<Map<String, dynamic>>? _billingNotifSub;
  int _pendingCashBooks = 0;
  String _cashBookStoreName = '';
  List<Map<String, dynamic>> _otherCashBookStores = [];
  final _menuScroll = ScrollController();
  final _sectionNav = GlobalKey<NavigatorState>();
  var _navGen = 0;
  var _barPage = _BarPage.none;
  _OpenSection? _section;
  Future<void>? _sectionTask;
  var _sheetOpen = false;
  late final _sheetObserver = _SheetObserver((open) {
    final next = open > 0;
    if (next == _sheetOpen) return;
    void apply() {
      if (mounted) setState(() => _sheetOpen = next);
    }

    // Routes can be pushed mid-build; defer the rebuild in that case.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      apply();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    }
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _billingNotifSub = PushNotificationService.instance.onMessageReceived
        .listen((data) {
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
        });
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
    if (!mounted || context.read<AuthProvider>().authRole != 'owner') return;
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
    _menuScroll.dispose();
    super.dispose();
  }

  Future<void> _loadCarousels() async {
    if (!mounted || context.read<AuthProvider>().authRole != 'owner') return;
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

  Future<void> _pushSection(
    Widget page, {
    _BarPage bar = _BarPage.none,
    IconData? icon,
    String tooltip = '',
    Future<void> Function()? after,
  }) async {
    final nav = _sectionNav.currentState;
    if (nav == null || !mounted) return;
    await _retireOpenSection();
    if (!mounted) return;
    final current = _sectionNav.currentState;
    if (current == null) return;

    final gen = ++_navGen;
    setState(() {
      _barPage = bar;
      _section = icon == null
          ? null
          : _OpenSection(icon: icon, tooltip: tooltip);
    });
    final task = _showSection(current, page, gen, after);
    _sectionTask = task;
    try {
      await task;
    } finally {
      if (identical(_sectionTask, task)) _sectionTask = null;
    }
  }

  Future<void> _showSection(
    NavigatorState nav,
    Widget page,
    int gen,
    Future<void> Function()? after,
  ) async {
    await nav.push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    if (gen == _navGen) {
      setState(() {
        _barPage = _BarPage.none;
        _section = null;
      });
    }
    if (after != null) await after();
  }

  Future<void> _retireOpenSection() async {
    final pending = _sectionTask;
    final nav = _sectionNav.currentState;
    if (nav != null && nav.canPop()) {
      _navGen++;
      nav.popUntil((route) => route.isFirst);
    }
    if (pending == null) return;
    try {
      await pending;
    } catch (_) {}
  }

  Future<void> _goHome() async {
    setState(() {
      _barPage = _BarPage.none;
      _section = null;
    });
    await _retireOpenSection();
    if (!mounted || !_menuScroll.hasClients) return;
    _menuScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _checkOnboarding() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshOwner();
    } catch (_) {}

    if (!mounted) return;

    final storesEmpty = auth.owner?.onboarding?.stores.isEmpty ?? true;
    if (!storesEmpty) await _maybeWelcomeGift();

    final requested = widget.initialStep;
    if (requested != null && requested != 'ready' && !_routingChecked) {
      _routingChecked = true;
      await _openStep(requested, fromSetup: true);
      if (mounted) await _maybeWelcomeGift();
      return;
    }

    // Auto-open current setup step for brand-new owners without any store.
    final force = auth.owner?.forceOnboarding == true || storesEmpty;
    final step = auth.owner?.onboarding?.nextStep ?? 'ready';
    if (force && step != 'ready' && !_routingChecked) {
      _routingChecked = true;
      await _openStep(step, fromSetup: true);
      if (mounted) await _maybeWelcomeGift();
    }
  }

  Future<void> _maybeWelcomeGift() async {
    if (_giftShown || !mounted) return;
    final auth = context.read<AuthProvider>();
    final owner = auth.owner;
    if (owner == null) return;
    if (owner.referralPointsEnabled == false) {
      await WelcomeGiftStore.clear(owner.id);
      return;
    }
    if (owner.onboarding?.stores.isEmpty ?? true) return;
    final points = await WelcomeGiftStore.read(owner.id);
    if (!mounted || points == null || points < 1) return;
    _giftShown = true;
    final openPoints = await showWelcomeGiftDialog(context, points: points);
    await WelcomeGiftStore.clear(owner.id);
    if (openPoints == true && mounted) {
      await _pushSection(
        const OwnerCavaaPointsPage(),
        icon: Icons.stars_rounded,
        tooltip: 'Cavaa Points',
        after: () => auth.refreshOwner(),
      );
    }
  }

  Future<void> _openStep(String step, {bool fromSetup = false}) async {
    Widget? page;
    switch (step) {
      case 'create_store':
        page = CreateStorePage(showSetupProgress: fromSetup);
        break;
      case 'create_product':
        page = CreateProductPage(showSetupProgress: fromSetup);
        break;
      case 'create_master_product':
        page = CreateProductPage(showSetupProgress: fromSetup);
        break;
      case 'create_payment_method':
        page = PaymentMethodsPage(showSetupProgress: fromSetup);
        break;
      case 'create_table':
        page = TablesPage(showSetupProgress: fromSetup);
        break;
      case 'create_employee':
        page = EmployeesPage(showSetupProgress: fromSetup);
        break;
      default:
        return;
    }

    final routePage = page;
    final icon = switch (step) {
      'create_product' || 'create_master_product' => Icons.shopping_bag_rounded,
      'create_payment_method' => Icons.payments_rounded,
      'create_table' => Icons.table_restaurant_rounded,
      'create_employee' => Icons.badge_rounded,
      _ => Icons.store_mall_directory_rounded,
    };
    await _pushSection(
      routePage,
      icon: icon,
      tooltip: _stepLabel(step),
      after: () async {
        if (!mounted) return;
        await context.read<AuthProvider>().refreshOwner();
        if (!mounted || !fromSetup) return;
        final next =
            context.read<AuthProvider>().owner?.onboarding?.nextStep ?? 'ready';
        if (next == 'ready') await _maybeSetupComplete();
      },
    );
  }

  Future<void> _maybeSetupComplete() async {
    if (_setupCompleteShown || !mounted) return;
    _setupCompleteShown = true;
    final openCashier = await showSetupCompleteDialog(context);
    if (openCashier == true && mounted) await _enterCashier();
  }

  Future<void> _enterCashier() async {
    final auth = context.read<AuthProvider>();
    final storeId =
        auth.owner?.onboarding?.selectedStoreId ??
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
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CashierHomePage()),
      (_) => false,
    );
  }

  Future<void> _openStocks(bool allowed) async {
    if (!allowed) {
      await _openAddonsPaywall(
        'Stok memerlukan add-on atau paket yang mendukung.',
        highlightFeatureKey: 'products_stocks',
        highlightAddonCode: 'stocks',
      );
      return;
    }

    await _pushSection(
      const OwnerStocksPage(),
      icon: Icons.inventory_2_rounded,
      tooltip: 'Stok',
    );
  }

  Future<void> _openReports(bool allowed) async {
    if (!allowed) {
      await _openAddonsPaywall(
        'Laporan penjualan memerlukan add-on atau paket yang mendukung.',
        highlightFeatureKey: 'report_sales',
        highlightAddonCode: 'reports',
      );
      return;
    }

    await _retireOpenSection();
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final storeId =
        auth.owner?.onboarding?.selectedStoreId ??
        auth.owner?.selectedPartnerId;
    final ok = await auth.enterCashierAsOwner(storeId: storeId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Gagal membuka laporan')),
      );
      return;
    }

    await _pushSection(
      const ReportsPage(),
      bar: _BarPage.report,
      after: () => auth.returnToOwner(),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
      await _pushSection(
        OwnerAddonsPage(
          highlightFeatureKey: highlightFeatureKey,
          highlightAddonCode: highlightAddonCode,
        ),
        icon: Icons.card_membership_rounded,
        tooltip: 'Paket',
        after: () async {
          if (mounted) await context.read<AuthProvider>().refreshOwner();
        },
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final owner = auth.owner;
    final stores = owner?.onboarding?.stores ?? const <OwnerStore>[];
    final hasStore = stores.isNotEmpty;
    final canReport = owner?.hasFeature('report_sales') ?? false;
    final unreadOrders = context.watch<NotificationsProvider>().unread;

    return _OwnerHost(
      state: this,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final nav = _sectionNav.currentState;
          if (nav != null && nav.canPop()) {
            nav.maybePop();
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: _bg,
          // Content scrolls behind the floating dock so it shows through
          // the transparent ring around the Kasir button.
          extendBody: true,
          bottomNavigationBar: _sheetOpen
              ? null
              : _OwnerDock(
                  cashierEnabled: hasStore,
                  reportEnabled: hasStore,
                  orderBadge: unreadOrders,
                  barPage: _barPage,
                  section: _section,
                  onCashier: hasStore ? _enterCashier : null,
                  onHome: _goHome,
                  onReport: hasStore ? () => _openReports(canReport) : null,
                  onAccount: () => _pushSection(
                    const OwnerAccountPage(),
                    bar: _BarPage.account,
                  ),
                ),
          body: const _OwnerSectionNavigator(),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final owner = auth.owner;
    final onboarding = owner?.onboarding;
    final nextStep = onboarding?.nextStep ?? 'ready';
    final stores = onboarding?.stores ?? const <OwnerStore>[];
    final selectedId = onboarding?.selectedStoreId ?? owner?.selectedPartnerId;
    final hasStore = stores.isNotEmpty;

    final canPromo = owner?.hasFeature('products_promotions') ?? false;
    final canScanTable = owner?.hasFeature('feature_scan_table') ?? false;
    final canStock = owner?.hasFeature('products_stocks') ?? false;

    final operasional = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Buku\nkasir',
        enabled: hasStore,
        badgeCount: _pendingCashBooks,
        onTap: hasStore
            ? () => _pushSection(
                const OwnerCashBookPage(),
                icon: Icons.account_balance_wallet_rounded,
                tooltip: 'Buku kasir',
                after: _loadPendingCashBooks,
              )
            : null,
      ),
      _MenuItemData(
        icon: canScanTable
            ? Icons.qr_code_2_rounded
            : Icons.table_restaurant_rounded,
        title: canScanTable ? 'QR\nMeja' : 'Meja',
        enabled: hasStore,
        onTap: hasStore
            ? () => _pushSection(
                const TablesPage(),
                icon: canScanTable
                    ? Icons.qr_code_2_rounded
                    : Icons.table_restaurant_rounded,
                tooltip: canScanTable ? 'QR Meja' : 'Meja',
              )
            : null,
      ),
      _MenuItemData(
        icon: Icons.badge_rounded,
        title: 'Pegawai',
        enabled: hasStore,
        onTap: hasStore
            ? () => _pushSection(
                const EmployeesPage(),
                icon: Icons.badge_rounded,
                tooltip: 'Pegawai',
                after: () async {
                  if (mounted) await auth.refreshOwner();
                },
              )
            : null,
      ),
    ];
    final katalog = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.shopping_bag_rounded,
        title: 'Produk',
        enabled: hasStore,
        onTap: hasStore
            ? () => _pushSection(
                const CreateProductPage(),
                icon: Icons.shopping_bag_rounded,
                tooltip: 'Produk',
                after: () async {
                  if (mounted) await auth.refreshOwner();
                },
              )
            : null,
      ),
      _MenuItemData(
        icon: Icons.inventory_2_rounded,
        title: 'Stok',
        enabled: hasStore,
        premiumLocked: hasStore && !canStock,
        onTap: hasStore ? () => _openStocks(canStock) : null,
      ),
      _MenuItemData(
        icon: Icons.local_offer_rounded,
        title: 'Promosi',
        premiumLocked: !canPromo,
        onTap: () {
          if (!canPromo) {
            _openAddonsPaywall(
              'Promosi menu memerlukan add-on atau paket yang mendukung.',
              highlightFeatureKey: 'products_promotions',
              highlightAddonCode: 'promotions',
            );
            return;
          }
          _pushSection(
            const PromotionsPage(),
            icon: Icons.local_offer_rounded,
            tooltip: 'Promosi',
          );
        },
      ),
    ];
    final kelola = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.store_mall_directory_rounded,
        title: 'Toko',
        enabled: hasStore,
        onTap: hasStore
            ? () => _pushSection(
                const StoreSettingsPage(),
                icon: Icons.store_mall_directory_rounded,
                tooltip: 'Toko',
                after: () async {
                  if (mounted) await auth.refreshOwner();
                },
              )
            : null,
      ),
      _MenuItemData(
        icon: Icons.card_membership_rounded,
        title: 'Paket',
        onTap: () => _pushSection(
          const OwnerAddonsPage(),
          icon: Icons.card_membership_rounded,
          tooltip: 'Paket',
          after: () async {
            if (mounted) await auth.refreshOwner();
          },
        ),
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
          controller: _menuScroll,
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
                  image: owner?.image,
                  onAccount: () => _pushSection(
                    const OwnerAccountPage(),
                    bar: _BarPage.account,
                  ),
                  showPoints: owner?.referralPointsEnabled != false,
                  pointsBalance: owner?.cavaaPointsBalance ?? 0,
                  onPoints: () => _pushSection(
                    const OwnerCavaaPointsPage(),
                    icon: Icons.stars_rounded,
                    tooltip: 'Cavaa Points',
                    after: () async {
                      if (mounted) await auth.refreshOwner();
                    },
                  ),
                  stores: stores,
                  selectedStoreId: selectedId,
                  selecting: _selectingStore || auth.isLoading,
                  canCreateStore:
                      owner?.canCreateStore ??
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
                    onTap: () => _pushSection(
                      const OwnerCashBookPage(),
                      icon: Icons.account_balance_wallet_rounded,
                      tooltip: 'Buku kasir',
                      after: _loadPendingCashBooks,
                    ),
                  ),
                ),
              ),
            if (nextStep != 'ready')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _SetupProgressBanner(
                    nextStep: nextStep,
                    onTap: () => _openStep(nextStep, fromSetup: true),
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
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _MenuSection(title: 'Operasional', items: operasional),
                      const _MenuDivider(),
                      _MenuSection(title: 'Katalog', items: katalog),
                      const _MenuDivider(),
                      _MenuSection(title: 'Kelola', items: kelola),
                    ],
                  ),
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
    this.badgeCount = 0,
    this.premiumLocked = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool enabled;
  final int badgeCount;
  final bool premiumLocked;
}

String _ownerPhotoUrl(String? raw) {
  if (raw == null) return '';
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.path.contains('/storage/')) {
      final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '$base${uri.path}$query';
    }
    return value;
  }
  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = value.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/storage/$clean';
}

String _pointsLabel(int value) {
  final raw = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write('.');
    buf.write(raw[i]);
  }
  return buf.toString();
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({
    required this.name,
    required this.email,
    required this.image,
    required this.onAccount,
    required this.showPoints,
    required this.pointsBalance,
    required this.onPoints,
    required this.stores,
    required this.selectedStoreId,
    required this.selecting,
    required this.canCreateStore,
    required this.onStoreSelected,
    required this.onCreateStore,
  });

  final String name;
  final String email;
  final String? image;
  final VoidCallback onAccount;
  final bool showPoints;
  final int pointsBalance;
  final VoidCallback onPoints;
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
                    clipBehavior: Clip.antiAlias,
                    child: _ownerPhotoUrl(image).isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: _brand,
                            size: 28,
                          )
                        : Image.network(
                            _ownerPhotoUrl(image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: _brand,
                              size: 28,
                            ),
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
            if (showPoints) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onPoints,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 15, color: _brand),
                      const SizedBox(width: 6),
                      const Text(
                        'Cavaa Points',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _pointsLabel(pointsBalance),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: _brand,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
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
              const LinearProgressIndicator(minHeight: 2, color: _brand),
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
    final parts = otherStores
        .map((store) {
          final name = store['name']?.toString() ?? 'Toko';
          final count = int.tryParse('${store['pending_count']}') ?? 0;
          return '$name ($count)';
        })
        .join(', ');
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
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _brand,
                ),
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

class _SetupProgressBanner extends StatelessWidget {
  const _SetupProgressBanner({required this.nextStep, required this.onTap});

  final String nextStep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeIndex = ownerSetupActiveIndex(nextStep);
    final total = ownerSetupSteps.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _brand.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lanjutkan setup',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${activeIndex + 1}/$total',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _brand.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _brand.withValues(alpha: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            color: i <= activeIndex
                                ? const Color(0xFF047857)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      _SetupDot(
                        label: ownerSetupSteps[i].title,
                        status: ownerSetupStatusFor(i, nextStep),
                      ),
                    ],
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

class _SetupDot extends StatelessWidget {
  const _SetupDot({required this.label, required this.status});

  final String label;
  final OwnerSetupStepStatus status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == OwnerSetupStepStatus.done;
    final isActive = status == OwnerSetupStepStatus.active;
    final color = isDone
        ? const Color(0xFF047857)
        : isActive
        ? _brand
        : const Color(0xFFD1D5DB);

    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone || isActive ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : isActive
                ? const Center(
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive
                  ? _brand
                  : isDone
                  ? const Color(0xFF047857)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = items.isEmpty ? 1 : items.length;
              const maxTile = 110.0;
              final tileWidth = (constraints.maxWidth / count).clamp(
                0.0,
                maxTile,
              );
              final iconSize = tileWidth < 96 ? 46.0 : 50.0;
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: tileWidth,
                        child: _MenuIconButton(
                          item: item,
                          iconSize: iconSize,
                          iconGlyphSize: 22,
                          labelSize: 11.5,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OwnerHost extends InheritedWidget {
  const _OwnerHost({required this.state, required super.child});

  final _OwnerHomePageState state;

  static _OwnerHomePageState of(BuildContext context) {
    final host = context.dependOnInheritedWidgetOfExactType<_OwnerHost>();
    assert(host != null, 'OwnerHost tidak ditemukan');
    return host!.state;
  }

  @override
  bool updateShouldNotify(_OwnerHost oldWidget) => true;
}

class _OwnerSectionNavigator extends StatelessWidget {
  const _OwnerSectionNavigator();

  @override
  Widget build(BuildContext context) {
    final state = _OwnerHost.of(context);
    return DockOverlapScope(
      child: Navigator(
        key: state._sectionNav,
        observers: [state._sheetObserver],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => const _OwnerDashboard(),
        ),
      ),
    );
  }
}

/// Tracks bottom sheets opened on the section navigator so the dock, which
/// floats over the body, can step aside while one is showing.
class _SheetObserver extends NavigatorObserver {
  _SheetObserver(this.onChanged);

  final ValueChanged<int> onChanged;
  var _open = 0;

  void _update(Route<dynamic> route, int delta) {
    if (route is! ModalBottomSheetRoute) return;
    _open = (_open + delta).clamp(0, 1 << 20);
    onChanged(_open);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route, -1);
}

class _OwnerDashboard extends StatelessWidget {
  const _OwnerDashboard();

  @override
  Widget build(BuildContext context) {
    return _OwnerHost.of(context)._buildMenu(context);
  }
}

class _OwnerDock extends StatelessWidget {
  const _OwnerDock({
    required this.cashierEnabled,
    required this.reportEnabled,
    required this.orderBadge,
    required this.barPage,
    required this.section,
    required this.onCashier,
    required this.onHome,
    required this.onReport,
    required this.onAccount,
  });

  final bool cashierEnabled;
  final bool reportEnabled;
  final int orderBadge;
  final _BarPage barPage;
  final _OpenSection? section;
  final VoidCallback? onCashier;
  final VoidCallback onHome;
  final VoidCallback? onReport;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 64,
              padding: const EdgeInsets.fromLTRB(7, 7, 4, 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      // Paints the whole dock background with a transparent
                      // ring cut around the Kasir pill.
                      child: CustomPaint(
                        painter: _DockCutoutPainter(
                          dockSize: Size(constraints.maxWidth, 64),
                          cellOffset: const Offset(7, 7),
                          gap: 3,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _DockCashier(
                            enabled: cashierEnabled,
                            badgeCount: orderBadge,
                            onTap: onCashier,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockItem(
                    icon: Icons.home_rounded,
                    tooltip: 'Beranda',
                    active: barPage == _BarPage.none && section == null,
                    onTap: onHome,
                  ),
                  _DockSectionSlot(section: section),
                  _DockItem(
                    icon: Icons.bar_chart_rounded,
                    tooltip: 'Laporan',
                    enabled: reportEnabled,
                    active: barPage == _BarPage.report,
                    onTap: onReport,
                  ),
                  _DockItem(
                    icon: Icons.person_rounded,
                    tooltip: 'Akun',
                    active: barPage == _BarPage.account,
                    onTap: onAccount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockCutoutPainter extends CustomPainter {
  const _DockCutoutPainter({
    required this.dockSize,
    required this.cellOffset,
    required this.gap,
  });

  final Size dockSize;
  final Offset cellOffset;
  final double gap;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = (-cellOffset) & dockSize;
    final outer = RRect.fromRectAndRadius(outerRect, const Radius.circular(32));
    final hole = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(gap),
      Radius.circular(size.height / 2 + gap),
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(hole),
    );

    canvas.drawPath(
      path.shift(const Offset(0, 6)),
      Paint()
        ..color = _brand.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, Paint()..shader = _gradient.createShader(outerRect));
  }

  @override
  bool shouldRepaint(_DockCutoutPainter oldDelegate) =>
      oldDelegate.dockSize != dockSize ||
      oldDelegate.cellOffset != cellOffset ||
      oldDelegate.gap != gap;
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.enabled = true,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: active
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slot for the open section's icon. The slot width and the icon scale share
/// one animation value, so the icon zooms in/out in step with the items
/// sliding aside to make room for it.
class _DockSectionSlot extends StatefulWidget {
  const _DockSectionSlot({required this.section});

  final _OpenSection? section;

  @override
  State<_DockSectionSlot> createState() => _DockSectionSlotState();
}

class _DockSectionSlotState extends State<_DockSectionSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.section == null ? 0 : 1,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  late _OpenSection? _shown = widget.section;

  @override
  void didUpdateWidget(covariant _DockSectionSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final section = widget.section;
    if (section != null) {
      _shown = section;
      _controller.forward();
    } else if (oldWidget.section != null) {
      _controller.reverse().whenComplete(() {
        if (mounted && widget.section == null) setState(() => _shown = null);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final shown = _shown;
        final t = _t.value;
        if (shown == null || t <= 0) {
          return const SizedBox(width: 0, height: 48);
        }
        return ClipRect(
          child: Align(
            widthFactor: t,
            child: Transform.scale(
              scale: t,
              child: _DockItem(
                key: ValueKey(shown.tooltip),
                icon: shown.icon,
                tooltip: shown.tooltip,
                active: true,
                onTap: () {},
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _KasirLayout { full, medium, compact }

class _KasirBadge extends StatelessWidget {
  const _KasirBadge({required this.count, this.compact = false});

  final int count;

  /// Smaller variant drawn over the icon, with a red ring so it stands out
  /// against the pill.
  final bool compact;

  static const style = TextStyle(
    color: _brand,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static String text(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      constraints: BoxConstraints(minWidth: compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: compact
            ? Border.all(color: const Color(0xFF8E1103), width: 1.5)
            : null,
      ),
      child: Text(text(count), textAlign: TextAlign.center, style: style),
    );
  }
}

class _DockCashier extends StatelessWidget {
  const _DockCashier({
    required this.enabled,
    required this.badgeCount,
    required this.onTap,
  });

  final bool enabled;
  final int badgeCount;
  final VoidCallback? onTap;

  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 15,
  );
  static const _icon = Icon(
    Icons.point_of_sale_rounded,
    color: Colors.white,
    size: 22,
  );

  /// Picks the richest layout that fits [width]: label + inline badge, then
  /// label with the badge over the icon, then the icon alone.
  _KasirLayout _layoutFor(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    final label = measure('Kasir', _labelStyle);
    final badge = badgeCount > 0
        ? (measure(_KasirBadge.text(badgeCount), _KasirBadge.style) + 12).clamp(
            18.0,
            double.infinity,
          )
        : 0.0;

    final full = 32 + 22 + 8 + label + (badgeCount > 0 ? 8 + badge : 0);
    if (full <= width) return _KasirLayout.full;
    // The overlaid badge pokes ~10 past the icon; the row gap absorbs it.
    final medium = 24 + 22 + (badgeCount > 0 ? 12 : 8) + label;
    if (medium <= width) return _KasirLayout.medium;
    return _KasirLayout.compact;
  }

  Widget _iconWithBadge() {
    if (badgeCount <= 0) return _icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _icon,
        Positioned(
          top: -7,
          right: -11,
          child: _KasirBadge(count: badgeCount, compact: true),
        ),
      ],
    );
  }

  Widget _buildLayout(_KasirLayout layout) {
    // FittedBox keeps the content from ever overflowing: while switching
    // layouts, and on extreme widths/text scales.
    switch (layout) {
      case _KasirLayout.full:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icon,
                const SizedBox(width: 8),
                const Text('Kasir', style: _labelStyle, maxLines: 1),
                if (badgeCount > 0) ...[
                  const SizedBox(width: 8),
                  _KasirBadge(count: badgeCount),
                ],
              ],
            ),
          ),
        );
      case _KasirLayout.medium:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconWithBadge(),
                SizedBox(width: badgeCount > 0 ? 12 : 8),
                const Text('Kasir', style: _labelStyle, maxLines: 1),
              ],
            ),
          ),
        );
      case _KasirLayout.compact:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                // Room for the overlaid badge inside the fitted box.
                padding: EdgeInsets.only(
                  top: badgeCount > 0 ? 7 : 0,
                  right: badgeCount > 0 ? 11 : 0,
                ),
                child: _iconWithBadge(),
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
            ),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Tooltip(
              message: 'Kasir',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _layoutFor(context, constraints.maxWidth);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, ?current],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(layout),
                      child: _buildLayout(layout),
                    ),
                  );
                },
              ),
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
    final locked = item.premiumLocked && enabled;
    final iconBg = locked
        ? const Color(0xFFF3F4F6)
        : _brand.withValues(alpha: 0.10);
    final iconColor = locked ? const Color(0xFF6B7280) : _brand;
    final titleColor = locked ? const Color(0xFF4B5563) : Colors.black87;

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
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: iconGlyphSize,
                          color: iconColor,
                        ),
                      ),
                      if (locked)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Coba',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        )
                      else if (item.badgeCount > 0)
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
                    color: titleColor,
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
