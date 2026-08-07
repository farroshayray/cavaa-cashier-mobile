import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '../auth_provider.dart';
import '../../../owner/presentation/pages/owner_home_page.dart';
import 'owner_set_password_page.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _googleLoading = false;
  String? _localError;

  static const _brand = Color(0xFFAE1504);

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _goAfterOwnerLogin() {
    final auth = context.read<AuthProvider>();
    final needsPassword = auth.owner?.needsPassword == true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => needsPassword
            ? const OwnerSetPasswordPage()
            : const OwnerHomePage(),
      ),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.ownerLogin(_email.text.trim(), _pass.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _localError = auth.errorMessage);
      return;
    }
    _goAfterOwnerLogin();
  }

  Future<void> _googleLogin() async {
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

      _goAfterOwnerLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localError = 'Google Sign-In gagal: $e';
        _googleLoading = false;
      });
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black45),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final busy = _googleLoading || auth.isLoading;
    final error = _localError ?? auth.errorMessage;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Text(
                    'Login Owner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 520 : 480),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _brand.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: _brand,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Masuk sebagai Owner',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _brand,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gunakan email & password, atau akun Google.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: _fieldDecoration(
                                hint: 'nama@email.com',
                                icon: Icons.mail_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _pass,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => busy ? null : _submit(),
                              decoration: _fieldDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: busy ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brand,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _brand.withValues(alpha: 0.55),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: auth.isLoading && !_googleLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'atau lanjut dengan',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: busy ? null : _googleLogin,
                                icon: _googleLoading
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
                                            const Icon(
                                          Icons.g_mobiledata,
                                          size: 24,
                                        ),
                                      ),
                                label: const Text(
                                  'Masuk dengan Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
