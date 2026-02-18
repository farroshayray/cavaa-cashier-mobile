import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

import 'tabs/purchase_tab.dart' as purchase_tab;
import 'tabs/payment_tab.dart' as payment_tab;
import 'package:flutter/services.dart';


import '/features/cashier/presentation/pages/printer/printer_settings_page.dart';

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
  DateTime? _lastBackPressed;

  int _index = 0;
  final _tabs = const [
    purchase_tab.PurchaseTab(),
    payment_tab.PaymentTab(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open barcode scanner...')),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar aplikasi'),
          duration: Duration(seconds: 2),
        ),
      );

      return false; // jangan keluar dulu
    }

    return true; // keluar aplikasi
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar aplikasi'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // keluar aplikasi (pop route root)
        SystemNavigator.pop();
      },
      child: Scaffold(
        drawer: _AppDrawer(
          onOpenPrinterSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
            );
          },
          onLogout: _logout,
        ),
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
        ),
        body: IndexedStack(
          index: _index,
          children: _tabs,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
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
          offset: const Offset(0, -10),
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onOpenPrinterSettings,
    required this.onLogout,
  });

  final VoidCallback onOpenPrinterSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: brand),
              title: const Text('Pairing Printer'),
              subtitle: const Text('Bluetooth / Kabel (USB)'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenPrinterSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
