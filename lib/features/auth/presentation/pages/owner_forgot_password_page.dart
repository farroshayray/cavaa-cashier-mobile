import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';

class OwnerForgotPasswordPage extends StatefulWidget {
  const OwnerForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<OwnerForgotPasswordPage> createState() =>
      _OwnerForgotPasswordPageState();
}

class _OwnerForgotPasswordPageState extends State<OwnerForgotPasswordPage> {
  static const _brand = Color(0xFFAE1504);

  late final TextEditingController _email;
  String? _localError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Masukkan email yang valid');
      return;
    }

    setState(() {
      _localError = null;
      _successMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final message = await auth.ownerForgotPassword(email);
    if (!mounted) return;

    if (message == null) {
      setState(() => _localError = auth.errorMessage);
      return;
    }

    setState(() => _successMessage = message);
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
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
    final busy = auth.isLoading;
    final error = _localError ?? auth.errorMessage;
    final sent = _successMessage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Lupa password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _brand.withValues(alpha: 0.12)),
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
                  child: sent
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_outlined,
                                  color: Colors.green,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cek email Anda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _brand,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _successMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Buka link di browser untuk membuat/mengatur password, lalu kembali ke aplikasi untuk login. Berlaku juga jika Anda biasanya masuk dengan Google.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brand,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Kembali ke login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
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
                                  Icons.lock_reset_rounded,
                                  color: _brand,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Reset password Owner',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _brand,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masukkan email akun owner Anda (termasuk yang biasa login Google). Kami akan kirim link reset ke email.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
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
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              enableSuggestions: false,
                              onSubmitted: (_) => busy ? null : _submit(),
                              decoration: _fieldDecoration(
                                hint: 'nama@email.com',
                                icon: Icons.mail_outline_rounded,
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
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    height: 1.25,
                                  ),
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
                                child: busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Kirim link reset',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
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
    );
  }
}
