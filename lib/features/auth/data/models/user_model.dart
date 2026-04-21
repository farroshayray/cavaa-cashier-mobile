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
    };
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
