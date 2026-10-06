import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal awal buku kasir. Mengembalikan nominal, atau null bila kasir keluar.
class OpeningCashDialog extends StatefulWidget {
  const OpeningCashDialog({super.key, this.leaveLabel = 'Keluar'});

  final String leaveLabel;

  @override
  State<OpeningCashDialog> createState() => _OpeningCashDialogState();
}

class _OpeningCashDialogState extends State<OpeningCashDialog> {
  static const _brand = Color(0xFFAE1504);

  final _controller = TextEditingController(text: '0');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectIfZero());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _selectIfZero() {
    if (_controller.text.replaceAll('.', '') != '0') return;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _save() {
    final amount = int.tryParse(_controller.text.replaceAll('.', '')) ?? 0;
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _brand,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Buka buku kasir',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan uang yang ada di laci. Angka ini menjadi modal awal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MODAL AWAL',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  inputFormatters: const [RupiahAmountFormatter()],
                  onTap: () => Future.microtask(_selectIfZero),
                  decoration: InputDecoration(
                    prefixText: 'Rp',
                    prefixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F7F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _brand, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text(
                      'Simpan modal',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.leaveLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Angka rupiah dengan pemisah ribuan. Nol di depan dibuang begitu ada angka lain.
class RupiahAmountFormatter extends TextInputFormatter {
  const RupiahAmountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    digits = digits.replaceFirst(RegExp(r'^0+(?=.)'), '');
    final formatted = _thousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _thousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
