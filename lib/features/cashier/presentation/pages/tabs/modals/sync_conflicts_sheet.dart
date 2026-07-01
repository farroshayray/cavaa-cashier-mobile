import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';

class SyncConflictsSheet extends StatefulWidget {
  const SyncConflictsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SyncConflictsSheet(),
    );
  }

  @override
  State<SyncConflictsSheet> createState() => _SyncConflictsSheetState();
}

class _SyncConflictsSheetState extends State<SyncConflictsSheet> {
  late final BookingOrdersDao _dao;
  List<SyncConflict> _conflicts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dao = context.read<BookingOrdersDao>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _dao.getUnresolvedConflicts();
      if (!mounted) return;
      setState(() {
        _conflicts = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _resolve(SyncConflict conflict, String choice) async {
    await _dao.applyConflictResolution(conflictId: conflict.id, choice: choice);
    if ((choice == 'PULL_AND_RETRY' || choice == 'LOCAL_WINS') && mounted) {
      try {
        await context.read<SyncService>().syncPendingOrders();
      } catch (_) {}
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Konflik Sinkronisasi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ini juga diubah di server atau kitchen. Pilih versi mana yang dipakai.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _conflicts.isEmpty
                            ? const Center(child: Text('Tidak ada konflik aktif'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _conflicts.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final c = _conflicts[index];
                                  return _ConflictTile(
                                    conflict: c,
                                    onServerWins: () =>
                                        _resolve(c, 'SERVER_WINS'),
                                    onLocalWins: () =>
                                        _resolve(c, 'LOCAL_WINS'),
                                    onPullRetry: () =>
                                        _resolve(c, 'PULL_AND_RETRY'),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({
    required this.conflict,
    required this.onServerWins,
    required this.onLocalWins,
    required this.onPullRetry,
  });

  final SyncConflict conflict;
  final VoidCallback onServerWins;
  final VoidCallback onLocalWins;
  final VoidCallback onPullRetry;

  @override
  Widget build(BuildContext context) {
    final serverPreview = _preview(conflict.serverSnapshotJson);
    final localPreview = _preview(conflict.localSnapshotJson);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conflict.reason,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('Tabel: ${conflict.entityTable}'),
        if (conflict.clientUuid != null)
          Text('Client: ${conflict.clientUuid}'),
        if (conflict.suggestedResolution != null)
          Text('Saran: ${conflict.suggestedResolution}'),
        const SizedBox(height: 8),
        if (localPreview != null) ...[
          const Text('Lokal:', style: TextStyle(fontSize: 12)),
          Text(localPreview, style: const TextStyle(fontSize: 11)),
        ],
        if (serverPreview != null) ...[
          const SizedBox(height: 4),
          const Text('Server:', style: TextStyle(fontSize: 12)),
          Text(serverPreview, style: const TextStyle(fontSize: 11)),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onServerWins,
              child: const Text('Gunakan server'),
            ),
            OutlinedButton(
              onPressed: onLocalWins,
              child: const Text('Gunakan perubahan saya'),
            ),
            FilledButton(
              onPressed: onPullRetry,
              child: const Text('Pull & coba lagi'),
            ),
          ],
        ),
      ],
    );
  }

  String? _preview(String? jsonText) {
    if (jsonText == null || jsonText.isEmpty) return null;
    try {
      final map = jsonDecode(jsonText);
      if (map is Map) {
        final status = map['order_status'] ?? map['status'];
        final code = map['booking_order_code'] ?? map['id'];
        return 'status=$status code/id=$code';
      }
    } catch (_) {}
    return jsonText.length > 80 ? '${jsonText.substring(0, 80)}...' : jsonText;
  }
}
