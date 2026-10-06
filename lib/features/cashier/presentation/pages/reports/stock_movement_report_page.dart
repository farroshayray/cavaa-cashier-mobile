import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/network/dio_client.dart';
import '/features/cashier/data/report_api.dart';
import '/features/owner/presentation/widgets/dock_inset.dart';
import 'stock_ledger_page.dart';
import 'stock_report_export.dart';
import 'stock_report_widgets.dart';
class StockMovementReportPage extends StatefulWidget {
  const StockMovementReportPage({
    super.key,
    required this.from,
    required this.to,
    required this.rangeLabel,
  });

  final String from;
  final String to;
  final String rangeLabel;

  @override
  State<StockMovementReportPage> createState() =>
      _StockMovementReportPageState();
}

class _StockMovementReportPageState extends State<StockMovementReportPage> {
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ReportApi(context.read<DioClient>().dio);
      final res = await api.getStockMovementReport(
        from: widget.from,
        to: widget.to,
      );
      final data = res['data'];
      final raw = data is Map ? data['rows'] : null;
      setState(() {
        _rows = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final api = ReportApi(context.read<DioClient>().dio);
      await exportStockReportCsv(
        context: context,
        fetchCsv: () => api.exportStockMovementReport(
          from: widget.from,
          to: widget.to,
        ),
        fileName: 'mutasi_stok_${widget.from}_${widget.to}.xlsx',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openLedger(Map<String, dynamic> row) {
    final id = int.tryParse('${row['stock_id'] ?? ''}');
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StockLedgerPage(
          stockId: id,
          stockName: row['stock_name']?.toString() ?? 'Bahan',
          from: widget.from,
          to: widget.to,
          rangeLabel: widget.rangeLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Mutasi Bahan Baku',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: DockAwareFab(
        child: FloatingActionButton.extended(
          onPressed: (_loading || _exporting) ? null : _export,
          backgroundColor: brand,
          foregroundColor: Colors.white,
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(_exporting ? 'Exporting...' : 'Export Excel'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: brand))
          : RefreshIndicator(
              color: brand,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100)
                    .withBottomInset(context),
                children: [
                  Text(
                    'Periode: ${widget.rangeLabel}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lacak keluar-masuk bahan baku. Terpakai resep dipotong otomatis tiap penjualan. Ketuk card untuk kartu stok.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  if (_rows.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        'Belum ada data stok untuk periode ini.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  else
                    ..._rows.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: StockMovementMaterialCard(
                          row: r,
                          onTap: () => _openLedger(r),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
