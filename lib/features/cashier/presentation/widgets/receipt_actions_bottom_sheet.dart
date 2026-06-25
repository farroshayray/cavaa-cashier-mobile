import 'package:flutter/material.dart';

enum ReceiptAction { print, share }

Future<ReceiptAction?> showReceiptActionsSheet(BuildContext context) {
  return showModalBottomSheet<ReceiptAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => const SafeArea(
      child: _ReceiptActionsSheetBody(),
    ),
  );
}

class _ReceiptActionsSheetBody extends StatelessWidget {
  const _ReceiptActionsSheetBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Struk Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.print_rounded),
            title: const Text('Print struk'),
            subtitle: const Text('Cetak ke printer thermal'),
            onTap: () => Navigator.pop(context, ReceiptAction.print),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Bagikan PDF'),
            subtitle: const Text('WhatsApp, Drive, email, dan lainnya'),
            onTap: () => Navigator.pop(context, ReceiptAction.share),
          ),
        ],
      ),
    );
  }
}
