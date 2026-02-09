import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../../../cashier/presentation/pages/cashier_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _pass = TextEditingController();

  bool _rememberMe = true;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _username.text.trim(),
      _pass.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CashierHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    const brand = Color(0xFFAE1504);
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0.8,
      //   titleSpacing: 12,
      //   title: Row(
      //     children: [
      //       // Logo (upload ke assets/images/cavaa_logo.png)
      //       Image.asset(
      //         'assets/images/cavaa_logo.png',
      //         height: 28,
      //         errorBuilder: (context, error, stackTrace) => const Text(
      //           'Cavaa',
      //           style: TextStyle(fontWeight: FontWeight.w800),
      //         ),
      //       ),
      //     ],
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () {},
      //       icon: const Icon(Icons.notifications_none_rounded),
      //       tooltip: 'Notifications',
      //     ),
      //     IconButton(
      //       onPressed: () {},
      //       icon: const Icon(Icons.menu_rounded),
      //       tooltip: 'Menu',
      //     ),
      //     const SizedBox(width: 6),
      //   ],
      // ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 520 : 480,
              ),
              child: _LoginCard(
                brand: brand,
                usernameController: _username,
                passController: _pass,
                rememberMe: _rememberMe,
                onRememberChanged: (v) => setState(() => _rememberMe = v),
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                isLoading: auth.isLoading,
                errorMessage: auth.errorMessage,
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.brand,
    required this.usernameController,
    required this.passController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.obscure,
    required this.onToggleObscure,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final Color brand;
  final TextEditingController usernameController;
  final TextEditingController passController;

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;

  final bool obscure;
  final VoidCallback onToggleObscure;

  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top icon circle
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: brand.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: brand.withOpacity(0.25)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12), // jarak logo ke lingkaran
                    child: Image.asset(
                      'assets/images/cavaa_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Cavaa',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Login Kasir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brand,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Masuk menggunakan akun pegawai Anda.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.black.withOpacity(0.62),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Username
            _Label('Username'),
            const SizedBox(height: 6),
            TextField(
              controller: usernameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: 'username',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brand, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password
            _Label('Password'),
            const SizedBox(height: 6),
            TextField(
              controller: passController,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  tooltip: obscure ? 'Show password' : 'Hide password',
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brand, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Remember me
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: isLoading ? null : (v) => onRememberChanged(v ?? false),
                  activeColor: brand,
                ),
                const Text('Remember me'),
                const Spacer(),
              ],
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => onSubmit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: brand.withOpacity(0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                '© 2026 Cavaa. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}
