import 'package:flutter/material.dart';

enum PaymentSection {
  webConfirm,
  openBillReady,
  payAtCashier,
  qrisExpired,
}

enum ProcessSection {
  openBillConfirm,
  inProgress,
}

class GroupedOrderSection<T> {
  const GroupedOrderSection({
    required this.section,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.headerBgColor,
  });

  final T section;
  final List<Map<String, dynamic>> items;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color headerBgColor;
}

bool orderTabToBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes';
}

bool _isOpenBill(Map<String, dynamic> data) {
  final paymentMethod = (data['payment_method'] ?? '').toString().toUpperCase();
  return orderTabToBool(data['openbill_flag']) || paymentMethod == 'OPENBILL';
}

PaymentSection classifyPaymentSection(Map<String, dynamic> data) {
  final status = (data['order_status'] ?? '').toString().toUpperCase();
  final paymentMethod = (data['payment_method'] ?? '').toString().toUpperCase();

  if (status == 'PAYMENT REQUEST') {
    return PaymentSection.webConfirm;
  }
  if (status == 'EXPIRED' && paymentMethod == 'QRIS') {
    return PaymentSection.qrisExpired;
  }
  if (status == 'UNPAID' && _isOpenBill(data)) {
    return PaymentSection.openBillReady;
  }
  return PaymentSection.payAtCashier;
}

ProcessSection classifyProcessSection(Map<String, dynamic> data) {
  final status = (data['order_status'] ?? '').toString().toUpperCase();
  if (status == 'OPENBILL_CONFIRMATION') {
    return ProcessSection.openBillConfirm;
  }
  return ProcessSection.inProgress;
}

PaymentSectionMeta paymentSectionMeta(PaymentSection section) {
  switch (section) {
    case PaymentSection.webConfirm:
      return const PaymentSectionMeta(
        title: 'Konfirmasi Bayar',
        subtitle: 'Verifikasi bukti transfer customer',
        accentColor: Color(0xFFF59E0B),
        headerBgColor: Color(0xFFFFFBEB),
        chipLabel: 'Konfirmasi Bayar',
      );
    case PaymentSection.openBillReady:
      return const PaymentSectionMeta(
        title: 'Open Bill — Siap Bayar',
        subtitle: 'Kitchen selesai, menunggu pembayaran',
        accentColor: Color(0xFF0EA5E9),
        headerBgColor: Color(0xFFF0F9FF),
        chipLabel: 'Open Bill',
      );
    case PaymentSection.payAtCashier:
      return const PaymentSectionMeta(
        title: 'Bayar di Kasir',
        subtitle: 'Checkout di counter (cash / QRIS / manual)',
        accentColor: Color(0xFFAE1504),
        headerBgColor: Color(0xFFFFF7ED),
        chipLabel: 'Bayar di Kasir',
      );
    case PaymentSection.qrisExpired:
      return const PaymentSectionMeta(
        title: 'QRIS Kedaluwarsa',
        subtitle: 'Perlu regenerate atau ulang QRIS',
        accentColor: Color(0xFFEF4444),
        headerBgColor: Color(0xFFFFF1F2),
        chipLabel: 'QRIS Expired',
      );
  }
}

ProcessSectionMeta processSectionMeta(ProcessSection section) {
  switch (section) {
    case ProcessSection.openBillConfirm:
      return const ProcessSectionMeta(
        title: 'Konfirmasi Open Bill',
        subtitle: 'Order open bill baru, perlu konfirmasi cashier',
        accentColor: Color(0xFFF59E0B),
        headerBgColor: Color(0xFFFFFBEB),
        chipLabel: 'Konfirmasi OB',
      );
    case ProcessSection.inProgress:
      return const ProcessSectionMeta(
        title: 'Sedang Diproses',
        subtitle: 'Kitchen, serve, atau menunggu pesanan',
        accentColor: Color(0xFFAE1504),
        headerBgColor: Color(0xFFFFF7ED),
        chipLabel: 'Diproses',
      );
  }
}

