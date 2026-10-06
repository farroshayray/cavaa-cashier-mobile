class WorkScheduleBlock {
  WorkScheduleBlock({
    required this.start,
    required this.end,
    Set<String>? days,
  }) : days = {...?days};

  String start;
  String end;
  Set<String> days;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'days': workScheduleDays.where(days.contains).toList(),
      };

  factory WorkScheduleBlock.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return WorkScheduleBlock(
      start: json['start']?.toString() ?? '09:00',
      end: json['end']?.toString() ?? '17:00',
      days: {
        if (rawDays is List) ...rawDays.map((e) => e.toString()),
      },
    );
  }
}

const workScheduleDays = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const workScheduleDayLabels = <String, String>{
  'monday': 'Senin',
  'tuesday': 'Selasa',
  'wednesday': 'Rabu',
  'thursday': 'Kamis',
  'friday': 'Jumat',
  'saturday': 'Sabtu',
  'sunday': 'Minggu',
};

List<WorkScheduleBlock> dayMapToBlocks(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => WorkScheduleBlock.fromJson(Map<String, dynamic>.from(e)))
        .map(
          (b) => WorkScheduleBlock(
            start: b.start,
            end: b.end,
            days: {...b.days},
          ),
        )
        .toList();
  }
  if (raw is! Map) return [];

  final groups = <String, WorkScheduleBlock>{};
  for (final day in workScheduleDays) {
    final list = raw[day];
    if (list is! List) continue;
    for (final item in list) {
      if (item is! Map) continue;
      final start = item['start']?.toString() ?? '';
      final end = item['end']?.toString() ?? '';
      if (start.isEmpty || end.isEmpty) continue;
      final key = '$start|$end';
      final existing = groups[key];
      if (existing == null) {
        groups[key] = WorkScheduleBlock(start: start, end: end, days: {day});
      } else {
        existing.days.add(day);
      }
    }
  }
  return groups.values.toList();
}

/// Prefer non-empty [blocks], otherwise convert day-map [schedule].
List<WorkScheduleBlock> profileToBlocks(Map<String, dynamic> profile) {
  final fromBlocks = dayMapToBlocks(profile['blocks']);
  final usableBlocks = fromBlocks
      .where((b) => b.start.isNotEmpty && b.end.isNotEmpty && b.days.isNotEmpty)
      .toList();
  if (usableBlocks.isNotEmpty) return usableBlocks;
  return dayMapToBlocks(profile['schedule'])
      .where((b) => b.start.isNotEmpty && b.end.isNotEmpty && b.days.isNotEmpty)
      .toList();
}

Map<String, List<Map<String, String>>> blocksToDayMap(
  List<WorkScheduleBlock> blocks,
) {
  final map = {for (final d in workScheduleDays) d: <Map<String, String>>[]};
  for (final block in blocks) {
    if (block.start.isEmpty || block.end.isEmpty) continue;
    for (final day in workScheduleDays) {
      if (!block.days.contains(day)) continue;
      map[day]!.add({'start': block.start, 'end': block.end});
    }
  }
  return map;
}

int _toMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

List<List<int>> _segments(String start, String end) {
  final s = _toMinutes(start);
  final e = _toMinutes(end);
  if (e > s) return [[s, e]];
  return [
    [s, 24 * 60],
    [0, e],
  ];
}

bool rangesOverlap(String aStart, String aEnd, String bStart, String bEnd) {
  for (final sa in _segments(aStart, aEnd)) {
    for (final sb in _segments(bStart, bEnd)) {
      if (sa[0] < sb[1] && sb[0] < sa[1]) return true;
    }
  }
  return false;
}

String? findScheduleOverlapError(List<WorkScheduleBlock> blocks) {
  final byDay = {for (final d in workScheduleDays) d: <WorkScheduleBlock>[]};
  for (final block in blocks) {
    if (block.start.isEmpty ||
        block.end.isEmpty ||
        block.start == block.end) {
      continue;
    }
    for (final day in block.days) {
      byDay[day]?.add(block);
    }
  }

  for (final day in workScheduleDays) {
    final ranges = byDay[day]!;
    for (var i = 0; i < ranges.length; i++) {
      for (var j = i + 1; j < ranges.length; j++) {
        if (rangesOverlap(
          ranges[i].start,
          ranges[i].end,
          ranges[j].start,
          ranges[j].end,
        )) {
          final label = workScheduleDayLabels[day] ?? day;
          return '$label: ${ranges[i].start}–${ranges[i].end} beririsan dengan ${ranges[j].start}–${ranges[j].end}.';
        }
      }
    }
  }
  return null;
}
