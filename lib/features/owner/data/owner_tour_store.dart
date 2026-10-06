import 'package:shared_preferences/shared_preferences.dart';

/// Menandai tur yang sudah dilihat owner, supaya tidak diulang.
class OwnerTourStore {
  /// Tur menu utama (dipakai sejak awal; key lamanya dipertahankan).
  static const home = 'home';

  /// Tur halaman Produk saat langkah setup.
  static const productHub = 'product_hub';

  /// Tur halaman "Tambah Produk Toko".
  static const productEditor = 'product_editor';

  /// Tur halaman "Grup opsi" (setelah "+ Tambah grup").
  static const optionGroup = 'option_group';

  /// Tur halaman "Opsi".
  static const optionItem = 'option_item';

  static String _key(int ownerId, String tour) => tour == home
      ? 'owner_home_tour_done_$ownerId'
      : 'owner_tour_${tour}_done_$ownerId';

  static Future<bool> isDone(int ownerId, {String tour = home}) async {
    if (ownerId <= 0) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(ownerId, tour)) ?? false;
  }

  static Future<void> markDone(int ownerId, {String tour = home}) async {
    if (ownerId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(ownerId, tour), true);
  }
}
