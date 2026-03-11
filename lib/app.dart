import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';

import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';

import 'features/cashier/data/models/purchase_repository.dart';
import 'features/cashier/presentation/providers/purchase_provider.dart';
import '/features/cashier/data/purchase_api.dart';

import 'features/auth/presentation/pages/splash_page.dart';
import 'core/navigation/app_navigator.dart';
import 'features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/preference/printer_prefs.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';

import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/data/orders_api.dart';
import '/features/cashier/data/models/orders_repository.dart';

class CavaaApp extends StatefulWidget {
  const CavaaApp({super.key});

  @override
  State<CavaaApp> createState() => _CavaaAppState();
}

class _CavaaAppState extends State<CavaaApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();

    () async {
      final initial = await _appLinks.getInitialLink();
      if (!mounted) return;
      if (initial != null) _handleUri(initial);
    }();

    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _handleUri(uri);
    }, onError: (e) {
    });
  }

  Future<void> _refreshAfterPayment(BuildContext ctx) async {
    try {
      await ctx.read<PaymentProvider>().load();

      // coba langsung
      await ctx.read<ProcessProvider>().load();

    } catch (e) {
      debugPrint('❌ refresh after payment failed: $e');
    }
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'cavapos' && uri.host == 'payment') {
      final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

      if (status == 'success') {
        appNavigatorKey.currentState?.popUntil((r) => r.isFirst);

        final ctx = appNavigatorKey.currentContext;
        if (ctx != null) {
          try {
            ctx.read<PurchaseProvider>().clearCartAndReset();
            _refreshAfterPayment(ctx);
          } catch (e) {
            debugPrint('❌ post-payment refresh failed: $e');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorageService();
    final dioClient = DioClient(storage);

    final authApi = AuthApi(dioClient);
    final authRepo = AuthRepository(api: authApi, storage: storage);

    final purchaseApi = PurchaseApi(dioClient.dio);
    final purchaseRepo = PurchaseRepository(api: purchaseApi);

    final ordersApi = OrdersApi(dioClient.dio);
    final ordersRepo = OrdersRepository(api: ordersApi);
    // ⚠️ sesuaikan: kalau PurchaseRepository constructor kamu beda, tinggal sesuaikan di sini

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),

        // ✅ INI YANG PALING PENTING: PurchaseProvider harus di ROOT
        ChangeNotifierProvider(create: (_) => PurchaseProvider(purchaseRepo)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(ordersRepo)),
        ChangeNotifierProvider(create: (_) => ProcessProvider(ordersRepo)),
        ChangeNotifierProvider(create: (_) => DoneProvider(ordersRepo)),
        // ✅ root printer manager (WAJIB)
        ChangeNotifierProvider(
          create: (_) => PrinterManager(PrinterPrefs())..init(autoConnect: true),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cavaa Cashier',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFAE1504)),
        home: const SplashPage(),
        navigatorKey: appNavigatorKey,
      ),
    );
  }
}
