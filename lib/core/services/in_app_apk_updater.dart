import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class InAppApkUpdater {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  bool get isDownloading =>
      _cancelToken != null && !(_cancelToken?.isCancelled ?? true);

  void cancelDownload() {
    if (_cancelToken != null && !(_cancelToken?.isCancelled ?? true)) {
      _cancelToken?.cancel('Download dibatalkan oleh pengguna');
    }
  }

  Future<String> downloadApk({
    required String url,
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/cavaa_update.apk';

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    try {
      await _dio.download(
        url,
        filePath,
        deleteOnError: true,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          debugPrint('DOWNLOAD APK => received=$received total=$total');
          onProgress?.call(received, total);
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      return filePath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      rethrow;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      _cancelToken = null;
    }
  }

  Future<OpenResult> openInstaller(String filePath) async {
    return OpenFilex.open(filePath);
  }

  Future<void> downloadAndInstall({
    required String apkUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK direct install hanya untuk Android');
    }

    final filePath = await downloadApk(
      url: apkUrl,
      onProgress: onProgress,
    );

    final result = await openInstaller(filePath);

    debugPrint('open installer result: ${result.type} ${result.message}');
  }
}