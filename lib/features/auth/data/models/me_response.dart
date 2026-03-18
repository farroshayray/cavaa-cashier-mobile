import 'user_model.dart';

class MeResponse {
  final UserModel user;
  final Map<String, dynamic>? appUpdate;

  MeResponse({
    required this.user,
    this.appUpdate,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw Exception('Invalid /me response: missing user');
    }

    return MeResponse(
      user: UserModel.fromJson(
        Map<String, dynamic>.from(userJson),
      ),
      appUpdate: json['app_update'] is Map
          ? Map<String, dynamic>.from(json['app_update'])
          : null,
    );
  }
}