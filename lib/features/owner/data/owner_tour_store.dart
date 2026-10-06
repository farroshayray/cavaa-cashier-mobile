import 'package:shared_preferences/shared_preferences.dart';

/// Menandai owner yang sudah melihat tur menu utama, supaya tidak diulang.
class OwnerTourStore {
  static String _key(int ownerId) => 'owner_home_tour_done_$ownerId';

  static Future<bool> isDone(int ownerId) async {
    if (ownerId <= 0) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(ownerId)) ?? false;
  }

  static Future<void> markDone(int ownerId) async {
    if (ownerId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(ownerId), true);
  }
}
