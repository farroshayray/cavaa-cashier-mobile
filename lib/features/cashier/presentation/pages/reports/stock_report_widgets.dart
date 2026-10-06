import 'package:flutter/material.dart';

import 'stock_report_export.dart';

const stockReportBrand = Color(0xFFAE1504);

class StockReportMaterialCard extends StatelessWidget {
  const StockReportMaterialCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StockReportCodeChip extends StatelessWidget {
  const StockReportCodeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Compact label-over-value cell for metric grids.
class StockReportMetricCell extends StatelessWidget {
  const StockReportMetricCell({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: Colors.black.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: accent ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class StockMovementMaterialCard extends StatelessWidget {
  const StockMovementMaterialCard({
    super.key,
    required this.row,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = row['stock_name']?.toString() ?? '-';
    final code = row['stock_code']?.toString() ?? '';
    final unit = row['unit']?.toString() ?? '';
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 420;

    final metrics = [
      StockReportMetricCell(
        label: 'Awal',
        value: formatStockQty(row['opening'] as num?),
      ),
      StockReportMetricCell(
        label: 'Masuk',
        value: formatStockQty(row['in_purchase'] as num?),
        accent: const Color(0xFF15803D),
      ),
      StockReportMetricCell(
        label: 'Resep',
        value: formatStockQty(row['used_recipe'] as num?),
        accent: const Color(0xFFB45309),
      ),
      StockReportMetricCell(
        label: 'Waste',
        value: formatStockQty(row['waste'] as num?),
        accent: const Color(0xFFB91C1C),
      ),
    ];

    return StockReportMaterialCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (code.isNotEmpty || unit.isNotEmpty)
                        const TextSpan(text: '  '),
                      if (code.isNotEmpty)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: StockReportCodeChip(label: code),
                          ),
                        ),
                      if (unit.isNotEmpty)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: StockReportCodeChip(label: unit),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: stockReportBrand.withValues(alpha: 0.65),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: wide
                ? Row(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: metrics[i]),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: metrics[0]),
                          const SizedBox(width: 8),
                          Expanded(child: metrics[1]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: metrics[2]),
                          const SizedBox(width: 8),
                          Expanded(child: metrics[3]),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Akhir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Text(
                formatStockQty(row['ending'] as num?),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: stockReportBrand,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StockVarianceMaterialCard extends StatelessWidget {
  const StockVarianceMaterialCard({
    super.key,
    required this.row,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = row['stock_name']?.toString() ?? '-';
    final unit = row['unit']?.toString() ?? '';
    final variance = row['variance'];
    final varianceNum = variance is num ? variance.toDouble() : 0.0;
    final varianceColor = varianceNum < 0
        ? const Color(0xFFB91C1C)
        : varianceNum > 0
            ? const Color(0xFF15803D)
            : const Color(0xFF6B7280);
    final varianceLabel = varianceNum < 0
        ? 'Kurang'
        : varianceNum > 0
            ? 'Lebih'
            : 'Pas';
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return StockReportMaterialCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const TextSpan(text: '  '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: StockReportCodeChip(label: unit),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _VarianceSplitPill(
                label: varianceLabel,
                value: formatStockQty(row['variance'] as num?),
                color: varianceColor,
                compact: narrow,
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: stockReportBrand.withValues(alpha: 0.65),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: StockReportMetricCell(
                    label: 'Sistem',
                    value: formatStockQty(row['system_qty'] as num?),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StockReportMetricCell(
                    label: 'Fisik',
                    value: formatStockQty(row['physical_qty'] as num?),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StockReportMetricCell(
                    label: 'Nilai',
                    value: formatStockMoney(row['variance_value'] as num?),
                    accent: varianceColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'HPP ${formatStockMoney(row['unit_cost'] as num?)}'
            '${unit.isNotEmpty ? ' / $unit' : ''}',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge status selisih berbentuk pil terbelah (label | angka).
class _VarianceSplitPill extends StatelessWidget {
  const _VarianceSplitPill({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: compact ? 10.5 : 11.5,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.1,
    );

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 7 : 9,
                compact ? 4 : 5,
                compact ? 6 : 8,
                compact ? 4 : 5,
              ),
              child: Text(label, style: textStyle),
            ),
            Container(
              width: 1.5,
              color: color.withValues(alpha: 0.55),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 6 : 8,
                compact ? 4 : 5,
                compact ? 7 : 9,
                compact ? 4 : 5,
              ),
              child: Text(value, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class StockLedgerTimelineTile extends StatelessWidget {
  const StockLedgerTimelineTile({
    super.key,
    required this.line,
    required this.unit,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> line;
  final String unit;
  final bool isFirst;
  final bool isLast;

  String _qty(num? value) {
    if (value == null) return '-';
    final q = formatStockQty(value);
    return unit.isEmpty ? q : '$q $unit';
  }

  @override
  Widget build(BuildContext context) {
    final activity = line['activity']?.toString() ?? '-';
    final notes = line['notes']?.toString() ?? '';
    final when = line['datetime_label']?.toString() ??
        line['datetime']?.toString() ??
        '-';
    final qtyIn = line['qty_in'] as num?;
    final qtyOut = line['qty_out'] as num?;
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: stockReportBrand,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isLast ? Colors.transparent : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        when,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (narrow)
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        Text(
                          'In ${_qty(qtyIn)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: qtyIn == null
                                ? Colors.black.withValues(alpha: 0.35)
                                : const Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          'Out ${_qty(qtyOut)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: qtyOut == null
                                ? Colors.black.withValues(alpha: 0.35)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                        Text(
                          'Sisa ${_qty(line['balance'] as num?)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: stockReportBrand,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Masuk ${_qty(qtyIn)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: qtyIn == null
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Keluar ${_qty(qtyOut)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: qtyOut == null
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                        Text(
                          'Sisa ${_qty(line['balance'] as num?)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: stockReportBrand,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
