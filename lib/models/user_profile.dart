class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? passport;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.passport,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      passport: json['passport'],
    );
  }
}
