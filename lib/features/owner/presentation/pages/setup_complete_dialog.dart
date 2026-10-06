import 'package:flutter/material.dart';

/// Returns `true` if the user wants to open Kasir.
Future<bool?> showSetupCompleteDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Setup selesai',
    barrierColor: const Color(0xCC1A0A08),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => const _SetupCompleteDialog(),
    transitionBuilder: (_, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curve, child: child),
      );
    },
  );
}

class _SetupCompleteDialog extends StatefulWidget {
  const _SetupCompleteDialog();

  @override
  State<_SetupCompleteDialog> createState() => _SetupCompleteDialogState();
}

class _SetupCompleteDialogState extends State<_SetupCompleteDialog>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFFAE1504);

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = _pulse.value;
                        return Transform.scale(
                          scale: 1 + (t * 0.06),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brand.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Selamat!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tokomu sudah siap untuk berjualan. Semua langkah setup selesai — silakan mulai dari Kasir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Buka Kasir',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Nanti saja',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.55),
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
    );
  }
}
