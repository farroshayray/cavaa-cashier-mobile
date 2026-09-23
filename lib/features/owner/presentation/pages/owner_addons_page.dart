import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '/core/utils/open_url.dart';
import '/features/auth/presentation/auth_provider.dart';
import '/features/owner/presentation/pages/owner_home_page.dart';

class OwnerAddonsPage extends StatefulWidget {
  const OwnerAddonsPage({
    super.key,
    this.highlightFeatureKey,
    this.highlightAddonCode,
  });

  /// Feature key from FeatureGate, e.g. `feature_scan_table`.
  final String? highlightFeatureKey;

  /// Addon catalog code, e.g. `scan_table`.
  final String? highlightAddonCode;

  @override
  State<OwnerAddonsPage> createState() => _OwnerAddonsPageState();
}

class _OwnerAddonsPageState extends State<OwnerAddonsPage> {
  static const _brand = Color(0xFFAE1504);
  static const _bg = Color(0xFFF6F7F9);

  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _addons = [];
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentPlan;
  List<Map<String, dynamic>> _overlapping = [];
  bool _playConfigured = false;
  bool _allowPlay = true;
  bool _allowManual = false;
  final ScrollController _scrollController = ScrollController();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, ProductDetails> _products = {};

  bool _isHighlighted(Map<String, dynamic> addon) {
    final code = (addon['code'] ?? '').toString();
    final feature = (addon['feature_key'] ?? '').toString();
    final wantCode = widget.highlightAddonCode?.trim() ?? '';
    final wantFeature = widget.highlightFeatureKey?.trim() ?? '';
    if (wantCode.isNotEmpty && code == wantCode) return true;
    if (wantFeature.isNotEmpty && feature == wantFeature) return true;
    return false;
  }

  /// Highlighted add-on first so paywall entry lands on the relevant card.
  List<Map<String, dynamic>> get _displayAddons {
    final want = widget.highlightAddonCode != null ||
        widget.highlightFeatureKey != null;
    if (!want || _addons.isEmpty) return _addons;
    final pinned = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    for (final a in _addons) {
      if (_isHighlighted(a)) {
        pinned.add(a);
      } else {
        rest.add(a);
      }
    }
    if (pinned.isEmpty) return _addons;
    return [...pinned, ...rest];
  }

