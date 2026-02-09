import 'user_model.dart';

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // sesuaikan dengan response API kamu
    final token = (json['token'] ?? '') as String;
    final userJson = (json['user'] ?? {}) as Map<String, dynamic>;
    return LoginResponse(
      token: token,
      user: UserModel.fromJson(userJson),
    );
  }
}
