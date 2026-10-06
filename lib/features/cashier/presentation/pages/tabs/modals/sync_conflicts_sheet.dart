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
  int? _resolvingId;
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
    setState(() {
      _resolvingId = conflict.id;
      _error = null;
    });

    try {
      await _dao.applyConflictResolution(
        conflictId: conflict.id,
        choice: choice,
      );
      if (choice == 'LOCAL_WINS' && mounted) {
        await context.read<SyncService>().syncPendingOrders();
        final resolved = await _dao.resolveLocalWinsIfSynced(conflict.id);
        if (!resolved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Data lokal belum berhasil dikirim ke server. Konflik tetap ditampilkan.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _resolvingId = null);
      }
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
                            isResolving: _resolvingId == c.id,
                            onServerWins: () => _resolve(c, 'SERVER_WINS'),
                            onLocalWins: () => _resolve(c, 'LOCAL_WINS'),
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
    required this.isResolving,
    required this.onServerWins,
    required this.onLocalWins,
  });

  final SyncConflict conflict;
  final bool isResolving;
  final VoidCallback onServerWins;
  final VoidCallback onLocalWins;

  @override
  Widget build(BuildContext context) {
    final local = _snapshot(conflict.localSnapshotJson);
    final server = _snapshot(conflict.serverSnapshotJson);
    final code = _firstNonEmpty([
      server?['booking_order_code'],
      local?['booking_order_code'],
      conflict.serverId,
      conflict.clientUuid,
      '-',
    ]);
    final name = _firstNonEmpty([
      server?['order_name'],
      server?['customer_name'],
      local?['order_name'],
      local?['customer_name'],
      'guest',
    ]);
    final diffs = _diffs(local, server);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        '$code - $name',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_reasonLabel(conflict.reason)} | ${conflict.entityTable}',
      ),
      children: [
        _SnapshotCompare(local: local, server: server),
        if (diffs.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perbedaan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          ...diffs.map(
            (diff) => Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $diff', style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
        if (conflict.suggestedResolution != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Saran: ${conflict.suggestedResolution}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: isResolving ? null : onServerWins,
                child: const Text('Gunakan data server'),
              ),
              FilledButton(
                onPressed: isResolving ? null : onLocalWins,
                child: Text(
                  isResolving ? 'Menyinkronkan...' : 'Gunakan data lokal',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _snapshot(String? jsonText) {
    if (jsonText == null || jsonText.isEmpty) return null;
    try {
      final map = jsonDecode(jsonText);
      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {}
    return {'raw': jsonText};
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '-';
  }

  String _reasonLabel(String reason) {
    return switch (reason.toUpperCase()) {
      'SYNC_VERSION_STALE' => 'Konflik versi',
      'EDIT_DIVERGENCE' => 'Data berbeda',
      'KITCHEN_CASHIER_STATUS_MISMATCH' => 'Status item berbeda',
      _ => reason,
    };
  }

  List<String> _diffs(
    Map<String, dynamic>? local,
    Map<String, dynamic>? server,
  ) {
    final result = <String>[];
    final localDiffs = local?['diffs'];
    if (localDiffs is List) {
      result.addAll(localDiffs.map((e) => e.toString()));
    }
    final locked = local?['locked'];
    if (locked is List) {
      result.addAll(locked.map((e) => e.toString()));
    }

    void compare(String key, String label) {
      final localValue = local?[key]?.toString();
      final serverValue = server?[key]?.toString();
      if (localValue != null &&
          serverValue != null &&
          localValue != serverValue) {
        result.add('$label lokal=$localValue server=$serverValue');
      }
    }

    compare('order_status', 'Status');
    compare('sync_version', 'Versi');

    return result.toSet().toList();
  }
}

class _SnapshotCompare extends StatelessWidget {
  const _SnapshotCompare({required this.local, required this.server});

  final Map<String, dynamic>? local;
  final Map<String, dynamic>? server;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SnapshotCard(title: 'Lokal', snapshot: local),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SnapshotCard(title: 'Server', snapshot: server),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.title, required this.snapshot});

  final String title;
  final Map<String, dynamic>? snapshot;

  @override
  Widget build(BuildContext context) {
    final status = _value('order_status') ?? _value('status') ?? '-';
    final version = _value('sync_version') ?? '-';
    final code = _value('booking_order_code') ?? _value('server_id') ?? '-';
    final details = snapshot?['order_details'];
    final detailCount = details is List ? details.length : 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Kode: $code', style: const TextStyle(fontSize: 12)),
          Text('Status: $status', style: const TextStyle(fontSize: 12)),
          Text('Versi: $version', style: const TextStyle(fontSize: 12)),
          Text('Item: $detailCount', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String? _value(String key) {
    final value = snapshot?[key];
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}
