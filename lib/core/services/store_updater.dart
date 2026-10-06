import 'package:url_launcher/url_launcher.dart';

/// Membuka halaman update aplikasi (link Play Store / App Store yang
/// disimpan di server sebagai `store_url`). Aplikasi tidak lagi mengunduh
/// dan memasang APK sendiri.
class StoreUpdater {
  /// Mengembalikan `false` kalau link kosong, tidak valid, atau gagal dibuka.
  Future<bool> open(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl.trim());
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
