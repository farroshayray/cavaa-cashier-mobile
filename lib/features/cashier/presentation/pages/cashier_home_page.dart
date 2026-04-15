import 'dart:async';
import '/core/config/env.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

import '/features/cashier/presentation/widgets/notif_bell_button.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';

import '/features/cashier/presentation/realtime/pusher_orders_service.dart';
import '/core/storage/secure_storage_service.dart';

import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';

import '/core/services/push_notification_service.dart';
import '/core/services/in_app_apk_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'tabs/purchase_tab.dart' as purchase_tab;
import 'tabs/payment_tab.dart' as payment_tab;
import 'tabs/process_tab.dart' as process_tab;
import 'tabs/done_tab.dart' as done_tab;

import '/features/cashier/presentation/pages/printer/printer_settings_page.dart';
import '/features/cashier/presentation/pages/reports/reports_page.dart';
import '/core/services/connectivity_status_provider.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> with WidgetsBindingObserver {
  // ===== Realtime =====
  final _pusherSvc = PusherOrdersService(SecureStorageService());
  bool _pusherStarted = false;
  final InAppApkUpdater _apkUpdater = InAppApkUpdater();
  final ValueNotifier<double> _updateProgressNotifier = ValueNotifier<double>(0);

  bool _isDownloadingUpdate = false;
  bool _activeUpdateIsForce = false;

  // ===== UI =====
  DateTime? _lastBackPressed;
  int _index = 0;

  // ===== Focus/highlight order =====
  int? _focusOrderId;
  int _focusRequestKey = 0;
  Timer? _focusTimer;
  Timer? _paymentReloadDebounce;
  Timer? _processReloadDebounce;
  Timer? _doneReloadDebounce;
  Timer? _resumeReloadDebounce;

  bool? _lastOnlineState;

  StreamSubscription<Map<String, dynamic>>? _fcmMessageSub;
  StreamSubscription<Map<String, dynamic>>? _fcmTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenFcmEvents();

    Future.microtask(() async {
      final pendingTap =
          await PushNotificationService.instance.consumePendingNotificationTap();

      if (pendingTap != null && mounted) {
        await context.read<NotificationsProvider>().pushFromFcm(pendingTap);
        await _handleFcmTap(pendingTap);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupConnectivitySyncHook();
    });

    Future.microtask(() async {
      final pending =
          await PushNotificationService.instance.consumePendingForceLogout();
      if (pending != null && mounted) {
        await _handleForceLogout(pending);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrinterManager>().connectDefault(silent: true);
      _refreshAfterResume();

      Future.microtask(() async {
        try {
          final conn = context.read<ConnectivityStatusProvider>();
          if (conn.isOnline && !conn.isChecking) {
            await context.read<SyncService>().syncPendingOrders();

            if (!mounted) return;
            await Future.wait([
              context.read<PaymentProvider>().load(),
              context.read<ProcessProvider>().load(),
              context.read<DoneProvider>().load(),
            ]);
          }
        } catch (e) {
          debugPrint('❌ sync after resume failed: $e');
        }
      });

      Future.microtask(() async {
        final pending =
            await PushNotificationService.instance.consumePendingForceLogout();
        if (pending != null && mounted) {
          await _handleForceLogout(pending);
        }
      });
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

  void _setupConnectivitySyncHook() {
    final connectivityProvider = context.read<ConnectivityStatusProvider>();
    final syncService = context.read<SyncService>();

    connectivityProvider.onBackOnline = () async {
      debugPrint('🌐 koneksi kembali online, mulai sync pending orders...');
      await syncService.syncPendingOrders();

      if (!mounted) return;

      await Future.wait([
        context.read<PaymentProvider>().load(),
        context.read<ProcessProvider>().load(),
        context.read<DoneProvider>().load(),
      ]);
    };
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startRealtimeIfReady();
  }

  void _handleConnectivitySync() {
    final conn = context.read<ConnectivityStatusProvider>();

    if (conn.isChecking) return;

    final isOnlineNow = conn.isOnline;

    if (_lastOnlineState == isOnlineNow) return;

    _lastOnlineState = isOnlineNow;

    if (isOnlineNow) {
      Future.microtask(() async {
        try {
          await context.read<SyncService>().syncPendingOrders();
          if (!mounted) return;

          await Future.wait([
            context.read<PaymentProvider>().load(),
            context.read<ProcessProvider>().load(),
            context.read<DoneProvider>().load(),
          ]);
        } catch (e) {
          debugPrint('❌ auto sync on reconnect failed: $e');
        }
      });
    }
  }

  Future<void> _confirmLogout() async {
    // 🔥 ambil status pending dulu
    final hasPending = await context.read<SyncService>().hasPendingData();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: Text(
          hasPending
              ? '⚠️ Masih ada data yang belum tersinkronisasi.\n\nLogout akan menghapus data tersebut.'
              : 'Apakah Anda yakin ingin logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 114, 9, 2),
              foregroundColor: Colors.white, // 🔥 ini kuncinya
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout();
    }
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

  Future<void> _cancelApkDownload() async {
    _apkUpdater.cancelDownload();

    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    setState(() {
      _isDownloadingUpdate = false;
      _activeUpdateIsForce = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download update dibatalkan')),
    );
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  Future<int?> _resolveTabIndexByOrderId(int orderId) async {
    final payVm = context.read<PaymentProvider>();
    final procVm = context.read<ProcessProvider>();
    final doneVm = context.read<DoneProvider>();

    payVm.setQuery('');
    procVm.setQuery('');
    doneVm.setQuery('');

    await Future.wait([
      payVm.load(),
      procVm.load(),
      doneVm.load(),
    ]);

    final inPayment = payVm.items.any((e) => _toId(e['id']) == orderId);
    if (inPayment) return 1;

    final inProcess = procVm.items.any((e) => _toId(e['id']) == orderId);
    if (inProcess) return 2;

    final inDone = doneVm.items.any((e) => _toId(e['id']) == orderId);
    if (inDone) return 3;

    return null;
  }

  @override
  void dispose() {
    try {
      context.read<ConnectivityStatusProvider>().onBackOnline = null;
    } catch (_) {}

    _focusTimer?.cancel();
    _paymentReloadDebounce?.cancel();
    _processReloadDebounce?.cancel();
    _doneReloadDebounce?.cancel();
    _resumeReloadDebounce?.cancel();

    _fcmMessageSub?.cancel();
    _fcmTapSub?.cancel();

    _updateProgressNotifier.dispose();
    _pusherSvc.stop();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _onTap(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    await context.read<NotificationsProvider>().clear();
    await context.read<PaymentProvider>().clearStateAndCache();
    await context.read<ProcessProvider>().clearStateAndCache();
    await context.read<DoneProvider>().clearStateAndCache();
    await context.read<SyncService>().clearCashierSessionData();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _handleFcmTap(Map<String, dynamic> data) async {
    final int? orderId = _pickOrderId(data);

    if (orderId == null || orderId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID order tidak valid')),
      );
      return;
    }

    await Future.wait([
      context.read<PaymentProvider>().load(),
      context.read<ProcessProvider>().load(),
      context.read<DoneProvider>().load(),
    ]);

    final targetIndex = await _resolveTabIndexByOrderId(orderId);

    if (!mounted) return;

    if (targetIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId tidak ditemukan di tab mana pun')),
      );
      return;
    }

    setState(() => _index = targetIndex);

    _focusTimer?.cancel();

    setState(() {
      _focusOrderId = orderId;
      _focusRequestKey++;
    });

    _focusTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _focusOrderId = null);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Buka order ${(data['code'] ?? data['booking_order_code'] ?? '').toString()}',
        ),
      ),
    );
  }

  Future<void> _showDownloadingDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Downloading Update'),
        content: ValueListenableBuilder<double>(
          valueListenable: _updateProgressNotifier,
          builder: (context, progress, _) {
            final isKnownProgress = progress >= 0 && progress <= 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sedang mengunduh APK versi terbaru...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: isKnownProgress ? progress : null,
                ),
                const SizedBox(height: 8),
                Text(
                  isKnownProgress
                      ? '${(progress * 100).toStringAsFixed(0)}%'
                      : 'Downloading...',
                ),
              ],
            );
          },
        ),
        actions: [
          if (!_activeUpdateIsForce)
            TextButton(
              onPressed: _cancelApkDownload,
              child: const Text('Batalkan'),
            ),
        ],
      ),
    );
  }

  Future<void> _startApkUpdate(String apkUrl, {required bool force}) async {
    if (apkUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link update tidak tersedia')),
      );
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isDownloadingUpdate = true;
          _activeUpdateIsForce = force;
        });
      }

      _updateProgressNotifier.value = 0;

      unawaited(_showDownloadingDialog());

      await _apkUpdater.downloadAndInstall(
        apkUrl: apkUrl,
        onProgress: (received, total) {
          if (!mounted) return;

          if (total > 0) {
            _updateProgressNotifier.value = received / total;
          } else {
            _updateProgressNotifier.value = -1;
          }
        },
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } on DioException catch (e) {
      final wasCancelled = CancelToken.isCancel(e);

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (!wasCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              force
                  ? 'Gagal mengunduh update. Silakan coba lagi.'
                  : 'Gagal mengunduh update.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('apk update failed: $e');

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            force
                ? 'Gagal mengunduh update. Silakan coba lagi.'
                : 'Gagal mengunduh update.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingUpdate = false;
          _activeUpdateIsForce = false;
        });
      }
    }
  }

  Future<void> _handleManualUpdateTap() async {
    final auth = context.read<AuthProvider>();
    final data = auth.appUpdate;

    if (data == null) return;

    final title = (data['title'] ?? 'Update Available').toString();
    final message = (data['message'] ?? 'A new version is available.').toString();
    final storeUrl = (data['store_url'] ?? '').toString();
    final force = data['force_update'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !force,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _startApkUpdate(storeUrl, force: force);
    }
  }

  void _listenFcmEvents() {
    _fcmMessageSub = PushNotificationService.instance.onMessageReceived.listen(
      (data) async {
        // debugPrint('🔔 FCM received event: $data');

        final type = (data['type'] ?? '').toString();

        if (type == 'force_logout') {
          await _handleForceLogout(data);
          return;
        }

        await context.read<NotificationsProvider>().pushFromFcm(data);
        _refreshTabByRealtimeData(data);
      },
    );

    _fcmTapSub = PushNotificationService.instance.onMessageTapped.listen(
      (data) async {
        // debugPrint('👉 FCM tapped event: $data');

        final type = (data['type'] ?? '').toString();

        if (type == 'force_logout') {
          await _handleForceLogout(data);
          return;
        }

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

  Future<void> _handleForceLogout(Map<String, dynamic> data) async {
    final newDeviceName = (data['new_device_name'] ?? '-').toString();
    final newDevicePlatform = (data['new_device_platform'] ?? '-').toString();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sesi Berakhir'),
        content: Text(
          'Akun ini login di perangkat lain.\n\n'
          'Device: $newDeviceName\n'
          'Platform: $newDevicePlatform',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    await context.read<NotificationsProvider>().clear();
    await context.read<PaymentProvider>().clearStateAndCache();
    await context.read<ProcessProvider>().clearStateAndCache();
    await context.read<DoneProvider>().clearStateAndCache();
    await context.read<SyncService>().clearCashierSessionData();
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // ======= INI KUNCI: notif click -> pindah tab + refresh + fokus & blink =======
  Future<void> _handleNotifTap(dynamic n) async {
    final int? orderId = _pickOrderId(n);
    final doneVm = context.read<DoneProvider>();

    if (orderId == null || orderId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID order tidak valid')),
      );
      return;
    }

    final targetIndex = await _resolveTabIndexByOrderId(orderId);

    if (!mounted) return;

    if (targetIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId tidak ditemukan di tab mana pun')),
      );
      return;
    }

    setState(() => _index = targetIndex);

    if (orderId > 0) {
      _focusTimer?.cancel();

      setState(() {
        _focusOrderId = orderId;
        _focusRequestKey++;
      });

      _focusTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _focusOrderId = null);
        }
      });
    }

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
    final auth = context.watch<AuthProvider>();
    final appUpdateData = auth.appUpdate;
    final hasAppUpdate = appUpdateData?['update_available'] == true;
    
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
        payment_tab.PaymentTab(
          focusOrderId: _focusOrderId,
          focusRequestKey: _focusRequestKey,
        ),
        process_tab.ProcessTab(
          focusOrderId: _focusOrderId,
          focusRequestKey: _focusRequestKey,
        ),
        done_tab.DoneTab(
          focusOrderId: _focusOrderId,
          focusRequestKey: _focusRequestKey,
        ),
      ],
    );

    _handleConnectivitySync();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        drawer: _AppDrawer(
          onOpenReports: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsPage()),
            );
          },
          onOpenPrinterSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
            );
          },
          onTapUpdate: hasAppUpdate && !_isDownloadingUpdate
              ? _handleManualUpdateTap
              : null,
          showUpdateBadge: hasAppUpdate,
          onLogout: _confirmLogout,
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.menu),
                    if (hasAppUpdate)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
            const OnlineStatusChip(),
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
                      // _BarcodeNavItem(
                      //   active: false,
                      //   onTap: _openBarcode,
                      // ),
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

