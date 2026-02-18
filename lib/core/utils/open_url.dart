import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!ok) {
    throw Exception('Tidak bisa membuka halaman pembayaran');
  }
}


Future<void> openInAppUrl(String url) async {
  final uri = Uri.parse(url);

  final ok = await launchUrl(
    uri,
    mode: LaunchMode.inAppBrowserView,
  );

  if (!ok) {
    throw Exception('Tidak bisa membuka halaman pembayaran');
  }
}