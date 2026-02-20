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

  void _handleUri(Uri uri) {

    if (uri.scheme == 'cavapos' && uri.host == 'payment') {
      final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

      if (status == 'success') {
        // tutup route
        appNavigatorKey.currentState?.popUntil((r) => r.isFirst);

        // clear cart
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null) {
          try {
            final p = ctx.read<PurchaseProvider>();
            p.clearCartAndReset();
          } catch (e) {
            debugPrint('❌ read<PurchaseProvider>() failed: $e');
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
    // ⚠️ sesuaikan: kalau PurchaseRepository constructor kamu beda, tinggal sesuaikan di sini

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),

        // ✅ INI YANG PALING PENTING: PurchaseProvider harus di ROOT
        ChangeNotifierProvider(create: (_) => PurchaseProvider(purchaseRepo)),
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
