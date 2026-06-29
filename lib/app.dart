import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';

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

import '/features/cashier/presentation/providers/edit_order_provider.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/data/orders_api.dart';
import '/features/cashier/data/models/orders_repository.dart';

import 'features/cashier/data/local/db/cashier_db.dart';
import 'core/services/connectivity_status_provider.dart';
import 'features/cashier/data/local/db/daos/local_orders_dao.dart';
import 'features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import 'features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import 'features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/sync_api.dart';
import 'core/services/app_update_provider.dart';
import '/core/services/push_notification_service.dart';

class CavaaApp extends StatefulWidget {
  const CavaaApp({super.key});

  @override
  State<CavaaApp> createState() => _CavaaAppState();
}

class _CavaaAppState extends State<CavaaApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  late final SecureStorageService storage;
  late final DioClient dioClient;
  late final AppUpdateProvider appUpdateProvider;
  late final CashierDb cashierDb;

  late final AuthApi authApi;
  late final AuthRepository authRepo;

  late final PurchaseApi purchaseApi;
  late final PurchaseRepository purchaseRepo;

  late final OrdersApi ordersApi;
  late final OrdersRepository ordersRepo;
  late final LocalOrdersDao localOrdersDao;
  late final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  late final CachedPaymentMethodsDao cachedPaymentMethodsDao;
  late final CachedProcessOrdersDao cachedProcessOrdersDao;
  late final CachedDoneOrdersDao cachedDoneOrdersDao;
  late final BookingOrdersDao bookingOrdersDao;
  late final SyncApi syncApi;

  @override
  void initState() {
    super.initState();

    storage = SecureStorageService();
    appUpdateProvider = AppUpdateProvider();
    dioClient = DioClient(storage, appUpdateProvider: appUpdateProvider);
    PushNotificationService.instance.configure(dioClient: dioClient);
    cashierDb = CashierDb();
    localOrdersDao = LocalOrdersDao(cashierDb);
    cachedPaymentOrdersDao = CachedPaymentOrdersDao(cashierDb);
    cachedPaymentMethodsDao = CachedPaymentMethodsDao(cashierDb);
    cachedProcessOrdersDao = CachedProcessOrdersDao(cashierDb);
    cachedDoneOrdersDao = CachedDoneOrdersDao(cashierDb);
    bookingOrdersDao = BookingOrdersDao(cashierDb);
    syncApi = SyncApi(dioClient.dio);

    authApi = AuthApi(dioClient);
    authRepo = AuthRepository(api: authApi, storage: storage);

    purchaseApi = PurchaseApi(dioClient.dio);
    purchaseRepo = PurchaseRepository(
      api: purchaseApi,
      db: cashierDb,
      syncApi: syncApi,
    );

    ordersApi = OrdersApi(dioClient.dio);
    ordersRepo = OrdersRepository(api: ordersApi);

    () async {
      final initial = await _appLinks.getInitialLink();
      if (!mounted) return;
      if (initial != null) _handleUri(initial);
    }();

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (e) {});
  }

  Future<void> _refreshAfterPayment(BuildContext ctx) async {
    try {
      final paymentProvider = ctx.read<PaymentProvider>();
      final processProvider = ctx.read<ProcessProvider>();

      await paymentProvider.load();

      // coba langsung
      await processProvider.load();
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
    cashierDb.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DioClient>.value(value: dioClient),
        ChangeNotifierProvider<AppUpdateProvider>.value(
          value: appUpdateProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityStatusProvider()..init(),
        ),

        Provider(
          create: (_) => SyncService(
            localOrdersDao: localOrdersDao,
            cachedPaymentOrdersDao: cachedPaymentOrdersDao,
            cachedProcessOrdersDao: cachedProcessOrdersDao,
            cachedDoneOrdersDao: cachedDoneOrdersDao,
            bookingOrdersDao: bookingOrdersDao,
            syncApi: syncApi,
            db: cashierDb,
          ),
        ),

        // ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider()..loadFromStorage(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),

        ChangeNotifierProvider(
          create: (ctx) => PurchaseProvider(
            repo: purchaseRepo,
            localOrdersDao: localOrdersDao,
            syncService: ctx.read<SyncService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EditOrderProvider(
            ordersRepo: ordersRepo,
            localOrdersDao: localOrdersDao,
            cachedPaymentOrdersDao: cachedPaymentOrdersDao,
            cachedProcessOrdersDao: cachedProcessOrdersDao,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PaymentProvider(
            repo: ordersRepo,
            localOrdersDao: localOrdersDao,
            cachedPaymentOrdersDao: cachedPaymentOrdersDao,
            cachedPaymentMethodsDao: cachedPaymentMethodsDao,
            cachedProcessOrdersDao: cachedProcessOrdersDao,
            cachedDoneOrdersDao: cachedDoneOrdersDao,
            connectivity: ctx.read<ConnectivityStatusProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ProcessProvider(
            ordersRepo,
            localOrdersDao,
            cachedProcessOrdersDao,
            cachedDoneOrdersDao,
            cachedPaymentOrdersDao,
            ctx.read<ConnectivityStatusProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => DoneProvider(
            ordersRepo,
            localOrdersDao,
            cachedDoneOrdersDao,
            ctx.read<ConnectivityStatusProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PrinterManager(PrinterPrefs())..init(autoConnect: true),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cavaa Cashier',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFAE1504),
        ),
        home: const SplashPage(),
        navigatorKey: appNavigatorKey,
      ),
    );
  }
}
