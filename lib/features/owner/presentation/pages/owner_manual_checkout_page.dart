import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '/features/owner/presentation/pages/owner_home_page.dart';

class OwnerManualCheckoutPage extends StatefulWidget {
  const OwnerManualCheckoutPage({
    super.key,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.amount,
    this.period,
    this.periodLabel,
  });

  final String type;
  final int itemId;
  final String itemName;
  final int amount;
  final String? period;
  final String? periodLabel;

  @override
  State<OwnerManualCheckoutPage> createState() =>
      _OwnerManualCheckoutPageState();
}

class _OwnerManualCheckoutPageState extends State<OwnerManualCheckoutPage> {
  static const _brand = Color(0xFFAE1504);

  List<Map<String, dynamic>> _banks = [];
  String? _proofPath;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBanks();
    });
  }

  Future<void> _loadBanks() async {
    try {
      final res = await ownerApiOf(context).listTransferBanks();
      final raw = res['banks'];
      final banks = raw is List
          ? raw
              .whereType<Map>()
              .map((bank) => Map<String, dynamic>.from(bank))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _banks = banks;
        _loading = false;
        _error = banks.isEmpty ? 'Rekening tujuan tidak tersedia.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(e);
      });
    }
  }

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _proofPath = file.path);
  }

  Future<void> _submit() async {
    final path = _proofPath;
    if (path == null || _banks.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await ownerApiOf(context).submitManualPayment(
        type: widget.type,
        itemId: widget.itemId,
        period: widget.period,
        proofPath: path,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        res['message']?.toString() ??
            'Bukti terkirim. Setelah disetujui, tarik halaman untuk memperbarui akses.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(e))),
      );
    }
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) return value.first.toString();
            if (value != null && '$value'.trim().isNotEmpty) {
              return value.toString();
            }
          }
        }
        final message = data['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
    }
    return 'Bukti transfer gagal dikirim.';
  }

  String _idr(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.periodLabel?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Transfer bank'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (period.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          period,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_idr(widget.amount)}',
                        style: const TextStyle(
                          color: _brand,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Transfer sesuai nominal ini ke salah satu rekening di bawah.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekening tujuan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: _brand)),
                      ],
                      for (final bank in _banks) ...[
                        const Divider(height: 20),
                        Text(
                          (bank['bank_name'] ?? '').toString(),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (bank['account_no'] ?? '').toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Salin nomor',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: (bank['account_no'] ?? '').toString(),
                                  ),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nomor rekening disalin'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                        Text(
                          'a.n ${(bank['account_name'] ?? '').toString()}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bukti transfer',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (_proofPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_proofPath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _sending ? null : _pickProof,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _proofPath == null ? 'Pilih foto' : 'Ganti foto',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _proofPath == null ||
                                  _banks.isEmpty ||
                                  _sending
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _sending ? 'Mengirim...' : 'Kirim bukti',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
