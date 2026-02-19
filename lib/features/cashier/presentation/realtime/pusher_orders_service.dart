import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import '/core/config/env.dart';
import '/core/storage/secure_storage_service.dart';

class PusherOrdersService {
  PusherOrdersService(this.storage);

  final SecureStorageService storage;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _started = false;

  Future<void> start({
    required int partnerId,
    required void Function(Map<String, dynamic> data) onOrderCreated,
  }) async {
    if (_started) return;
    _started = true;

    final token = await storage.getToken();
    if (token == null || token.trim().isEmpty) {
      _started = false;
      throw Exception('Token kosong');
    }

    await _pusher.init(
      apiKey: Env.pusherKey,
      cluster: Env.pusherCluster,

      // 🔎 CONNECTION DEBUG
      onConnectionStateChange: (current, previous) {
        print('PUSHER STATE: $previous -> $current');
      },

      onError: (message, code, error) {
        print('PUSHER ERROR: $code $message $error');
      },

      // 🔐 AUTH DEBUG
      onAuthorizer: (channelName, socketId, options) async {
        print('AUTH REQUEST: $channelName socket=$socketId');

        final url = Uri.parse('${Env.baseUrl}/api/v1/mobile/cashier/broadcasting/auth');

        final resp = await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': 'Bearer $token',
          },
          body: {
            'socket_id': socketId,
            'channel_name': channelName,
          },
        );

        print('AUTH RESPONSE ${resp.statusCode}: ${resp.body}');

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw Exception('Auth failed ${resp.statusCode}: ${resp.body}');
        }

        return jsonDecode(resp.body);
      },

      // 📡 SUBSCRIBE DEBUG
      onSubscriptionSucceeded: (channelName, data) {
        print('SUBSCRIBED OK: $channelName');
      },

      onSubscriptionError: (message, e) {
        print('SUBSCRIBE ERROR: $message $e');
      },

      // 📩 EVENT DEBUG
      onEvent: (event) {
        print('EVENT RECEIVED: ${event.eventName}');
        print('DATA: ${event.data}');

        if (event.eventName == '.OrderCreated' ||
            event.eventName == 'OrderCreated') {
          final data = jsonDecode(event.data ?? '{}');
          if (data is Map<String, dynamic>) onOrderCreated(data);
        }
      },
    );

    await _pusher.connect();

    final channel = 'private-partner.$partnerId.orders';
    await _pusher.subscribe(channelName: channel);
  }

  Future<void> stop() async {
    _started = false;
    try {
      await _pusher.disconnect();
    } catch (_) {}
  }
}
