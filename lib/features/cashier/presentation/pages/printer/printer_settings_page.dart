import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // dummy data dulu (nanti diganti dari storage + scan result)
  

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final pm = context.watch<PrinterManager>(); // provider kamu
    final saved = pm.saved;
    final defaultId = pm.defaultId;
    final discoveredBt = pm.discoveredBt;
    final discoveredUsb = pm.discoveredUsb;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Printer Settings'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Bluetooth'),
            Tab(text: 'USB'),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        onPressed: () async {
          try {
            await context.read<PrinterManager>().testPrint();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test print dikirim')),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal test print: $e')),
            );
          }
        },
        icon: const Icon(Icons.print),
        label: const Text('Test Print'),
      ),
      body: Column(
        children: [
          // ===== Default printer + saved list =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _SectionTitle(
              title: 'Printer Tersimpan',
              subtitle: 'Pilih salah satu sebagai default.',
            ),
          ),
          if (saved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Belum ada printer tersimpan. Silakan pairing dari tab Bluetooth/USB.',
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemBuilder: (_, i) {
                final p = saved[i];
                final isDefault = p.id == defaultId;

                return _SavedTile(
                  printer: p,
                  isDefault: isDefault,
                  onSetDefault: () => context.read<PrinterManager>().setDefault(p.id),
                  onRemove: () => context.read<PrinterManager>().removeSaved(p.id),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: saved.length,
            ),

          const Divider(height: 1),

          // ===== Discover / pair =====
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DiscoverList(
                  title: 'Perangkat Bluetooth',
                  subtitle: 'Scan & pilih printer untuk pairing.',
                  items: discoveredBt,
                  onScan: () => context.read<PrinterManager>().scanBluetooth(),
                  onPair: (p) {
                    final pm = context.read<PrinterManager>();
                    if (p.type == PrinterType.bluetooth) {
                      return pm.pairAndSaveBluetooth(p);
                    } else {
                      return pm.pairAndSaveUsb(p);
                    }
                  },

                ),
                _DiscoverList(
                  title: 'Perangkat USB',
                  subtitle: 'Colok kabel OTG/USB lalu refresh.',
                  items: discoveredUsb,
                  onScan: () => context.read<PrinterManager>().scanUsb(),
                  onPair: (p) {
                    final pm = context.read<PrinterManager>();
                    if (p.type == PrinterType.bluetooth) {
                      return pm.pairAndSaveBluetooth(p);
                    } else {
                      return pm.pairAndSaveUsb(p);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.65))),
      ],
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.printer,
    required this.isDefault,
    required this.onSetDefault,
    required this.onRemove,
  });

  final PrinterDevice printer;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        color: isDefault ? brand.withOpacity(0.06) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(printer.type == PrinterType.bluetooth ? Icons.bluetooth : Icons.usb),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(printer.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  printer.type == PrinterType.bluetooth ? 'Bluetooth' : 'USB',
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Default',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            )
          else
            TextButton(
              onPressed: onSetDefault,
              child: const Text('Jadikan default'),
            ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}

class _DiscoverList extends StatelessWidget {
  const _DiscoverList({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onScan,
    required this.onPair,
  });

  final String title;
  final String subtitle;
  final List<PrinterDevice> items;
  final VoidCallback onScan;
  final Future<void> Function(PrinterDevice) onPair;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Row(
          children: [
            Expanded(child: _SectionTitle(title: title, subtitle: subtitle)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
              ),
              onPressed: onScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text('Tidak ada perangkat ditemukan.', style: TextStyle(color: Colors.black.withOpacity(0.65)))
        else
          ...items.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: ListTile(
                  leading: Icon(p.type == PrinterType.bluetooth ? Icons.bluetooth : Icons.usb),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(p.id, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await onPair(p);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Berhasil pairing & disimpan')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal pairing: $e')),
                        );
                      }
                    },
                    child: const Text('Pair'),
                  ),
                ),
              )),
      ],
    );
  }
}

