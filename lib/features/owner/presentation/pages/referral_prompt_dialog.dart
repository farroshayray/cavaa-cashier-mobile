import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import '/features/owner/data/welcome_gift_store.dart';
import '/features/owner/presentation/pages/owner_home_page.dart';

Future<void> showReferralPrompt(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  if (auth.owner?.needsReferralPrompt != true) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ReferralPromptDialog(),
  );
}

class _ReferralPromptDialog extends StatefulWidget {
  const _ReferralPromptDialog();

  @override
  State<_ReferralPromptDialog> createState() => _ReferralPromptDialogState();
}

class _ReferralPromptDialogState extends State<_ReferralPromptDialog> {
  static const _brand = Color(0xFFAE1504);

  final _code = TextEditingController();
  String _message = '';
  int? _welcome;
  bool? _valid;
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _lookup() async {
    final api = ownerApiOf(context);
    final res = await api.checkReferral(_code.text.trim());
    if (!mounted) return null;
    final valid = res['valid'] == true;
    final welcome = int.tryParse('${res['welcome_points'] ?? 0}') ?? 0;
    setState(() {
      _valid = valid;
      _welcome = valid ? welcome : null;
      _message = (res['message'] ?? '').toString();
    });
    return res;
  }

  Future<void> _check() async {
    if (_code.text.trim().isEmpty) {
      setState(() {
        _valid = false;
        _welcome = null;
        _message = 'Isi kode referral dulu.';
      });
      return;
    }
    setState(() => _busy = true);
    try {
      await _lookup();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _valid = false;
        _welcome = null;
        _message = 'Gagal memeriksa kode.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    final api = ownerApiOf(context);
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final res = await api.skipReferral();
      final user = api.parseUser(res);
      if (!mounted) return;
      if (user != null) auth.applyOwner(user);
      navigator.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _valid = false;
        _message = _dioMessage(e, 'Gagal melewati kode.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _valid = false;
        _message = 'Gagal melewati kode.';
      });
    }
  }

  Future<void> _apply() async {
    if (_code.text.trim().isEmpty) {
      setState(() {
        _valid = false;
        _welcome = null;
        _message = 'Isi kode referral dulu.';
      });
      return;
    }
    final api = ownerApiOf(context);
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      var welcome = _welcome ?? 0;
      if (_valid != true) {
        final checked = await _lookup();
        if (!mounted) return;
        if (checked == null || checked['valid'] != true) {
          setState(() => _busy = false);
          return;
        }
        welcome = int.tryParse('${checked['welcome_points'] ?? 0}') ?? 0;
      }
      final res = await api.applyReferral(_code.text.trim());
      final user = api.parseUser(res);
      if (!mounted) return;
      if (user != null) {
        auth.applyOwner(user);
        final gift = welcome > 0 ? welcome : user.cavaaPointsBalance;
        await WelcomeGiftStore.save(user.id, gift);
      }
      navigator.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _valid = false;
        _welcome = null;
        _message = _dioMessage(e, 'Kode tidak valid.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _valid = false;
        _message = 'Gagal memakai kode.';
      });
    }
  }

  String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  String _pointsLabel(int value) {
    final raw = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write('.');
      buf.write(raw[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _valid == true;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFAE1504), Color(0xFF6E0C02)],
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
                        SizedBox(height: 10),
                        Text(
                          'Punya kode referral?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Isi sekali sekarang. Kode yang valid memberi Cavaa Points.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          enabled: !_busy,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            fontSize: 16,
                          ),
                          onChanged: (_) {
                            if (_message.isEmpty && _valid == null) return;
                            setState(() {
                              _message = '';
                              _valid = null;
                              _welcome = null;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Kode referral',
                            hintText: 'Contoh FARROS42',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _brand, width: 1.4),
                            ),
                          ),
                        ),
                        if (_message.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _ResultBanner(
                            valid: valid,
                            message: valid && (_welcome ?? 0) > 0
                                ? 'Kode valid. Anda akan mendapat ${_pointsLabel(_welcome!)} Cavaa Points.'
                                : _message,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _busy ? null : _apply,
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Pakai kode',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _check,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _brand,
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: const Text('Cek kode'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: _busy ? null : _skip,
                                child: const Text('Lewati'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Setelah dilewati, kode tidak bisa ditambahkan lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.valid, required this.message});

  final bool valid;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = valid ? const Color(0xFF067647) : const Color(0xFFB42318);
    final bg = valid ? const Color(0xFFECFDF3) : const Color(0xFFFEF3F2);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
