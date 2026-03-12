class UserModel {
  final int id;
  final String name;
  final String userName;
  final String role;
  final int? partnerId;
  final String? image;

  UserModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.role,
    required this.partnerId,
    this.image,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      userName: (json['user_name'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      partnerId: json['partner_id'] as int?,
      image: json['image']?.toString(),
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
    };
  }
}