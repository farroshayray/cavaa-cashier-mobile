import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_notification_item.dart';

class LocalNotificationStore {
  static const _key = 'cashier_local_notifications';

  Future<List<LocalNotificationItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    return rawList
        .map((e) => LocalNotificationItem.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> saveAll(List<LocalNotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> add(LocalNotificationItem item) async {
    final items = await load();

    final exists = items.any((e) => e.uid == item.uid);
    if (exists) return;

    items.insert(0, item);

    if (items.length > 200) {
      items.removeRange(200, items.length);
    }

    await saveAll(items);
  }

  Future<void> markAllRead() async {
    final items = await load();
    final updated = items.map((e) => e.copyWith(isRead: true)).toList();
    await saveAll(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}