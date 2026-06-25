import 'package:flutter/material.dart';

import '../utils/order_tab_grouping.dart';

class OrderTabSectionHeader extends StatelessWidget {
  const OrderTabSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    this.compact = false,
  });

  static const brand = Color(0xFFAE1504);
  static const sectionBottomMargin = 6.0;

  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool compact;

  static double heightFor({required bool compact}) => compact ? 34 : 38;

  static double slotHeightFor({required bool compact, double topPadding = 0}) =>
      heightFor(compact: compact) + sectionBottomMargin + topPadding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 10 : 12);
    final bg = Theme.of(context).colorScheme.primaryContainer;
    final labelColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: heightFor(compact: compact),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: radius,
            splashColor: brand.withOpacity(0.08),
            highlightColor: brand.withOpacity(0.06),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 4 : 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: compact ? 18 : 20,
                    color: labelColor,
                  ),
                  SizedBox(width: compact ? 5 : 6),
                  Container(
                    constraints: BoxConstraints(minWidth: compact ? 18 : 20),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 5 : 6,
                      vertical: compact ? 1 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  final Widget child;
  final double height;
  final Color backgroundColor;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class OrderTabSectionFilterChips<T> extends StatelessWidget {
  const OrderTabSectionFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.chips,
    this.compact = false,
  });

  final T? selected;
  final ValueChanged<T?> onSelected;
  final List<({T? value, String label, int count})> chips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(12, 0, 12, compact ? 6 : 8),
      child: Row(
        children: [
          for (final chip in chips) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 6),
                    _ChipCountBadge(
                      count: chip.count,
                      selected: selected == chip.value,
                      compact: compact,
                    ),
                  ],
                ),
                selected: selected == chip.value,
                showCheckmark: false,
                selectedColor: brand.withOpacity(0.14),
                checkmarkColor: brand,
                side: BorderSide(
                  color: selected == chip.value
                      ? brand
                      : Colors.black.withOpacity(0.12),
                ),
                onSelected: (_) => onSelected(chip.value),
                visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 0 : 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipCountBadge extends StatelessWidget {
  const _ChipCountBadge({
    required this.count,
    required this.selected,
    required this.compact,
  });

  final int count;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 18 : 20),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: selected ? brand : brand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
          color: selected ? Colors.white : brand,
          height: 1.1,
        ),
      ),
    );
  }
}

List<Widget> buildPaymentSectionFilterChips({
  required List<Map<String, dynamic>> items,
  required PaymentSection? selected,
  required ValueChanged<PaymentSection?> onSelected,
  bool compact = false,
}) {
  final counts = paymentSectionCounts(items);

  return [
    OrderTabSectionFilterChips<PaymentSection>(
      selected: selected,
      onSelected: onSelected,
      compact: compact,
      chips: [
        (value: null, label: 'Semua', count: items.length),
        for (final s in paymentSectionOrder)
          (
            value: s,
            label: paymentSectionMeta(s).chipLabel,
            count: counts[s] ?? 0,
          ),
      ],
    ),
  ];
}

List<Widget> buildProcessSectionFilterChips({
  required List<Map<String, dynamic>> items,
  required ProcessSection? selected,
  required ValueChanged<ProcessSection?> onSelected,
  bool compact = false,
}) {
  final counts = processSectionCounts(items);

  return [
    OrderTabSectionFilterChips<ProcessSection>(
      selected: selected,
      onSelected: onSelected,
      compact: compact,
      chips: [
        (value: null, label: 'Semua', count: items.length),
        for (final s in processSectionOrder)
          (
            value: s,
            label: processSectionMeta(s).chipLabel,
            count: counts[s] ?? 0,
          ),
      ],
    ),
  ];
}

List<Widget> buildGroupedOrderSlivers<T>({
  required BuildContext context,
  required List<GroupedOrderSection<T>> sections,
  required Widget Function(BuildContext context, Map<String, dynamic> data, int index) itemBuilder,
  required bool Function(T section) isSectionExpanded,
  required ValueChanged<T> onToggleSection,
  bool compact = false,
}) {
  final slivers = <Widget>[];
  final slotBackground = Theme.of(context).colorScheme.surface;

  for (var i = 0; i < sections.length; i++) {
    final section = sections[i];
    final expanded = isSectionExpanded(section.section);
    final topPadding = i == 0 ? 8.0 : 0.0;
    final slotHeight = OrderTabSectionHeader.slotHeightFor(
      compact: compact,
      topPadding: topPadding,
    );

    slivers.add(
      SliverPersistentHeader(
        pinned: true,
        delegate: _SectionHeaderDelegate(
          height: slotHeight,
          backgroundColor: slotBackground,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              topPadding,
              12,
              OrderTabSectionHeader.sectionBottomMargin,
            ),
            child: OrderTabSectionHeader(
              title: section.title,
              count: section.items.length,
              isExpanded: expanded,
              onToggle: () => onToggleSection(section.section),
              compact: compact,
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final data = section.items[i];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  i == 0 ? 8 : 0,
                  12,
                  i == section.items.length - 1 ? 4 : 10,
                ),
                child: itemBuilder(context, data, i),
              );
            },
            childCount: section.items.length,
          ),
        ),
      );
    }
  }

  slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 12)));

  return slivers;
}
