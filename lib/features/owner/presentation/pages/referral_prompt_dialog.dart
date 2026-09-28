import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
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
  final _code = TextEditingController();
  String _message = '';
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final api = ownerApiOf(context);
    setState(() => _busy = true);
    try {
      final res = await api.checkReferral(_code.text.trim());
      if (!mounted) return;
      setState(() => _message = (res['message'] ?? '').toString());
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Gagal memeriksa kode.');
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
        _message = _dioMessage(e, 'Gagal melewati kode.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Gagal melewati kode.';
      });
    }
  }

  Future<void> _apply() async {
    final api = ownerApiOf(context);
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final res = await api.applyReferral(_code.text.trim());
      final user = api.parseUser(res);
      if (!mounted) return;
      if (user != null) auth.applyOwner(user);
      navigator.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = _dioMessage(e, 'Kode tidak valid.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Punya kode referral?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Isi sekali sekarang. Setelah dilewati, kode tidak bisa ditambahkan.'),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Kode referral',
              border: OutlineInputBorder(),
            ),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_message),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _check,
          child: const Text('Cek'),
        ),
        TextButton(
          onPressed: _busy ? null : _skip,
          child: const Text('Lewati'),
        ),
        FilledButton(
          onPressed: _busy ? null : _apply,
          child: const Text('Pakai'),
        ),
      ],
    );
  }
}
