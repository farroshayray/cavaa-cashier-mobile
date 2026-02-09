class LoginRequest {
  final String userName;
  final String password;

  LoginRequest({
    required this.userName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'user_name': userName, // ⚠️ HARUS user_name
        'password': password,
      };
}