class PaymentSectionMeta {
  const PaymentSectionMeta({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.headerBgColor,
    required this.chipLabel,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color headerBgColor;
  final String chipLabel;
}

class ProcessSectionMeta {
  const ProcessSectionMeta({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.headerBgColor,
    required this.chipLabel,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color headerBgColor;
  final String chipLabel;
}

const paymentSectionOrder = [
  PaymentSection.webConfirm,
  PaymentSection.openBillReady,
  PaymentSection.payAtCashier,
  PaymentSection.qrisExpired,
];

const processSectionOrder = [
  ProcessSection.openBillConfirm,
  ProcessSection.inProgress,
];

List<GroupedOrderSection<PaymentSection>> groupPaymentItems(
  List<Map<String, dynamic>> items, {
  PaymentSection? filter,
}) {
  final buckets = <PaymentSection, List<Map<String, dynamic>>>{
    for (final s in paymentSectionOrder) s: [],
  };

  for (final item in items) {
    buckets[classifyPaymentSection(item)]!.add(item);
  }

  return paymentSectionOrder
      .where((s) => filter == null || filter == s)
      .map((s) {
        final meta = paymentSectionMeta(s);
        return GroupedOrderSection<PaymentSection>(
          section: s,
          items: buckets[s]!,
          title: meta.title,
          subtitle: meta.subtitle,
          accentColor: meta.accentColor,
          headerBgColor: meta.headerBgColor,
        );
      })
      .where((g) => g.items.isNotEmpty)
      .toList();
}

List<GroupedOrderSection<ProcessSection>> groupProcessItems(
  List<Map<String, dynamic>> items, {
  ProcessSection? filter,
}) {
  final buckets = <ProcessSection, List<Map<String, dynamic>>>{
    for (final s in processSectionOrder) s: [],
  };

  for (final item in items) {
    buckets[classifyProcessSection(item)]!.add(item);
  }

  return processSectionOrder
      .where((s) => filter == null || filter == s)
      .map((s) {
        final meta = processSectionMeta(s);
        return GroupedOrderSection<ProcessSection>(
          section: s,
          items: buckets[s]!,
          title: meta.title,
          subtitle: meta.subtitle,
          accentColor: meta.accentColor,
          headerBgColor: meta.headerBgColor,
        );
      })
      .where((g) => g.items.isNotEmpty)
      .toList();
}

Map<PaymentSection, int> paymentSectionCounts(List<Map<String, dynamic>> items) {
  final counts = <PaymentSection, int>{
    for (final s in paymentSectionOrder) s: 0,
  };

  for (final item in items) {
    final section = classifyPaymentSection(item);
    counts[section] = counts[section]! + 1;
  }

  return counts;
}

Map<ProcessSection, int> processSectionCounts(List<Map<String, dynamic>> items) {
  final counts = <ProcessSection, int>{
    for (final s in processSectionOrder) s: 0,
  };

  for (final item in items) {
    final section = classifyProcessSection(item);
    counts[section] = counts[section]! + 1;
  }

  return counts;
}

/// Flat list of items in render order (for scroll-to-index).
List<Map<String, dynamic>> flattenGroupedItems<T>(
  List<GroupedOrderSection<T>> sections, {
  bool Function(T section)? isSectionExpanded,
}) {
  return sections
      .where((s) => isSectionExpanded == null || isSectionExpanded(s.section))
      .expand((s) => s.items)
      .toList();
}

/// Estimate scroll offset to a card inside grouped sections.
double estimateGroupedScrollOffset<T>({
  required List<GroupedOrderSection<T>> sections,
  required int orderId,
  required int Function(Map<String, dynamic>) toId,
  bool Function(T section)? isSectionExpanded,
  double sectionHeaderHeight = 44,
  double cardHeight = 170,
  double cardSpacing = 10,
  double listTopPadding = 12,
}) {
  var offset = listTopPadding;

  for (final section in sections) {
    offset += sectionHeaderHeight;

    final expanded =
        isSectionExpanded == null || isSectionExpanded(section.section);
    if (!expanded) continue;

    for (var i = 0; i < section.items.length; i++) {
      if (toId(section.items[i]) == orderId) {
        return offset;
      }
      offset += cardHeight + cardSpacing;
    }
  }

  return 0;
}
