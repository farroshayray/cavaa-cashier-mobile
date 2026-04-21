import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/remembered_login_storage.dart';
import '../../data/models/user_model.dart';
import '../auth_provider.dart';
import '../../../cashier/presentation/pages/cashier_home_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _forcedLogoutMessageKey = 'forced_logout_message';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialErrorMessage});

  final String? initialErrorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _pass = TextEditingController();
  final _rememberedLoginStorage = RememberedLoginStorage();

  bool _loadingRemembered = true;
  bool _rememberMe = true;
  bool _obscure = true;
  String? _forcedLogoutMessage;

  @override
  void dispose() {
    _username.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final data = await _rememberedLoginStorage.load();
    final forcedLogoutMessage =
        widget.initialErrorMessage ?? await _takeForcedLogoutMessage();

    if (!mounted) return;

    setState(() {
      _rememberMe = data['rememberMe'] as bool? ?? true;
      _username.text = data['username'] as String? ?? '';
      _pass.text = data['password'] as String? ?? '';
      _forcedLogoutMessage = forcedLogoutMessage;
      _loadingRemembered = false;
    });
  }

  Future<String?> _takeForcedLogoutMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final message = prefs.getString(_forcedLogoutMessageKey);
    await prefs.remove(_forcedLogoutMessageKey);
    return message?.trim().isEmpty == true ? null : message;
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final username = _username.text.trim();
    final password = _pass.text;

    if (_forcedLogoutMessage != null) {
      setState(() => _forcedLogoutMessage = null);
    }

    final ok = await auth.login(username, password, rememberMe: _rememberMe);

    if (!mounted) return;

    if (ok) {
      await _rememberedLoginStorage.save(
        username: username,
        password: password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CashierHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    const brand = Color(0xFFAE1504);
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    if (_loadingRemembered) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 520 : 480),
              child: _LoginCard(
                brand: brand,
                usernameController: _username,
                passController: _pass,
                rememberMe: _rememberMe,
                onRememberChanged: (v) => setState(() => _rememberMe = v),
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                isLoading: auth.isLoading,
                errorMessage: auth.errorMessage ?? _forcedLogoutMessage,
                blockedWorkSchedule: auth.blockedWorkSchedule,
                blockedWorkScheduleSummary: auth.blockedWorkScheduleSummary,
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.brand,
    required this.usernameController,
    required this.passController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.obscure,
    required this.onToggleObscure,
    required this.isLoading,
    required this.errorMessage,
    required this.blockedWorkSchedule,
    required this.blockedWorkScheduleSummary,
    required this.onSubmit,
  });

  final Color brand;
  final TextEditingController usernameController;
  final TextEditingController passController;

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;

  final bool obscure;
  final VoidCallback onToggleObscure;

  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<WorkScheduleRange>>? blockedWorkSchedule;
  final String? blockedWorkScheduleSummary;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top icon circle
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: brand.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      12,
                    ), // jarak logo ke lingkaran
                    child: Image.asset(
                      'assets/images/cavaa_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Cavaa',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Login Kasir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brand,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Masuk menggunakan akun pegawai Anda.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Username
            _Label('Username'),
            const SizedBox(height: 6),
            TextField(
              controller: usernameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: 'username',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brand, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password
            _Label('Password'),
            const SizedBox(height: 6),
            TextField(
              controller: passController,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  tooltip: obscure ? 'Show password' : 'Hide password',
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brand, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Remember me
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: isLoading
                      ? null
                      : (v) => onRememberChanged(v ?? false),
                  activeColor: brand,
                ),
                const Text('Remember me'),
                const Spacer(),
              ],
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (blockedWorkSchedule != null &&
                blockedWorkSchedule!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _NextWorkScheduleCountdown(
                schedule: blockedWorkSchedule!,
                summary: blockedWorkScheduleSummary,
                brand: brand,
              ),
            ],

            const SizedBox(height: 14),

            // Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => onSubmit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: brand.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                '© 2026 Cavaa. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.50),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(child: _AppVersionText()),
          ],
        ),
      ),
    );
  }
}

class _NextWorkScheduleCountdown extends StatefulWidget {
  const _NextWorkScheduleCountdown({
    required this.schedule,
    required this.summary,
    required this.brand,
  });

  final Map<String, List<WorkScheduleRange>> schedule;
  final String? summary;
  final Color brand;

  @override
  State<_NextWorkScheduleCountdown> createState() =>
      _NextWorkScheduleCountdownState();
}

class _NextWorkScheduleCountdownState
    extends State<_NextWorkScheduleCountdown> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  static const _days = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayLabels = <String, String>{
    'monday': 'Senin',
    'tuesday': 'Selasa',
    'wednesday': 'Rabu',
    'thursday': 'Kamis',
    'friday': 'Jumat',
    'saturday': 'Sabtu',
    'sunday': 'Minggu',
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextShift = _findNextShift(widget.schedule, _now);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock_outlined, color: widget.brand),
          const SizedBox(width: 10),
          Expanded(
            child: nextShift == null
                ? _NoNextShiftSummary(summary: widget.summary)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jam kerja berikutnya',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dayLabels[nextShift.day] ?? nextShift.day}, '
                        '${nextShift.range.start} - ${nextShift.range.end}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDuration(nextShift.startAt.difference(_now)),
                        style: TextStyle(
                          color: widget.brand,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  _UpcomingShift? _findNextShift(
    Map<String, List<WorkScheduleRange>> schedule,
    DateTime now,
  ) {
    _UpcomingShift? nearest;

    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      final day = _dayKey(date);

      for (final range in schedule[day] ?? const <WorkScheduleRange>[]) {
        final startAt = _timeOnDate(date, range.start);
        if (!startAt.isAfter(now)) continue;

        final candidate = _UpcomingShift(
          day: day,
          range: range,
          startAt: startAt,
        );

        if (nearest == null || candidate.startAt.isBefore(nearest.startAt)) {
          nearest = candidate;
        }
      }
    }

    return nearest;
  }

  DateTime _timeOnDate(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _dayKey(DateTime date) => _days[date.weekday - 1];

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final totalMinutes = safe.inMinutes;
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes ~/ 60) % 24;
    final minutes = totalMinutes % 60;
    final seconds = safe.inSeconds % 60;

    if (safe.inSeconds <= 0) return 'Mulai sekarang';

    final parts = <String>[];
    if (days > 0) parts.add('$days hari');
    if (hours > 0 || days > 0) parts.add('$hours jam');
    parts.add('$minutes menit');
    parts.add('$seconds detik');

    return parts.join(' ');
  }
}

class _NoNextShiftSummary extends StatelessWidget {
  const _NoNextShiftSummary({required this.summary});

  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Text(
      summary == null || summary!.isEmpty
          ? 'Belum ada jadwal kerja berikutnya.'
          : summary!,
      style: const TextStyle(
        color: Colors.black87,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UpcomingShift {
  const _UpcomingShift({
    required this.day,
    required this.range,
    required this.startAt,
  });

  final String day;
  final WorkScheduleRange range;
  final DateTime startAt;
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );
  }
}

class _AppVersionText extends StatelessWidget {
  const _AppVersionText();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final info = snapshot.data!;
        final version = info.version;
        final build = info.buildNumber;

        return Text(
          'Version $version ($build)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.50),
          ),
        );
      },
    );
  }
}
