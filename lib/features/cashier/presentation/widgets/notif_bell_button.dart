import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';

class NotifBellButton extends StatelessWidget {
  const NotifBellButton({
    super.key,
    required this.onTapItem,
  });

  final void Function(IncomingOrderNotif n) onTapItem;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsProvider>();
    final unread = vm.unread;

    return IconButton(
      onPressed: () async {
        // buka panel list
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _NotifSheet(onTapItem: onTapItem),
        );
        // setelah tutup sheet -> tandai terbaca
        context.read<NotificationsProvider>().markAllRead();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet({required this.onTapItem});
  final void Function(IncomingOrderNotif n) onTapItem;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsProvider>();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(blurRadius: 20, offset: const Offset(0, 10), color: Colors.black.withOpacity(0.12))],
        ),
        height: MediaQuery.of(context).size.height * 0.70,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                TextButton(
                  onPressed: () => context.read<NotificationsProvider>().clear(),
                  child: const Text('Bersihkan'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: vm.items.isEmpty
                  ? Center(child: Text('Belum ada notifikasi.', style: TextStyle(color: Colors.black.withOpacity(0.6))))
                  : ListView.separated(
                      itemCount: vm.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = vm.items[i];
                        return ListTile(
                          dense: true,
                          title: Text(n.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${n.customer} • Rp ${_rupiah(n.total)} • ${n.status}\n${n.createdAt}'),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            onTapItem(n);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _rupiah(num n) {
  final s = n.toDouble().round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
