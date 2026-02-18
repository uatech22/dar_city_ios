import 'package:dar_city_app/models/user.dart';

class LoginResponse {
  final bool success;
  final String token;
  final User user;

  LoginResponse({
    required this.success,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}