  @override
  void initState() {
    super.initState();
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );
    _load();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ownerApiOf(context);
    try {
      final res = await api.listAddons();
      final raw = res['addons'];
      _addons = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : [];
      final overlap = res['overlapping_subscriptions'];
      _overlapping = overlap is List
          ? overlap
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : [];
      final plansRes = await api.listPlans();
      final rawPlans = plansRes['plans'];
      _plans = rawPlans is List
          ? rawPlans
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : [];
      final current = plansRes['current_plan'];
      _currentPlan = current is Map
          ? Map<String, dynamic>.from(current)
          : null;
      _playConfigured = res['play_configured'] == true ||
          plansRes['play_configured'] == true;
      _readBilling(res);
      _readBilling(plansRes);

      final ids = {
        ..._addons.map((a) => (a['play_product_id'] ?? '').toString()),
        ..._plans.map((p) => (p['play_product_id'] ?? '').toString()),
      }.where((id) => id.isNotEmpty).toSet();
      if (ids.isNotEmpty) {
        final available = await _iap.isAvailable();
        if (available) {
          final resp = await _iap.queryProductDetails(ids);
          for (final p in resp.productDetails) {
            _products[p.id] = p;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(purchase.error?.message ?? 'Pembelian gagal'),
            ),
          );
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _confirmWithBackend(purchase);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  void _readBilling(Map<String, dynamic> res) {
    final billing = res['billing'];
    if (billing is Map) {
      _allowPlay = billing['play'] == true;
      _allowManual = billing['manual'] == true;
    }
  }

  Future<void> _openManualCheckout(String type, Object? id) async {
    final itemId = id is int ? id : int.tryParse('$id');
    if (itemId == null || itemId <= 0) return;
    final api = ownerApiOf(context);
    setState(() => _busy = true);
    try {
      final res = await api.createCheckoutLink(type: type, itemId: itemId);
      final url = (res['url'] ?? '').toString();
      if (url.isEmpty) {
        throw Exception('Tautan pembayaran kosong');
      }
      await openExternalUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lanjutkan transfer di browser. Setelah disetujui, tarik halaman ini untuk memperbarui akses.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isPlanProduct(String productId) {
    return _plans.any(
      (plan) => (plan['play_product_id'] ?? '').toString() == productId,
    );
  }

  Future<void> _confirmWithBackend(PurchaseDetails purchase) async {
    final api = ownerApiOf(context);
    setState(() => _busy = true);
    try {
      final token = purchase.verificationData.serverVerificationData;
      final res = _isPlanProduct(purchase.productID)
          ? await api.confirmPlanPurchase(
              productId: purchase.productID,
              purchaseToken: token,
            )
          : await api.confirmAddonPurchase(
              productId: purchase.productID,
              purchaseToken: token,
            );
      final user = api.parseUser(res);
      if (user != null && mounted) {
        await context.read<AuthProvider>().refreshOwner();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Add-on aktif')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(Map<String, dynamic> addon) async {
    if (addon['can_purchase'] != true) return;
    final productId = (addon['play_product_id'] ?? '').toString();
    if (productId.isEmpty) return;

    final details = _products[productId];
    if (details == null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Produk Play belum tersedia'),
          content: Text(
            _playConfigured
                ? 'SKU "$productId" belum muncul dari Google Play. Pastikan internal testing + license tester.\n\nLanjut dengan stub token (hanya jika server GOOGLE_PLAY_DEV_STUB=true)?'
                : 'Google Play Billing belum dikonfigurasi di server. Lanjut stub token untuk uji lokal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stub confirm'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final api = ownerApiOf(context);
      setState(() => _busy = true);
      try {
        final res = await api.confirmAddonPurchase(
          productId: productId,
          purchaseToken: 'DEV-STUB-${DateTime.now().millisecondsSinceEpoch}',
        );
        await context.read<AuthProvider>().refreshOwner();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Add-on aktif'),
            ),
          );
          await _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    final billingType = (addon['billing_type'] ?? '').toString();
    final param = PurchaseParam(productDetails: details);
    if (billingType == 'subscription') {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> _buyPlan(Map<String, dynamic> plan) async {
    if (plan['can_purchase'] != true) return;
    final productId = (plan['play_product_id'] ?? '').toString();
    if (productId.isEmpty) return;

    final details = _products[productId];
    if (details == null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Produk Play belum tersedia'),
          content: Text(
            _playConfigured
                ? 'SKU "$productId" belum muncul dari Google Play. Pastikan internal testing + license tester.\n\nLanjut dengan stub token (hanya jika server GOOGLE_PLAY_DEV_STUB=true)?'
                : 'Google Play Billing belum dikonfigurasi di server. Lanjut stub token untuk uji lokal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stub confirm'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final api = ownerApiOf(context);
      setState(() => _busy = true);
      try {
        final res = await api.confirmPlanPurchase(
          productId: productId,
          purchaseToken: 'DEV-STUB-${DateTime.now().millisecondsSinceEpoch}',
        );
        await context.read<AuthProvider>().refreshOwner();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']?.toString() ?? 'Paket aktif')),
          );
          await _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  (String amount, String suffix) _planPrice(Map<String, dynamic> plan) {
    final productId = (plan['play_product_id'] ?? '').toString();
    final play = _products[productId];
    if (play != null) {
      return (play.price, '');
    }
    final raw = plan['price'];
    final n = raw is num ? raw : num.tryParse('$raw') ?? 0;
    final cycle = (plan['billing_cycle'] ?? '').toString().trim();
    return ('Rp ${_formatIdr(n)}', cycle.isEmpty ? '' : cycle);
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final isCurrent = plan['is_current'] == true;
    final canBuy = plan['can_purchase'] == true;
    final hasSku = ((plan['play_product_id'] ?? '').toString()).isNotEmpty;
    final parts = _planPrice(plan);
    final name = (plan['name'] ?? '').toString();
    final description = (plan['description'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? _brand : const Color(0xFFE5E7EB),
              width: isCurrent ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const _Chip(
                      label: 'Paket aktif',
                      fg: _brand,
                      bg: Color(0xFFFFF1EE),
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: parts.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _brand,
                      ),
                    ),
                    if (parts.$2.isNotEmpty)
                      TextSpan(
                        text: ' ${parts.$2}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_allowPlay && !isCurrent)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: canBuy && !_busy ? () => _buyPlan(plan) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF6B7280),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasSku ? 'Beli paket' : 'Belum tersedia di Play',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              if (isCurrent)
                const SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: null,
                    child: Text(
                      'Sedang dipakai',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              if (_allowManual && !isCurrent) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _openManualCheckout('plan', plan['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: _brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Transfer bank',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await _iap.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore dikirim ke Google Play')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _formatIdr(num n) {
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  /// Returns (amount text, period suffix). Play price kept as-is when available.
  (String amount, String suffix) _priceParts(Map<String, dynamic> addon) {
    final productId = (addon['play_product_id'] ?? '').toString();
    final play = _products[productId];
    if (play != null) {
      return (play.price, '');
    }
    final raw = addon['price_idr'];
    final n = raw is num ? raw : num.tryParse('$raw') ?? 0;
    final period = (addon['billing_period'] ?? '').toString();
    final amount = 'Rp ${_formatIdr(n)}';
    if (period == 'month') return (amount, '/bln');
    return (amount, 'sekali bayar');
  }

  _AddonVisual _visualFor(String code) {
    switch (code) {
      case 'receipt_logo':
        return const _AddonVisual(
          icon: Icons.receipt_long_rounded,
          accent: Color(0xFFB45309),
          soft: Color(0xFFFFF7ED),
        );
      case 'order_notes':
        return const _AddonVisual(
          icon: Icons.sticky_note_2_rounded,
          accent: Color(0xFF0369A1),
          soft: Color(0xFFF0F9FF),
        );
      case 'promotions':
        return const _AddonVisual(
          icon: Icons.local_offer_rounded,
          accent: Color(0xFF7C3AED),
          soft: Color(0xFFF5F3FF),
        );
      case 'scan_table':
        return const _AddonVisual(
          icon: Icons.qr_code_2_rounded,
          accent: _brand,
          soft: Color(0xFFFFF1EE),
        );
      case 'open_bill':
        return const _AddonVisual(
          icon: Icons.payments_rounded,
          accent: Color(0xFF0369A1),
          soft: Color(0xFFF0F9FF),
        );
      default:
        return const _AddonVisual(
          icon: Icons.extension_rounded,
          accent: _brand,
          soft: Color(0xFFFFF1EE),
        );
    }
  }

  String _ctaLabel({
    required bool covered,
    required bool owned,
    required bool isSub,
  }) {
    if (covered) return 'Sudah termasuk paket';
    if (owned) return 'Sudah aktif';
    return isSub ? 'Langganan sekarang' : 'Beli sekali';
  }

  @override
  Widget build(BuildContext context) {
    final displayAddons = _displayAddons;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Paket',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            child: const Text(
              'Restore',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _brand,
                  onRefresh: _load,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      const _HeroBanner(),
                      if (_currentPlan != null) ...[
                        const SizedBox(height: 12),
                        _CurrentPlanBanner(plan: _currentPlan!),
                      ],
                      if (_overlapping.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _OverlapBanner(messages: _overlapping),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Paket penuh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengganti seluruh akses paket. Add-on yang sudah dibeli tetap ada.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_plans.isEmpty)
                        const _EmptyNote(
                          text: 'Belum ada paket yang ditawarkan di aplikasi.',
                        )
                      else
                        ..._plans.map(_planCard),
                      const SizedBox(height: 8),
                      Text(
                        'Add-on fitur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...displayAddons.map((addon) {
                        final covered = addon['covered_by_plan'] == true;
                        final owned = addon['owned'] == true;
                        final canBuy = addon['can_purchase'] == true;
                        final code = (addon['code'] ?? '').toString();
                        final highlighted = _isHighlighted(addon);
                        final visual = _visualFor(code);
                        final isSub =
                            (addon['billing_type'] ?? '').toString() ==
                                'subscription';
                        final parts = _priceParts(addon);
                        final status =
                            (addon['status_label'] ?? '').toString();
                        final overlap =
                            addon['overlapping_subscription'] == true;

                        final card = Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AddonCard(
                            name: (addon['name'] ?? '').toString(),
                            description:
                                (addon['description'] ?? '').toString(),
                            visual: visual,
                            amount: parts.$1,
                            periodSuffix: parts.$2,
                            isSubscription: isSub,
                            highlighted: highlighted,
                            covered: covered,
                            owned: owned,
                            statusLabel: status,
                            overlapping: overlap,
                            ctaLabel: _ctaLabel(
                              covered: covered,
                              owned: owned,
                              isSub: isSub,
                            ),
                            canBuy: canBuy && !_busy && _allowPlay,
                            onBuy: () => _buy(addon),
                            showManual: _allowManual && canBuy,
                            showPlay: _allowPlay,
                            onTransfer: () =>
                                _openManualCheckout('addon', addon['id']),
                          ),
                        );

                        if (!highlighted) return card;
                        return _AutoScrollIntoView(child: card);
                      }),
                    ],
                  ),
                ),
    );
  }
}

/// Scrolls this subtree into view once after layout (and route transition).
class _AutoScrollIntoView extends StatefulWidget {
  const _AutoScrollIntoView({required this.child});

  final Widget child;

  @override
  State<_AutoScrollIntoView> createState() => _AutoScrollIntoViewState();
}

class _AutoScrollIntoViewState extends State<_AutoScrollIntoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollIntoView());
  }

  Future<void> _scrollIntoView() async {
    // Wait for page transition + ListView extent calculation.
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    for (var attempt = 0; attempt < 20; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final object = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (object == null || !object.attached || scrollable == null) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        continue;
      }

      final position = scrollable.position;
      if (!position.hasContentDimensions) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        continue;
      }

      final viewport = RenderAbstractViewport.maybeOf(object);
      if (viewport == null) {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.06,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
        return;
      }

      final raw = viewport.getOffsetToReveal(object, 0.06).offset;
      final target = raw.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      // Extent not ready yet but we clearly need to scroll.
      if (raw > 24 && position.maxScrollExtent < 8) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        continue;
      }

      if ((position.pixels - target).abs() < 2) return;

      await position.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AddonVisual {
  const _AddonVisual({
    required this.icon,
    required this.accent,
    required this.soft,
  });

  final IconData icon;
  final Color accent;
  final Color soft;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  static const _brand = Color(0xFFAE1504);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFAE1504),
            Color(0xFF7A0E03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tingkatkan tokomu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Aktifkan fitur ekstra sesuai kebutuhan — bayar sekali atau langganan bulanan lewat Google Play.',
                  style: TextStyle(
                    color: Color(0xFFFFE4E0),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.plan});

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final name = (plan['name'] ?? 'Paket').toString();
    final isFree = plan['is_mobile_free'] == true;
    final expires = (plan['expires_at'] ?? '').toString();
    final parsed = DateTime.tryParse(expires);
    final expiryLabel = parsed == null
        ? expires
        : '${parsed.toLocal().day}/${parsed.toLocal().month}/${parsed.toLocal().year}';
    final subtitle = isFree
        ? 'Paket gratis aplikasi kasir. Upgrade kapan saja.'
        : expires.isEmpty
            ? 'Paket berbayar sedang aktif.'
            : 'Berlaku sampai $expiryLabel';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFAE1504)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paket aktif: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }
}

class _OverlapBanner extends StatelessWidget {
  const _OverlapBanner({required this.messages});

  final List<Map<String, dynamic>> messages;

  @override
  Widget build(BuildContext context) {
    final text = messages
        .map((e) => (e['message'] ?? '').toString())
        .where((m) => m.isNotEmpty)
        .join('\n');
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A3412),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAE1504),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddonCard extends StatelessWidget {
  const _AddonCard({
    required this.name,
    required this.description,
    required this.visual,
    required this.amount,
    required this.periodSuffix,
    required this.isSubscription,
    required this.highlighted,
    required this.covered,
    required this.owned,
    required this.statusLabel,
    required this.overlapping,
    required this.ctaLabel,
    required this.canBuy,
    required this.onBuy,
    this.showManual = false,
    this.showPlay = true,
    this.onTransfer,
  });

  final String name;
  final String description;
  final _AddonVisual visual;
  final String amount;
  final String periodSuffix;
  final bool isSubscription;
  final bool highlighted;
  final bool covered;
  final bool owned;
  final String statusLabel;
  final bool overlapping;
  final String ctaLabel;
  final bool canBuy;
  final VoidCallback onBuy;
  final bool showManual;
  final bool showPlay;
  final VoidCallback? onTransfer;

  static const _brand = Color(0xFFAE1504);
  static const _ink = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    final active = owned || covered;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? _brand : const Color(0xFFE8EAED),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? _brand.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: highlighted ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: visual.soft,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, size: 18, color: _brand),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Direkomendasikan untuk fitur yang kamu buka',
                      style: TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: visual.soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: _ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Chip(
                                label: isSubscription
                                    ? 'Langganan'
                                    : 'Sekali bayar',
                                fg: visual.accent,
                                bg: visual.soft,
                              ),
                              if (active)
                                _Chip(
                                  label: covered ? 'Di paket' : 'Aktif',
                                  fg: const Color(0xFF15803D),
                                  bg: const Color(0xFFDCFCE7),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: amount,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _brand,
                                      height: 1.1,
                                    ),
                                  ),
                                  if (periodSuffix.isNotEmpty)
                                    TextSpan(
                                      text: periodSuffix.startsWith('/')
                                          ? periodSuffix
                                          : ' · $periodSuffix',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (statusLabel.isNotEmpty)
                        Flexible(
                          child: Text(
                            statusLabel,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? const Color(0xFF15803D)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (overlapping) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Langganan Play masih aktif sementara paket sudah mencakup fitur ini. Batalkan di Google Play.',
                    style: TextStyle(
                      color: Color(0xFFC2410C),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (showPlay || !showManual)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: canBuy ? onBuy : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        disabledForegroundColor: const Color(0xFF6B7280),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      child: Text(ctaLabel),
                    ),
                  ),
                if (showManual) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onTransfer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brand,
                        side: const BorderSide(color: _brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Transfer bank',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
