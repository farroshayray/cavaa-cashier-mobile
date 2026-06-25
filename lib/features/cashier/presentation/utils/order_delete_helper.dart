import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';

Future<void> confirmDeleteUnpaidOrder(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final isLocalOnly = data['is_local_only'] == true;
  final serverId = (data['server_id'] ?? data['id']);
  final hasServerId = serverId != null && serverId.toString() != '-1';
  final isOnline = context.read<ConnectivityStatusProvider>().isOnline;

  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      String message;
      if (isLocalOnly && !hasServerId) {
        message = 'Order lokal yang belum sync akan dihapus permanen dari device.';
      } else if (!isOnline) {
        message = 'Order akan ditandai sebagai Pending Delete dan dihapus saat koneksi kembali online.';
      } else {
        message = 'Order akan dihapus.';
      }

      return AlertDialog(
        title: const Text('Hapus order?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 146, 10, 0),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );

  if (ok != true || !context.mounted) return;

  final paymentProvider = context.read<PaymentProvider>();
  final processProvider = context.read<ProcessProvider>();

  try {
    await paymentProvider.deleteOrderItem(
      data,
      isOnline: isOnline,
    );
    await processProvider.load();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order berhasil dihapus.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal hapus order: $e')),
    );
  }
}
