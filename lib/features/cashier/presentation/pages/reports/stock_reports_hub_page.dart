import 'package:flutter/material.dart';

import '/features/owner/presentation/widgets/dock_inset.dart';
import 'stock_movement_report_page.dart';
import 'stock_variance_report_page.dart';

class StockReportsHubPage extends StatelessWidget {
  const StockReportsHubPage({
    super.key,
    required this.from,
    required this.to,
    required this.rangeLabel,
  });

  final String from;
  final String to;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Laporan Stok',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
        children: [
          Text(
            'Periode: $rangeLabel',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          _HubCard(
            icon: Icons.swap_vert_rounded,
            title: 'Mutasi & Penggunaan Bahan Baku',
            subtitle:
                'Lacak keluar-masuk bahan. Kolom Terpakai Resep dipotong otomatis setiap menu terjual di kasir.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockMovementReportPage(
                    from: from,
                    to: to,
                    rangeLabel: rangeLabel,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.balance_rounded,
            title: 'Selisih / Varian (Opname)',
            subtitle:
                'Bandingkan perkiraan pemakaian resep di sistem dengan stok fisik di akhir periode.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockVarianceReportPage(
                    from: from,
                    to: to,
                    rangeLabel: rangeLabel,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: brand),
            ],
          ),
        ),
      ),
    );
  }
}
