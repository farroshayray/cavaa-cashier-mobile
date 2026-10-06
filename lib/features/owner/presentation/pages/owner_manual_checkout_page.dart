import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '/features/owner/presentation/pages/owner_home_page.dart';
import '../widgets/dock_inset.dart';

class OwnerManualCheckoutPage extends StatefulWidget {
  const OwnerManualCheckoutPage({
    super.key,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.amount,
    this.period,
    this.periodLabel,
    this.revisionId,
    this.adminNote,
  });

  final String type;
  final int itemId;
  final String itemName;
  final int amount;
  final String? period;
  final String? periodLabel;

  /// Set when re-sending proof for a payment the admin rejected: the proof
  /// goes to that payment instead of creating a new one.
  final int? revisionId;

  /// The admin's rejection note, shown above the form in revision mode.
  final String? adminNote;

  bool get isRevision => revisionId != null;

  @override
  State<OwnerManualCheckoutPage> createState() =>
      _OwnerManualCheckoutPageState();
}

class _OwnerManualCheckoutPageState extends State<OwnerManualCheckoutPage> {
  static const _brand = Color(0xFFAE1504);

  List<Map<String, dynamic>> _banks = [];
  int? _selectedBankId;
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
        _selectedBankId = banks.length == 1 ? _bankId(banks.first) : null;
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
    final bankId = _selectedBankId;
    if (path == null || bankId == null || _banks.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final api = ownerApiOf(context);
      final revisionId = widget.revisionId;
      final res = revisionId != null
          ? await api.resubmitBillingRevision(
              type: widget.type,
              id: revisionId,
              bankId: bankId,
              proofPath: path,
            )
          : await api.submitManualPayment(
              type: widget.type,
              itemId: widget.itemId,
              period: widget.period,
              bankId: bankId,
              proofPath: path,
            );
      if (!mounted) return;
      Navigator.pop(
        context,
        res['message']?.toString() ??
            'Pembayaran diterima, sudah aktif. Admin akan memverifikasi bukti transfer.',
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

  int? _bankId(Map<String, dynamic> bank) {
    final raw = bank['id'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
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
        title: Text(widget.isRevision ? 'Kirim ulang bukti' : 'Transfer bank'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24).withBottomInset(context),
              children: [
                if (widget.isRevision &&
                    (widget.adminNote?.trim().isNotEmpty ?? false)) ...[
                  BillingAdminNoteCard(note: widget.adminNote!.trim()),
                  const SizedBox(height: 12),
                ],
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
                        'Pilih satu rekening tujuan, lalu transfer sesuai nominal.',
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
                      RadioGroup<int>(
                        groupValue: _selectedBankId,
                        onChanged: (value) {
                          if (value == null || value < 1) return;
                          setState(() => _selectedBankId = value);
                        },
                        child: Column(
                          children: [
                            for (final bank in _banks)
                              RadioListTile<int>(
                                value: _bankId(bank) ?? -1,
                                activeColor: _brand,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  (bank['bank_name'] ?? '').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  '${bank['account_no'] ?? ''}\na.n ${bank['account_name'] ?? ''}',
                                ),
                                secondary: IconButton(
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
                              ),
                          ],
                        ),
                      ),
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
                                  _selectedBankId == null ||
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
                            _sending
                                ? 'Mengirim...'
                                : widget.isRevision
                                ? 'Kirim ulang bukti'
                                : 'Kirim bukti',
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

/// The admin's reason for rejecting a manual payment.
class BillingAdminNoteCard extends StatelessWidget {
  const BillingAdminNoteCard({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33AE1504)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.feedback_outlined, color: Color(0xFFAE1504), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8E1103),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(color: Color(0xFF8E1103), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
