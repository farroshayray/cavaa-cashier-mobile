import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../auth_provider.dart';
import '../../../cashier/presentation/pages/cashier_home_page.dart';
import '../../../owner/presentation/pages/owner_home_page.dart';
import 'login_page.dart';
import 'owner_set_password_page.dart';

import '/core/network/version_api.dart';
import '/core/network/dio_client.dart';
import '/core/services/app_update_provider.dart';
import '/core/services/store_updater.dart';

enum UpdateAction { later, update }

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final StoreUpdater _storeUpdater = StoreUpdater();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();

    try {
      final dioClient = context.read<DioClient>();
      final versionApi = VersionApi(dioClient);

      final info = await PackageInfo.fromPlatform();
      final versionCode = int.tryParse(info.buildNumber) ?? 1;
      final versionName = info.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      dioClient.setAppInfo(
        platform: platform,
        versionCode: versionCode,
        versionName: versionName,
      );

      final versionData = await versionApi.checkVersion(
        platform: platform,
        versionCode: versionCode,
        versionName: versionName,
      );
      if (mounted) {
        context.read<AppUpdateProvider>().setUpdate(versionData);
      }

      if (!mounted) return;

      final forceUpdate = versionData['force_update'] == true;
      final updateAvailable = versionData['update_available'] == true;
      final storeUrl = (versionData['store_url'] ?? '').toString();

      if (updateAvailable && !forceUpdate) {
        final action = await _showOptionalUpdateDialog(versionData);
        // Optional update: open the store, then carry on into the app so
        // coming back without updating doesn't leave the user stuck here.
        if (action == UpdateAction.update) await _openStoreUpdate(storeUrl);
      }

      if (forceUpdate && updateAvailable) {
        // Required update: keep asking. The dialog is back on screen when the
        // user returns from the store without updating.
        while (mounted) {
          final action = await _showForceUpdateDialog(versionData);
          if (action == UpdateAction.update) await _openStoreUpdate(storeUrl);
        }
        return;
      }
    } catch (e) {
      // debugPrint('version check failed: $e');
    }

    await auth.bootstrap();

    if (!mounted) return;

    Widget next = const LoginPage();
    if (auth.isLoggedIn) {
      if (auth.isOwner) {
        next = auth.owner?.needsPassword == true
            ? const OwnerSetPasswordPage()
            : const OwnerHomePage();
      } else {
        next = const CashierHomePage();
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  Future<void> _openStoreUpdate(String storeUrl) async {
    if (storeUrl.trim().isEmpty) {
      _snack('Link update tidak tersedia');
      return;
    }
    final opened = await _storeUpdater.open(storeUrl);
    if (!opened) _snack('Tidak bisa membuka Play Store');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<UpdateAction?> _showForceUpdateDialog(
    Map<String, dynamic> data,
  ) async {
    final title = (data['title'] ?? 'Update Required').toString();
    final message = (data['message'] ?? 'Please update the app to continue.')
        .toString();

    return showDialog<UpdateAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(UpdateAction.update);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<UpdateAction?> _showOptionalUpdateDialog(
    Map<String, dynamic> data,
  ) async {
    final title = (data['title'] ?? 'Update Available').toString();
    final message = (data['message'] ?? 'A new version is available.')
        .toString();

    return showDialog<UpdateAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(UpdateAction.later);
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(UpdateAction.update);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
