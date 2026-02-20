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

import '/features/cashier/data/orders_api.dart';
import '/features/cashier/data/models/orders_repository.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';

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

  // ===== Repos (biar ga bikin berkali2) =====
  late final OrdersRepository _ordersRepo;
  late final PaymentProvider _payVm;
  late final ProcessProvider _procVm;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ordersRepo = OrdersRepository(api: OrdersApi(), storage: SecureStorageService());

    _payVm = PaymentProvider(_ordersRepo)..load();
    _procVm = ProcessProvider(_ordersRepo)..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // saat balik ke app, coba connect lagi ke default
    if (state == AppLifecycleState.resumed) {
      // silent biar ga ganggu user kalau gagal
      context.read<PrinterManager>().connectDefault(silent: true);
    }

    // OPTIONAL: kalau kamu mau disconnect saat background
    // if (state == AppLifecycleState.paused) {
    //   context.read<PrinterManager>().disconnect();
    // }
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
          // debugPrint('✅ OrderCreated: $data');

          // 🔔 bunyi notif masuk
          await SoundService.instance.playNotification();

          // tetap simpan ke provider notif
          notif.pushFromPusher(data);
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
    _pusherSvc.stop();
    _payVm.dispose();
    _procVm.dispose();

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

  void _openBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open barcode scanner...')),
    );
  }

  // ======= INI KUNCI: notif click -> pindah tab + refresh + fokus & blink =======
  Future<void> _handleNotifTap(dynamic n) async {
    // asumsi model notif kamu punya:
    // n.status (String), n.orderId (int?) atau n.id, n.code
    final st = (n.status ?? '').toString().toUpperCase();
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
    if (targetIndex == 1) {
      _payVm.setQuery('');
      await _payVm.load();
    } else if (targetIndex == 2) {
      _procVm.setQuery('');
      await _procVm.load();
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
    // ✅ INI yang kamu ubah: build milik _CashierHomePageState
    const brand = Color(0xFFAE1504);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PaymentProvider>.value(value: _payVm),
        ChangeNotifierProvider<ProcessProvider>.value(value: _procVm),
      ],
      child: PopScope(
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
                onTapItem: _handleNotifTap, // ✅ pakai handler baru
              ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              const purchase_tab.PurchaseTab(),

              // ✅ kirim focusOrderId ke tab supaya bisa blink + scroll
              payment_tab.PaymentTab(focusOrderId: _focusOrderId),

              process_tab.ProcessTab(focusOrderId: _focusOrderId),

              const done_tab.DoneTab(),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
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
                    ),
                    _NavItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Selesai',
                      active: _index == 3,
                      badge: 2,
                      onTap: () => _onTap(3),
                    ),
                  ],
                ),
              ),
            ),
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
