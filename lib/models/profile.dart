class Profile {
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? passportImageUrl;

  Profile({
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.passportImageUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'],
      role: json['role'],
      // Corrected to match the backend key 'passport'
      passportImageUrl: json['passport'], 
    );
  }
}
