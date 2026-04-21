import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '/features/auth/data/models/user_model.dart';
import '/features/auth/presentation/auth_provider.dart';

class WorkScheduleProfilePage extends StatefulWidget {
  const WorkScheduleProfilePage({super.key});

  @override
  State<WorkScheduleProfilePage> createState() =>
      _WorkScheduleProfilePageState();
}

class _WorkScheduleProfilePageState extends State<WorkScheduleProfilePage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  static const _brand = Color(0xFFAE1504);
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refreshSchedule() async {
    await context.read<AuthProvider>().fetchMe();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final activeShift = user == null
        ? null
        : _activeShiftFor(user.workSchedule, _now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Kasir'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshSchedule,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Data user belum tersedia'))
          : RefreshIndicator(
              onRefresh: _refreshSchedule,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 14),
                  _CurrentShiftPanel(
                    now: _now,
                    activeShift: activeShift,
                    enforceWorkSchedule: user.enforceWorkSchedule,
                    hasSchedule: user.workSchedule.isNotEmpty,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Jam Kerja Minggu Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ..._days.map((day) {
                    final ranges = user.workSchedule[day] ?? const [];
                    return _ScheduleDayTile(
                      label: _dayLabels[day] ?? day,
                      ranges: ranges,
                      isToday: day == _dayKey(_now),
                      activeShift: activeShift,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  _ActiveShift? _activeShiftFor(
    Map<String, List<WorkScheduleRange>> schedule,
    DateTime now,
  ) {
    final today = _dayKey(now);
    final todayShift = _matchDay(schedule, today, now, baseDate: now);
    if (todayShift != null) return todayShift;

    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday = _dayKey(yesterdayDate);
    return _matchDay(
      schedule,
      yesterday,
      now,
      baseDate: yesterdayDate,
      overnightOnly: true,
    );
  }

  _ActiveShift? _matchDay(
    Map<String, List<WorkScheduleRange>> schedule,
    String day,
    DateTime now, {
    required DateTime baseDate,
    bool overnightOnly = false,
  }) {
    for (final range in schedule[day] ?? const <WorkScheduleRange>[]) {
      final start = _timeOnDate(baseDate, range.start);
      var end = _timeOnDate(baseDate, range.end);
      final isOvernight = !end.isAfter(start);

      if (overnightOnly && !isOvernight) continue;
      if (isOvernight) {
        end = end.add(const Duration(days: 1));
      }

      if (!now.isBefore(start) && now.isBefore(end)) {
        return _ActiveShift(day: day, range: range, startAt: start, endAt: end);
      }
    }

    return null;
  }

  DateTime _timeOnDate(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _dayKey(DateTime date) => _days[date.weekday - 1];
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildUserImageUrl(user.image);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.badge_outlined,
                      label: user.role.isEmpty ? 'Cashier' : user.role,
                    ),
                    _InfoChip(
                      icon: user.enforceWorkSchedule
                          ? Icons.lock_clock_outlined
                          : Icons.schedule_outlined,
                      label: user.enforceWorkSchedule
                          ? 'Jadwal wajib'
                          : 'Jadwal fleksibel',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _buildUserImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return null;

    final raw = imagePath.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanPath = raw.replaceFirst(RegExp(r'^/'), '');
    return '$base/storage/$cleanPath';
  }
}

class _CurrentShiftPanel extends StatelessWidget {
  const _CurrentShiftPanel({
    required this.now,
    required this.activeShift,
    required this.enforceWorkSchedule,
    required this.hasSchedule,
  });

  final DateTime now;
  final _ActiveShift? activeShift;
  final bool enforceWorkSchedule;
  final bool hasSchedule;

  @override
  Widget build(BuildContext context) {
    final shift = activeShift;
    final isActive = shift != null;
    final remaining = shift == null
        ? Duration.zero
        : shift.endAt.difference(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF7EE) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
              : const Color(0xFFEF6C00).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive
                    ? Icons.play_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFEF6C00),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isActive ? 'Jadwal sedang berjalan' : _inactiveTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isActive) ...[
            Text(
              '${shift.range.start} - ${shift.range.end}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa jam kerja: ${_formatDuration(remaining)}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else
            Text(
              _inactiveMessage,
              style: const TextStyle(color: Colors.black87, height: 1.35),
            ),
        ],
      ),
    );
  }

  String get _inactiveTitle {
    if (!hasSchedule) return 'Jadwal belum tersedia';
    return 'Tidak ada jadwal berjalan';
  }

  String get _inactiveMessage {
    if (!hasSchedule) {
      return 'Backend belum mengirim jadwal kerja untuk akun ini.';
    }
    if (enforceWorkSchedule) {
      return 'Saat ini tidak berada di rentang jam kerja yang aktif.';
    }
    return 'Tidak ada rentang jadwal aktif saat ini.';
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) parts.add('${hours}j');
    parts.add('${minutes.toString().padLeft(2, '0')}mnt');
    parts.add('${seconds.toString().padLeft(2, '0')}dtk');

    return parts.join(' ');
  }
}

class _ScheduleDayTile extends StatelessWidget {
  const _ScheduleDayTile({
    required this.label,
    required this.ranges,
    required this.isToday,
    required this.activeShift,
  });

  final String label;
  final List<WorkScheduleRange> ranges;
  final bool isToday;
  final _ActiveShift? activeShift;

  @override
  Widget build(BuildContext context) {
    final hasActiveRange = ranges.any(_isActiveRange);
    final borderColor = hasActiveRange
        ? const Color(0xFF2E7D32)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Row(
              children: [
                if (isToday)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: _WorkScheduleProfilePageState._brand,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ranges.isEmpty
                ? const Text('Libur', style: TextStyle(color: Colors.black45))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ranges.map((range) {
                      return _TimeBadge(
                        label: '${range.start} - ${range.end}',
                        active: _isActiveRange(range),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  bool _isActiveRange(WorkScheduleRange range) {
    final shift = activeShift;
    if (shift == null) return false;
    return shift.range.start == range.start && shift.range.end == range.end;
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFEAF7EE)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? activeColor.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? activeColor : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const brand = _WorkScheduleProfilePageState._brand;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return const CircleAvatar(
        radius: 30,
        backgroundColor: brand,
        child: Icon(Icons.person, color: Colors.white, size: 34),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: brand.withValues(alpha: 0.12),
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              color: brand,
              child: const Icon(Icons.person, color: Colors.white, size: 34),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveShift {
  const _ActiveShift({
    required this.day,
    required this.range,
    required this.startAt,
    required this.endAt,
  });

  final String day;
  final WorkScheduleRange range;
  final DateTime startAt;
  final DateTime endAt;
}