class OnlineStatusChip extends StatelessWidget {
  const OnlineStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityStatusProvider>(
      builder: (_, conn, __) {
        Color dotColor;
        String label;

        if (conn.isChecking) {
          dotColor = Colors.orange;
          label = 'Checking';
        } else if (conn.isOnline) {
          dotColor = Colors.green;
          label = 'Online';
        } else {
          dotColor = Colors.red;
          label = 'Offline';
        }

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
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
    required this.onOpenReports,
    required this.onOpenPrinterSettings,
    required this.onLogout,
    required this.showUpdateBadge,
    this.onTapUpdate,
  });

  final VoidCallback onOpenReports;
  final VoidCallback onOpenPrinterSettings;
  final VoidCallback onLogout;
  final bool showUpdateBadge;
  final VoidCallback? onTapUpdate;

  String? _buildUserImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return null;

    final raw = imagePath.trim();

    // kalau backend suatu saat sudah kirim full URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanPath = raw.replaceFirst(RegExp(r'^/'), '');

    // pola umum file upload Laravel/public storage
    return '$base/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    final auth = context.watch<AuthProvider>();
    final fullName = auth.user?.name ?? 'User';
    final userName = auth.user?.userName ?? 'UserName';
    final imageUrl = _buildUserImageUrl(auth.user?.image);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UserAvatar(imageUrl: imageUrl),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Cashier Account',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_document, color: brand),
                    title: const Text('Laporan'),
                    subtitle: const Text('Lihat laporan penjualan'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenReports();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print_outlined, color: brand),
                    title: const Text('Pairing Printer'),
                    subtitle: const Text('Bluetooth / Kabel (USB)'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenPrinterSettings();
                    },
                  ),
                  if (onTapUpdate != null) ...[
                    const Divider(),
                    ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.system_update_alt, color: brand),
                          if (showUpdateBadge)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: const Text('Update App'),
                      subtitle: const Text('Versi baru tersedia'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onTapUpdate?.call();
                      },
                    ),
                  ],
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

            // 🔥 INI FOOTER VERSION
            const Divider(),
            const _AppVersionText(),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: brand,
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 28,
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: brand.withOpacity(0.12),
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 48,
              height: 48,
              color: brand,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 48,
              height: 48,
              color: brand.withOpacity(0.10),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppVersionText extends StatelessWidget {
  const _AppVersionText();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final info = snapshot.data!;
        final version = info.version;
        final build = info.buildNumber;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Version $version ($build)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        );
      },
    );
  }
}
