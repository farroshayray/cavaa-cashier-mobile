import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '/core/network/dio_client.dart';
import '/core/config/env.dart';

class PusherOrdersService {
  PusherOrdersService(this.client);

  final DioClient client;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _started = false;

  Future<void> start({
    required int partnerId,
    required void Function(Map<String, dynamic> data) onOrderCreated,
    void Function(Map<String, dynamic> data)? onOrderUpdated,
  }) async {
    if (_started) return;
    _started = true;

    final token = await client.storage.getToken();
    if (token == null || token.trim().isEmpty) {
      _started = false;
      throw Exception('Token kosong');
    }

    await _pusher.init(
      apiKey: Env.pusherKey,
      cluster: Env.pusherCluster,

      // 🔎 CONNECTION DEBUG
      onConnectionStateChange: (current, previous) {
        // print('PUSHER STATE: $previous -> $current');
      },

      onError: (message, code, error) {
        // print('PUSHER ERROR: $code $message $error');
      },

      // 🔐 AUTH DEBUG
      onAuthorizer: (channelName, socketId, options) async {
        // print('AUTH REQUEST: $channelName socket=$socketId');

        final resp = await client.dio.post(
          '/api/v1/mobile/cashier/broadcasting/auth',
          data: {'socket_id': socketId, 'channel_name': channelName},
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );

        // print('AUTH RESPONSE ${resp.statusCode}: ${resp.data}');

        final statusCode = resp.statusCode ?? 0;
        if (statusCode < 200 || statusCode >= 300) {
          throw Exception('Auth failed $statusCode: ${resp.data}');
        }

        final data = resp.data;
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is String) return jsonDecode(data);

        throw Exception('Auth response tidak valid: $data');
      },

      // 📡 SUBSCRIBE DEBUG
      onSubscriptionSucceeded: (channelName, data) {
        // print('SUBSCRIBED OK: $channelName');
      },

      onSubscriptionError: (message, e) {
        // print('SUBSCRIBE ERROR: $message $e');
      },

      // 📩 EVENT DEBUG
      onEvent: (event) {
        // print('EVENT RECEIVED: ${event.eventName}');
        // print('DATA: ${event.data}');

        final name = event.eventName ?? '';
        final raw = event.data;
        if (raw == null || raw.isEmpty) return;

        Map<String, dynamic> data;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return;
          data = Map<String, dynamic>.from(decoded);
        } catch (_) {
          return;
        }

        if (name == '.OrderCreated' || name == 'OrderCreated') {
          onOrderCreated(data);
          return;
        }

        if (name == '.OrderUpdated' || name == 'OrderUpdated') {
          onOrderUpdated?.call(data);
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
