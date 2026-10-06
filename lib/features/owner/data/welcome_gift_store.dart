import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan hadiah welcome points sampai popup di menu utama ditutup.
class WelcomeGiftStore {
  static String _key(int ownerId) => 'welcome_gift_points_$ownerId';

  static Future<void> save(int ownerId, int points) async {
    if (ownerId <= 0 || points < 1) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(ownerId), points);
  }

  static Future<int?> read(int ownerId) async {
    if (ownerId <= 0) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(ownerId));
  }

  static Future<void> clear(int ownerId) async {
    if (ownerId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(ownerId));
  }
}
