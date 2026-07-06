enum SyncErrorKind { stock, lifecycle, version, general }

class SyncErrorInfo {
  const SyncErrorInfo({
    required this.kind,
    required this.status,
    required this.title,
    required this.shortLabel,
    required this.defaultMessage,
  });

  final SyncErrorKind kind;
  final String status;
  final String title;
  final String shortLabel;
  final String defaultMessage;

  bool get isConflict => kind != SyncErrorKind.general;
}

class SyncErrorClassifier {
  SyncErrorClassifier._();

  static SyncErrorInfo classify(String? message, {String? reason}) {
    final text = '${reason ?? ''} ${message ?? ''}'.trim().toLowerCase();
    final normalizedReason = (reason ?? '').trim().toUpperCase();

    if (normalizedReason.contains('SYNC_VERSION') ||
        text.contains('sync_version') ||
        text.contains('stale') ||
        text.contains('server ahead') ||
        text.contains('pull required')) {
      return const SyncErrorInfo(
        kind: SyncErrorKind.version,
        status: 'VERSION_CONFLICT',
        title: 'Konflik Versi',
        shortLabel: 'Konflik Versi',
        defaultMessage: 'Versi server lebih baru dari data lokal.',
      );
    }

    if (text.contains('stock') ||
        text.contains('stok') ||
        text.contains('stock_insufficient') ||
        text.contains('insufficient')) {
      return const SyncErrorInfo(
        kind: SyncErrorKind.stock,
        status: 'STOCK_CONFLICT',
        title: 'Konflik Stok',
        shortLabel: 'Konflik Stok',
        defaultMessage: 'Stok tidak cukup di server.',
      );
    }

    if (text.contains('finish') ||
        text.contains('served') ||
        text.contains('status') ||
        text.contains('pay tidak diizinkan') ||
        text.contains('process tidak diizinkan') ||
        text.contains('tidak diizinkan') ||
        text.contains('order tidak dapat')) {
      return const SyncErrorInfo(
        kind: SyncErrorKind.lifecycle,
        status: 'LIFECYCLE_CONFLICT',
        title: 'Konflik Status Order',
        shortLabel: 'Konflik Status',
        defaultMessage: 'Status order lokal dan server tidak sejalan.',
      );
    }

    return const SyncErrorInfo(
      kind: SyncErrorKind.general,
      status: 'FAILED',
      title: 'Gagal Sinkronisasi',
      shortLabel: 'Gagal Sync',
      defaultMessage: 'Perubahan lokal belum tersinkron.',
    );
  }

  static bool isConflictStatus(String status) {
    return const {
      'STOCK_CONFLICT',
      'LIFECYCLE_CONFLICT',
      'VERSION_CONFLICT',
    }.contains(status.toUpperCase());
  }
}
