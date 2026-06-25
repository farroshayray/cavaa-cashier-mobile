import 'dart:convert';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/core/network/dio_client.dart';
import '/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/features/cashier/presentation/providers/notifications_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // debugPrint('📩 Background message: ${message.messageId}');
  // debugPrint('📦 Background data: ${jsonEncode(message.data)}');

  final data = Map<String, dynamic>.from(message.data);
  final type = (data['type'] ?? '').toString();

  if (type == 'force_logout') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('force_logout_pending', true);
    await prefs.setString('force_logout_payload', jsonEncode(data));
    // debugPrint('🚪 force_logout saved in background');
    return;
  }

  if (type == 'order_updated') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orders_stale', true);
    return;
  }

  if (type == 'new_order' &&
      (data['order_by'] ?? '').toString().toUpperCase() == 'CASHIER') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orders_stale', true);
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  const key = 'cashier_notifications';
  const unreadKey = 'cashier_notifications_unread';

  final rawList = prefs.getStringList(key) ?? [];

  final notif = IncomingOrderNotif.fromMap(data);
  final encoded = jsonEncode(notif.toMap());

  final exists = rawList.any((e) {
    try {
      final old = IncomingOrderNotif.fromMap(jsonDecode(e));
      return old.uniqueKey == notif.uniqueKey;
    } catch (_) {
      return false;
    }
  });

  if (!exists) {
    rawList.insert(0, encoded);

    if (rawList.length > 200) {
      rawList.removeRange(200, rawList.length);
    }

    final currentUnread = prefs.getInt(unreadKey) ?? 0;

    await prefs.setStringList(key, rawList);
    await prefs.setInt(unreadKey, currentUnread + 1);
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _messageReceivedController =
      StreamController<Map<String, dynamic>>.broadcast();

  final _messageTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageReceivedController.stream;

  Stream<Map<String, dynamic>> get onMessageTapped =>
      _messageTapController.stream;

  bool _initialized = false;
  DioClient? _dioClient;

  static const AndroidNotificationChannel orderChannel =
      AndroidNotificationChannel(
        'cavaa_order_channel_v2',
        'Cavaa Order Notifications',
        description: 'Heads-up notifications for incoming cashier orders',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('buzzer'),
      );

  static const AndroidNotificationChannel paymentChannel =
      AndroidNotificationChannel(
        'cavaa_payment_channel',
        'Cavaa Payment Notifications',
        description: 'Payment notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('buzzer'),
      );

  static const AndroidNotificationChannel promoChannel =
      AndroidNotificationChannel(
        'cavaa_promo_channel',
        'Cavaa Promo Notifications',
        description: 'Promo notifications',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notify'),
      );

  static const AndroidNotificationChannel generalChannel =
      AndroidNotificationChannel(
        'cavaa_general_channel',
        'Cavaa General Notifications',
        description: 'General notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notify'),
      );

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _initLocalNotifications();
    await _setupInitialNotificationTap();
    _setupForegroundHandler();
    _setupOpenedAppHandler();
    await _printInitialToken();
    _listenTokenRefresh();

    _initialized = true;
  }

  void configure({required DioClient dioClient}) {
    _dioClient = dioClient;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    // debugPrint('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _messageTapController.add(decoded);
          } else if (decoded is Map) {
            _messageTapController.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(orderChannel);
    await androidPlugin?.createNotificationChannel(paymentChannel);
    await androidPlugin?.createNotificationChannel(promoChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  Future<void> _setupInitialNotificationTap() async {
    final details = await _localNotifications.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      // debugPrint(
      //   '🚀 App launched from local notification. payload=${details?.notificationResponse?.payload}',
      // );

      final payload = details?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          _messageTapController.add(decoded);
        }
      }
    }

    final remoteMessage = await _messaging.getInitialMessage();
    if (remoteMessage != null) {
      if (remoteMessage.data.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cashier_pending_notification_tap',
          jsonEncode(Map<String, dynamic>.from(remoteMessage.data)),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> consumePendingNotificationTap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cashier_pending_notification_tap');

    if (raw == null || raw.isEmpty) return null;

    await prefs.remove('cashier_pending_notification_tap');

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return null;
  }

  static const String ordersStaleKey = 'orders_stale';

  Future<bool> consumeOrdersStaleFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final stale = prefs.getBool(ordersStaleKey) ?? false;

    if (stale) {
      await prefs.setBool(ordersStaleKey, false);
    }

    return stale;
  }

  Future<Map<String, dynamic>?> consumePendingForceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('force_logout_pending') ?? false;

    if (!pending) return null;

    final raw = prefs.getString('force_logout_payload');

    await prefs.remove('force_logout_pending');
    await prefs.remove('force_logout_payload');

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // debugPrint('📲 Foreground message: ${message.messageId}');
      // debugPrint('📦 Foreground data: ${jsonEncode(message.data)}');

      final data = Map<String, dynamic>.from(message.data);
      final type = (data['type'] ?? '').toString();

      if (data.isNotEmpty) {
        _messageReceivedController.add(data);
      }

      if (type == 'force_logout') {
        // debugPrint('🚪 force_logout received in foreground');
        return;
      }

      if (type == 'order_updated') {
        return;
      }

      final notification = message.notification;
      if (notification == null) return;

      final channel = _channelFromData(data);

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Notifikasi',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: _soundFromChannel(channel.id),
            ticker: notification.title ?? 'Notifikasi',
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: jsonEncode(data),
      );
    });
  }

  void dispose() {
    _messageReceivedController.close();
    _messageTapController.close();
  }

  void _setupOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // debugPrint('📬 App opened from remote notification: ${message.data}');

      if (message.data.isNotEmpty) {
        _messageTapController.add(Map<String, dynamic>.from(message.data));
      }
    });
  }

  AndroidNotificationChannel _channelFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();

    switch (type) {
      case 'new_order':
        return orderChannel;
      case 'payment_success':
      case 'payment':
        return paymentChannel;
      case 'promo':
        return promoChannel;
      default:
        return generalChannel;
    }
  }

  AndroidNotificationSound? _soundFromChannel(String channelId) {
    switch (channelId) {
      case 'cavaa_order_channel_v2':
        return const RawResourceAndroidNotificationSound('buzzer');
      case 'cavaa_payment_channel':
        return const RawResourceAndroidNotificationSound('buzzer');
      case 'cavaa_promo_channel':
        return const RawResourceAndroidNotificationSound('notify');
      case 'cavaa_general_channel':
        return const RawResourceAndroidNotificationSound('notify');
      default:
        return null;
    }
  }

  Future<void> _printInitialToken() async {
    await _messaging.getToken();
    // debugPrint('✅ FCM TOKEN ASLI: $token');
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      // debugPrint('🔄 FCM token refreshed: $token');
      await sendTokenToBackend(token);
    });
  }

  Future<String?> getFcmToken() async {
    return _messaging.getToken();
  }

  Future<void> syncCurrentTokenToBackend() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      // debugPrint('⚠️ FCM token kosong.');
      return;
    }

    await sendTokenToBackend(token);
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final dioClient = _dioClient;

      if (dioClient == null) {
        debugPrint('FCM sync skipped: DioClient belum siap.');
        return;
      }

      final deviceName = await getDeviceName();

      final response = await dioClient.dio.post(
        '/api/v1/mobile/cashier/device-token',
        data: {
          'token': token,
          'platform': 'Android',
          'device_name': deviceName,
        },
      );

      debugPrint('✅ Sync token success: ${response.data}');
    } catch (e) {
      debugPrint('❌ Failed sync FCM token: $e');
    }
  }
}

Future<String> getDeviceName() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return "${androidInfo.brand} ${androidInfo.model}"; // contoh: "Poco F7"
  }

  return "Unknown device";
}
