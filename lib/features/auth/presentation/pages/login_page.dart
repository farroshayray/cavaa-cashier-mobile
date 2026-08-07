import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '../auth_provider.dart';
import '../../../owner/presentation/pages/owner_home_page.dart';
import 'cashier_login_page.dart';
import 'owner_login_page.dart';
import 'owner_set_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialErrorMessage});

  final String? initialErrorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _localError;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _localError = widget.initialErrorMessage;
  }

  Future<void> _googleSignup() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _localError = null;
      _googleLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: Env.googleServerClientId.isEmpty
            ? null
            : Env.googleServerClientId,
      );

      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final authHeaders = await account.authentication;
      final idToken = authHeaders.idToken;
      if (idToken == null || idToken.isEmpty) {
        setState(() {
          _localError =
              'Gagal mendapatkan token Google. Pastikan Google Server Client ID sudah dikonfigurasi.';
          _googleLoading = false;
        });
        return;
      }

      final ok = await auth.ownerGoogle(idToken);
      if (!mounted) return;

      if (!ok) {
        setState(() {
          _localError = auth.errorMessage;
          _googleLoading = false;
        });
        return;
      }

      final needsPassword = auth.owner?.needsPassword == true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => needsPassword
              ? const OwnerSetPasswordPage()
              : const OwnerHomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localError = 'Google Sign-In gagal: $e';
        _googleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final auth = context.watch<AuthProvider>();
    final busy = _googleLoading || auth.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 520 : 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: brand.withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: brand.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: brand.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/cavaa_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text(
                                'Cavaa',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Cavaa Kasir',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: brand,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Pilih cara masuk ke aplikasi',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.black.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_localError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _localError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const OwnerLoginPage(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Login Owner',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CashierLoginPage(),
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brand,
                            side: BorderSide(color: brand.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login Kasir',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum punya akun owner? Daftar gratis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : _googleSignup,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.g_mobiledata, size: 24),
                                ),
                          label: const Text(
                            'Daftar dengan Google',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          '© 2026 Cavaa. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(child: _HubVersionText()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubVersionText extends StatelessWidget {
  const _HubVersionText();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final info = snapshot.data!;
        return Text(
          'Version ${info.version} (${info.buildNumber})',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.50),
          ),
        );
      },
    );
  }
}
