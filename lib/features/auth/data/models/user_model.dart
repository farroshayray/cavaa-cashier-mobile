class WorkScheduleRange {
  final String start;
  final String end;

  const WorkScheduleRange({required this.start, required this.end});

  factory WorkScheduleRange.fromJson(Map<String, dynamic> json) {
    return WorkScheduleRange(
      start: (json['start'] ?? '').toString(),
      end: (json['end'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }

  bool get isValid => _validTime(start) && _validTime(end) && start != end;

  static bool _validTime(String value) {
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }
}

class UserModel {
  final int id;
  final String name;
  final String userName;
  final String role;
  final int? partnerId;
  final String? image;
  final bool isActive;
  final bool isActiveAdmin;
  final bool enforceWorkSchedule;
  final Map<String, List<WorkScheduleRange>> workSchedule;

  UserModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.role,
    required this.partnerId,
    this.image,
    this.isActive = true,
    this.isActiveAdmin = true,
    this.enforceWorkSchedule = false,
    this.workSchedule = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      userName: (json['user_name'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      partnerId: json['partner_id'] as int?,
      image: json['image']?.toString(),
      isActive: _parseBool(json['is_active'], defaultValue: true),
      isActiveAdmin: _parseBool(json['is_active_admin'], defaultValue: true),
      enforceWorkSchedule: _parseBool(
        json['enforce_work_schedule'],
        defaultValue: false,
      ),
      workSchedule: UserModel.parseWorkSchedule(json['work_schedule']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_name': userName,
      'role': role,
      'partner_id': partnerId,
      'image': image,
      'is_active': isActive,
      'is_active_admin': isActiveAdmin,
      'enforce_work_schedule': enforceWorkSchedule,
      'work_schedule': workSchedule.map(
        (day, ranges) =>
            MapEntry(day, ranges.map((range) => range.toJson()).toList()),
      ),
    };
  }

  static Map<String, List<WorkScheduleRange>> parseWorkSchedule(dynamic value) {
    if (value is! Map) return const {};

    final result = <String, List<WorkScheduleRange>>{};

    for (final entry in value.entries) {
      final day = entry.key.toString();
      final rawRanges = entry.value;
      if (rawRanges is! List) continue;

      final ranges = rawRanges
          .whereType<Map>()
          .map(
            (range) =>
                WorkScheduleRange.fromJson(Map<String, dynamic>.from(range)),
          )
          .where((range) => range.isValid)
          .toList();

      if (ranges.isNotEmpty) {
        result[day] = ranges;
      }
    }

    return result;
  }

  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return defaultValue;
  }
}
