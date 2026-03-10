import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

import '/features/cashier/presentation/widgets/notif_bell_button.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';

import '/features/cashier/presentation/realtime/pusher_orders_service.dart';
import '/core/services/sound_service.dart';
import '/core/storage/secure_storage_service.dart';

import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';

import '/core/services/push_notification_service.dart';

import 'tabs/purchase_tab.dart' as purchase_tab;
import 'tabs/payment_tab.dart' as payment_tab;
import 'tabs/process_tab.dart' as process_tab;
import 'tabs/done_tab.dart' as done_tab;

import '/features/cashier/presentation/pages/printer/printer_settings_page.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> with WidgetsBindingObserver {
  // ===== Realtime =====
  final _pusherSvc = PusherOrdersService(SecureStorageService());
  bool _pusherStarted = false;

  // ===== UI =====
  DateTime? _lastBackPressed;
  int _index = 0;

  // ===== Focus/highlight order =====
  int? _focusOrderId;
  Timer? _focusTimer;
  Timer? _paymentReloadDebounce;
  Timer? _processReloadDebounce;
  Timer? _doneReloadDebounce;
  Timer? _resumeReloadDebounce;

  StreamSubscription<Map<String, dynamic>>? _fcmMessageSub;
  StreamSubscription<Map<String, dynamic>>? _fcmTapSub;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      await context.read<NotificationsProvider>().loadFromStorage();
    });

    _listenFcmEvents();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrinterManager>().connectDefault(silent: true);

      _refreshAfterResume();
    }
  }

  void _refreshAfterResume() {
    _resumeReloadDebounce?.cancel();
    _resumeReloadDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      try {
        final payVm = context.read<PaymentProvider>();
        final procVm = context.read<ProcessProvider>();
        final doneVm = context.read<DoneProvider>();

        payVm.setQuery('');
        procVm.setQuery('');

        await Future.wait([
          payVm.load(),
          procVm.load(),
          doneVm.load(),
        ]);
      } catch (e) {
        debugPrint('❌ refresh after resume failed: $e');
      }
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startRealtimeIfReady();
  }

  Future<void> _startRealtimeIfReady() async {
    if (!mounted || _pusherStarted) return;

    final auth = context.read<AuthProvider>();
    final partnerId = auth.user?.partnerId;

    if (partnerId == null) {
      debugPrint('PUSHER: partnerId null, belum start');
      return;
    }

    final notif = context.read<NotificationsProvider>();

    try {
      await _pusherSvc.start(
        partnerId: partnerId,
        onOrderCreated: (data) async {
          // await SoundService.instance.playNotification();

          await notif.pushFromPusher(data);

          _refreshTabByRealtimeData(data);
        },
      );

      _pusherStarted = true;
      // debugPrint('✅ PUSHER STARTED partner=$partnerId');
    } catch (e, st) {
      debugPrint('❌ PUSHER start error: $e');
      debugPrint('$st');
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _paymentReloadDebounce?.cancel();
    _processReloadDebounce?.cancel();
    _doneReloadDebounce?.cancel();
    _resumeReloadDebounce?.cancel();

    _fcmMessageSub?.cancel();
    _fcmTapSub?.cancel();

    _pusherSvc.stop();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _onTap(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _handleFcmTap(Map<String, dynamic> data) async {
    final st = (data['status'] ?? data['order_status'] ?? '')
        .toString()
        .toUpperCase();

    int targetIndex = 1;

    if (st == 'UNPAID' || st == 'EXPIRED' || st == 'PAYMENT REQUEST') {
      targetIndex = 1;
    } else if (st == 'PAID' || st == 'PROCESSED') {
      targetIndex = 2;
    } else if (st == 'SERVED' || st == 'DONE' || st == 'FINISHED') {
      targetIndex = 3;
    }

    final int? orderId = _pickOrderId(data);

    if (mounted) setState(() => _index = targetIndex);

    final payVm = context.read<PaymentProvider>();
    final procVm = context.read<ProcessProvider>();
    final doneVm = context.read<DoneProvider>();

    if (targetIndex == 1) {
      payVm.setQuery('');
      await payVm.load();
    } else if (targetIndex == 2) {
      procVm.setQuery('');
      await procVm.load();
    } else if (targetIndex == 3) {
      await doneVm.load();
    }

    if (orderId != null && orderId > 0 && mounted) {
      _focusTimer?.cancel();

      setState(() => _focusOrderId = null);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _focusOrderId = orderId);

        _focusTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _focusOrderId = null);
        });
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buka order ${(data['code'] ?? data['booking_order_code'] ?? '').toString()}'),
      ),
    );
  }

  void _listenFcmEvents() {
    _fcmMessageSub = PushNotificationService.instance.onMessageReceived.listen(
      (data) async {
        debugPrint('🔔 FCM received event: $data');

        await context.read<NotificationsProvider>().pushFromFcm(data);

        _refreshTabByRealtimeData(data);
      },
    );

    _fcmTapSub = PushNotificationService.instance.onMessageTapped.listen(
      (data) async {
        debugPrint('👉 FCM tapped event: $data');

        await context.read<NotificationsProvider>().pushFromFcm(data);

        await _handleFcmTap(data);
      },
    );
  }

  void _openBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sementara anda belum dapat menggunakan fitur ini...')),
    );
  }

    void _debouncedReloadPayment() {
    _paymentReloadDebounce?.cancel();
    _paymentReloadDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final vm = context.read<PaymentProvider>();
      vm.setQuery('');
      unawaited(vm.load());
    });
  }

  void _debouncedReloadProcess() {
    _processReloadDebounce?.cancel();
    _processReloadDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final vm = context.read<ProcessProvider>();
      vm.setQuery('');
      unawaited(vm.load());
    });
  }

  void _debouncedReloadDone() {
    _doneReloadDebounce?.cancel();
    _doneReloadDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final vm = context.read<DoneProvider>();
      unawaited(vm.load());
    });
  }

  void _refreshTabByRealtimeData(Map<String, dynamic> data) {
    final status = (data['status'] ?? data['order_status'] ?? '')
        .toString()
        .toUpperCase();

    final source = (data['source'] ??
            data['from'] ??
            data['payment_method'] ??
            data['order_source'] ??
            '')
        .toString()
        .toUpperCase();

    // debugPrint('REALTIME status=$status source=$source');

    if (status == 'UNPAID' ||
        status == 'EXPIRED' ||
        status == 'PAYMENT REQUEST') {
      _debouncedReloadPayment();
      return;
    }

    if (status == 'PAID' || status == 'PROCESSED') {
      _debouncedReloadProcess();
      return;
    }

    if (status == 'SERVED' || status == 'DONE' || status == 'FINISHED') {
      _debouncedReloadDone();
      return;
    }

    // fallback kalau source mau ikut dipakai
    if (source == 'QRIS' || source == 'CASH' || source == 'MANUAL') {
      _debouncedReloadPayment();
    }
  }

  // ======= INI KUNCI: notif click -> pindah tab + refresh + fokus & blink =======
  Future<void> _handleNotifTap(dynamic n) async {
    final st = (n.status ?? '').toString().toUpperCase();
    final doneVm = context.read<DoneProvider>();
    // debugPrint('NOTIF RAW = $n');

    int targetIndex = 0;
    if (st == 'UNPAID' || st == 'EXPIRED' || st == 'PAYMENT REQUEST') {
      targetIndex = 1; // pembayaran
    } else if (st == 'PAID' || st == 'PROCESSED') {
      targetIndex = 2; // proses
    } else if (st == 'SERVED' || st == 'DONE' || st == 'FINISHED') {
      targetIndex = 3; // selesai
    } else {
      // fallback, kalau status tidak dikenal
      targetIndex = 1;
    }

    // ambil orderId dari notif
    final int? orderId = _pickOrderId(n);
    // debugPrint('NOTIF TAP status=$st orderId=$orderId code=${n.code}');

    // 1) pindah tab
    if (mounted) setState(() => _index = targetIndex);

    // 2) refresh tab tujuan (tunggu selesai)
    final payVm = context.read<PaymentProvider>();
    final procVm = context.read<ProcessProvider>();

    if (targetIndex == 1) {
      payVm.setQuery('');
      await payVm.load();
    } else if (targetIndex == 2) {
      procVm.setQuery('');
      await procVm.load();
    } else if (targetIndex == 3) {
      await doneVm.load();
    }

    // 3) set focus setelah load + setelah frame (biar list sudah kebangun)
    if (orderId != null && orderId > 0 && mounted) {
      _focusTimer?.cancel();

      // trik: reset dulu supaya walau orderId sama, tetap dianggap "berubah"
      setState(() => _focusOrderId = null);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _focusOrderId = orderId);

        _focusTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _focusOrderId = null);
        });
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buka order ${n.code ?? ''}'.trim())),
    );
  }

  int? _pickOrderId(dynamic n) {
    try {
      // ✅ kasus notif kamu (IncomingOrderNotif)
      if (n is IncomingOrderNotif) return n.id;

      // ✅ kalau suatu saat notif berubah jadi Map
      if (n is Map) {
        final v = n['id'] ?? n['orderId'] ?? n['order_id'] ?? n['booking_order_id'];
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString());
      }

      // ✅ fallback object lain
      final v = (n.id ?? n.orderId ?? n.order_id);
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }


  // ======= BACK PRESS double-tap exit =======
  Future<void> _handleBack() async {
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar aplikasi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    final isTablet = shortestSide >= 600;
    // final useSideNav = isLandscape && isTablet;
    final useSideNav = isLandscape;

    final paymentCount = context.watch<PaymentProvider>().items.length;
    final processCount = context.watch<ProcessProvider>().items.length;
    final doneCount = context.watch<DoneProvider>().items.length;

    final content = IndexedStack(
      index: _index,
      children: [
        const purchase_tab.PurchaseTab(),
        payment_tab.PaymentTab(focusOrderId: _focusOrderId),
        process_tab.ProcessTab(focusOrderId: _focusOrderId),
        const done_tab.DoneTab(),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        drawer: _AppDrawer(
          onOpenPrinterSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
            );
          },
          onLogout: _logout,
        ),
        appBar: AppBar(
          titleSpacing: 12,
          title: Row(
            children: [
              Image.asset(
                'assets/images/cavaa_logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'Cavaa',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          actions: [
            const PrinterStatusDot(),
            NotifBellButton(
              onTapItem: _handleNotifTap,
            ),
          ],
        ),
        body: useSideNav
          ? Row(
              children: [
                _SideNav(
                  currentIndex: _index,
                  onTap: _onTap,
                  onBarcodeTap: _openBarcode,
                  iconOnly: true,
                  paymentCount: paymentCount,
                  processCount: processCount,
                  doneCount: doneCount,
                ),
                Expanded(child: content),
              ],
            )
          : content,
        bottomNavigationBar: useSideNav
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Pembelian',
                        active: _index == 0,
                        onTap: () => _onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.payments_outlined,
                        label: 'Pembayaran',
                        active: _index == 1,
                        onTap: () => _onTap(1),
                        badge: paymentCount,
                      ),
                      _BarcodeNavItem(
                        active: false,
                        onTap: _openBarcode,
                      ),
                      _NavItem(
                        icon: Icons.sync_rounded,
                        label: 'Proses',
                        active: _index == 2,
                        onTap: () => _onTap(2),
                        badge: processCount,
                      ),
                      _NavItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Selesai',
                        active: _index == 3,
                        onTap: () => _onTap(3),
                        badge: doneCount,
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

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.currentIndex,
    required this.onTap,
    required this.onBarcodeTap,
    this.iconOnly = false,
    this.paymentCount = 0,
    this.processCount = 0,
    this.doneCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onBarcodeTap;
  final bool iconOnly;
  final int paymentCount;
  final int processCount;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    final media = MediaQuery.of(context);
    final leftInset = media.padding.left;

    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;

    final baseWidth = iconOnly
        ? (isTablet ? 72.0 : 90.0)
        : 96.0;

    final navWidth = baseWidth + leftInset.clamp(0.0, 24.0);

    final appBarBg =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return Container(
      width: navWidth,
      decoration: BoxDecoration(
        color: appBarBg,
        border: const Border(
          right: BorderSide(color: Color(0x1A000000), width: 1),
        ),
      ),
      child: SafeArea(
        right: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _SideNavItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Pembelian',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                  iconOnly: iconOnly,
                ),
                _SideNavItem(
                  icon: Icons.payments_outlined,
                  label: 'Pembayaran',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                  iconOnly: iconOnly,
                  badge: paymentCount,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: InkWell(
                      onTap: onBarcodeTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: iconOnly ? 44 : 56,
                        height: iconOnly ? 44 : 56,
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: brand.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: iconOnly ? 22 : 28,
                        ),
                      ),
                    ),
                  ),
                ),
                _SideNavItem(
                  icon: Icons.sync_rounded,
                  label: 'Proses',
                  active: currentIndex == 2,
                  onTap: () => onTap(2),
                  iconOnly: iconOnly,
                  badge: processCount,
                ),
                _SideNavItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Selesai',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                  iconOnly: iconOnly,
                  badge: doneCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.iconOnly = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool iconOnly;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final color = active ? brand : Colors.black54;
    final bg = active ? brand.withOpacity(0.10) : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: iconOnly ? 8 : 8,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            vertical: iconOnly ? 12 : 12,
            horizontal: iconOnly ? 0 : 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: iconOnly ? 22 : 24,
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!iconOnly) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PrinterStatusDot extends StatelessWidget {
  const PrinterStatusDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterManager>(
      builder: (_, pm, __) {
        final hasDefault = pm.defaultId != null;

        Color dot;
        if (!hasDefault) {
          dot = Colors.grey;
        } else if (pm.connState == PrinterConnState.connecting) {
          dot = Colors.orange;
        } else if (pm.connState == PrinterConnState.connected) {
          dot = Colors.green;
        } else {
          dot = Colors.red;
        }

        return IconButton(
          tooltip: !hasDefault
              ? 'Default printer belum dipilih'
              : (pm.isReady ? 'Printer siap' : (pm.connMessage ?? 'Printer belum connect')),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.print_outlined),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final color = active ? brand : Colors.black54;

    Widget iconWidget = Icon(icon, color: color);

    if (badge != null && badge! > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color),
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeNavItem extends StatelessWidget {
  const _BarcodeNavItem({
    required this.onTap,
    this.active = false,
  });

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: brand.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onOpenPrinterSettings,
    required this.onLogout,
  });

  final VoidCallback onOpenPrinterSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: brand),
              title: const Text('Pairing Printer'),
              subtitle: const Text('Bluetooth / Kabel (USB)'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenPrinterSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
