import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../auth_provider.dart';
import '../../../cashier/presentation/pages/cashier_home_page.dart';
import 'login_page.dart';

import '/core/network/version_api.dart';
import '/core/network/dio_client.dart';
import '/core/services/in_app_apk_updater.dart';

enum UpdateAction {
  later,
  update,
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final InAppApkUpdater _apkUpdater = InAppApkUpdater();
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

  bool _isDownloadingUpdate = false;
  bool _activeUpdateIsForce = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
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

      if (!mounted) return;

      final forceUpdate = versionData['force_update'] == true;
      final updateAvailable = versionData['update_available'] == true;
      final storeUrl = (versionData['store_url'] ?? '').toString();

      

      if (updateAvailable && !forceUpdate) {
        final action = await _showOptionalUpdateDialog(versionData);
        if (action == UpdateAction.update) {
          await _startApkUpdate(storeUrl, force: false);
          return;
        }
      }

      if (forceUpdate && updateAvailable) {
        final action = await _showForceUpdateDialog(versionData);
        if (action == UpdateAction.update) {
          await _startApkUpdate(storeUrl, force: true);
        }
        return;
      }
    } catch (e) {
      debugPrint('version check failed: $e');
    }

    final auth = context.read<AuthProvider>();
    await auth.bootstrap();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn
            ? const CashierHomePage()
            : const LoginPage(),
      ),
    );
  }

  Future<void> _showDownloadingDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Downloading Update'),
        content: ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            final isKnownProgress = progress >= 0 && progress <= 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sedang mengunduh APK versi terbaru...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: isKnownProgress ? progress : null,
                ),
                const SizedBox(height: 8),
                Text(
                  isKnownProgress
                      ? '${(progress * 100).toStringAsFixed(0)}%'
                      : 'Downloading...',
                ),
              ],
            );
          },
        ),
        actions: [
          if (!_activeUpdateIsForce)
            TextButton(
              onPressed: _cancelApkDownload,
              child: const Text('Batalkan'),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelApkDownload() async {
    _apkUpdater.cancelDownload();

    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    setState(() {
      _isDownloadingUpdate = false;
      _activeUpdateIsForce = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download update dibatalkan')),
    );
  }

  Future<void> _startApkUpdate(String apkUrl, {required bool force}) async {
    if (apkUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link update tidak tersedia')),
      );
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isDownloadingUpdate = true;
          _activeUpdateIsForce = force;
          _downloadProgress = 0;
        });
      }

      _progressNotifier.value = 0;

      unawaited(_showDownloadingDialog());

      await _apkUpdater.downloadAndInstall(
        apkUrl: apkUrl,
        onProgress: (received, total) {
          if (!mounted) return;

          if (total > 0) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
            _progressNotifier.value = progress;
          } else {
            _progressNotifier.value = -1;
          }
        },
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } on DioException catch (e) {
      final wasCancelled = CancelToken.isCancel(e);

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (!wasCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              force
                  ? 'Gagal mengunduh update. Silakan coba lagi.'
                  : 'Gagal mengunduh update.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('apk update failed: $e');

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            force
                ? 'Gagal mengunduh update. Silakan coba lagi.'
                : 'Gagal mengunduh update.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingUpdate = false;
          _activeUpdateIsForce = false;
        });
      }
    }
  }

  Future<UpdateAction?> _showForceUpdateDialog(Map<String, dynamic> data) async {
    final title = (data['title'] ?? 'Update Required').toString();
    final message =
        (data['message'] ?? 'Please update the app to continue.').toString();

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
    final message = (data['message'] ?? 'A new version is available.').toString();

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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}