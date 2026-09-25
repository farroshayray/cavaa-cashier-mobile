import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import '/features/auth/presentation/pages/login_page.dart';
import '/features/auth/presentation/pages/owner_set_password_page.dart';

class OwnerAccountPage extends StatefulWidget {
  const OwnerAccountPage({super.key});

  @override
  State<OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends State<OwnerAccountPage> {
  static const _brand = Color(0xFFAE1504);
  static const _bg = Color(0xFFF6F7F9);

  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final owner = context.read<AuthProvider>().owner;
    _name = TextEditingController(text: owner?.name ?? '');
    _phone = TextEditingController(text: owner?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('Nama tidak boleh kosong');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateOwnerProfile(
      name: name,
      phoneNumber: _phone.text.trim(),
    );
    if (ok) await auth.refreshOwner();
    if (!mounted) return;
    _toast(ok ? 'Profil diperbarui.' : (auth.errorMessage ?? 'Gagal menyimpan profil'));
  }

  Future<void> _savePassword() async {
    if (_current.text.isEmpty) {
      _toast('Isi password lama');
      return;
    }
    if (_next.text.length < 8) {
      _toast('Password baru minimal 8 karakter');
      return;
    }
    if (_next.text != _confirm.text) {
      _toast('Konfirmasi password tidak cocok');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.changeOwnerPassword(
      currentPassword: _current.text,
      password: _next.text,
      confirmation: _confirm.text,
    );
    if (!mounted) return;
    if (!ok) {
      _toast(auth.errorMessage ?? 'Gagal mengganti password');
      return;
    }
    _current.clear();
    _next.clear();
    _confirm.clear();
    _toast('Password berhasil diganti.');
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final owner = auth.owner;
    final name = (owner?.name ?? '').trim();
    final initial = name.isEmpty ? 'O' : name.characters.first.toUpperCase();
    final image = owner?.image?.trim() ?? '';
    final hasPassword = owner?.passwordIsSet == true;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Akun', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _Card(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _brand.withValues(alpha: 0.12),
                  backgroundImage: image.startsWith('http')
                      ? NetworkImage(image)
                      : null,
                  child: image.startsWith('http')
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Owner' : name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        owner?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email dipakai untuk masuk dan tidak bisa diubah di sini.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Data diri'),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _field('Nama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _field('Nomor telepon'),
                ),
                const SizedBox(height: 14),
                _PrimaryButton(
                  label: 'Simpan data diri',
                  busy: auth.isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Keamanan'),
                const SizedBox(height: 8),
                if (!hasPassword) ...[
                  const Text(
                    'Akun ini masuk lewat Google. Buat password agar bisa masuk tanpa Google.',
                    style: TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'Buat password',
                    busy: false,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OwnerSetPasswordPage(
                            continueToHome: false,
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  TextField(
                    controller: _current,
                    obscureText: _obscureCurrent,
                    decoration: _field(
                      'Password lama',
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _next,
                    obscureText: _obscureNext,
                    decoration: _field(
                      'Password baru',
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureNext = !_obscureNext),
                        icon: Icon(
                          _obscureNext
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    decoration: _field(
                      'Konfirmasi password baru',
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'Ganti password',
                    busy: auth.isLoading,
                    onPressed: _savePassword,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: auth.isLoading ? null : _logout,
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: _brand,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFAE1504),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
