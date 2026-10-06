import 'package:flutter/material.dart';

Future<bool?> showWelcomeGiftDialog(
  BuildContext context, {
  required int points,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Hadiah Cavaa Points',
    barrierColor: const Color(0xCC1A0A08),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => _WelcomeGiftDialog(points: points),
    transitionBuilder: (_, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curve, child: child),
      );
    },
  );
}

class _WelcomeGiftDialog extends StatefulWidget {
  const _WelcomeGiftDialog({required this.points});

  final int points;

  @override
  State<_WelcomeGiftDialog> createState() => _WelcomeGiftDialogState();
}

class _WelcomeGiftDialogState extends State<_WelcomeGiftDialog>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFFAE1504);
  static const _gold = Color(0xFFF6C445);

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
    final label = _pointsLabel(widget.points);
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
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 168,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFAE1504),
                                  Color(0xFF7A0E02),
                                  Color(0xFF3D0701),
                                ],
                              ),
                            ),
                            child: SizedBox.expand(),
                          ),
                          Positioned(
                            top: -30,
                            right: -20,
                            child: _blob(120, _gold.withValues(alpha: 0.28)),
                          ),
                          Positioned(
                            bottom: -36,
                            left: -16,
                            child: _blob(100, Colors.white.withValues(alpha: 0.12)),
                          ),
                          const Positioned(
                            top: 18,
                            left: 22,
                            child: Icon(Icons.auto_awesome, color: _gold, size: 18),
                          ),
                          const Positioned(
                            top: 36,
                            right: 28,
                            child: Icon(Icons.star_rounded, color: _gold, size: 22),
                          ),
                          const Positioned(
                            bottom: 22,
                            right: 48,
                            child: Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                          ),
                          Positioned(
                            top: 8,
                            right: 4,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                            ),
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.94, end: 1.06).animate(
                              CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                            ),
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: _gold.withValues(alpha: 0.55),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.celebration_rounded,
                                color: _brand,
                                size: 42,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Column(
                        children: [
                          const Text(
                            'SELAMAT!',
                            style: TextStyle(
                              color: _brand,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Anda mendapatkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F2933),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cavaa Points',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _brand,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Hadiah karena mendaftar dengan kode referral. Poin ini bisa dipakai untuk langganan dan add-on.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.35,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: _brand,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.stars_rounded, size: 20),
                              label: const Text(
                                'Lihat Cavaa Points',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Tutup'),
                          ),
                        ],
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

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
