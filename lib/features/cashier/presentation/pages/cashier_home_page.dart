import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'tabs/purchase_tab.dart' as purchase_tab;


class PaymentTab extends StatelessWidget {
  const PaymentTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Tab: Pembayaran'));
}

class ProcessTab extends StatelessWidget {
  const ProcessTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Tab: Proses'));
}

class DoneTab extends StatelessWidget {
  const DoneTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Tab: Selesai'));
}

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  int _index = 0; // default: Pembayaran (sesuai screenshot)
  final _tabs = const [
    purchase_tab.PurchaseTab(),
    PaymentTab(),
    ProcessTab(),
    DoneTab(),
  ];

  void _onTap(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _openBarcode() {
    // nanti bisa push ke halaman scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open barcode scanner...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/images/cavaa_logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Cavaa',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      // IndexedStack = state tiap tab aman (scroll, input, dsb)
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),

      // Tombol barcode menonjol di tengah
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom nav style “notch”
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64, // kunci tinggi bar
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Pembelian',
                    active: _index == 0,
                    onTap: () => _onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.payments_outlined,
                    label: 'Pembayaran',
                    active: _index == 1,
                    onTap: () => _onTap(1),
                  ),

                  _BarcodeNavItem(
                    active: false,
                    onTap: _openBarcode,
                  ),
 // ruang untuk FAB (lebih aman)

                  _NavItem(
                    icon: Icons.sync_rounded,
                    label: 'Proses',
                    active: _index == 2,
                    onTap: () => _onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Selesai',
                    active: _index == 3,
                    badge: 2,
                    onTap: () => _onTap(3),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final color = active ? brand : Colors.black54;

    Widget iconWidget = Icon(icon, color: color);

    if (badge != null && badge! > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color),
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,

              const SizedBox(height: 2),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}


class _BarcodeNavItem extends StatelessWidget {
  const _BarcodeNavItem({
    required this.onTap,
    this.active = false,
  });

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -10), // ⬅️ naik sedikit (floating)
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: brand.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
