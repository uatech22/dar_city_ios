class Person {
  final int id;
  final String firstName;
  final String lastName;
  final String position;
  final String role;
  final String? image;
  final String? nationality;
  final DateTime? dob;
  final String? bio;
  final int? jerseyNumber;
  final int? points;
  final int? rebounds;
  final int? assists;
  final int? age;
  final String? height;
  final String? weight;




  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.role,
    this.image,
    this.nationality,
    this.dob,
    this.bio,
    this.jerseyNumber,
    this.points,
    this.rebounds,
    this.assists,
    this.age,
    this.height,
    this.weight,
  });

  String get fullName => '$firstName $lastName';

  factory Person.fromJson(Map<String, dynamic> json) {
    final imagePath = json['passport_picture'];

    return Person(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      position: json['position'].toString(),
      role: json['role_in_team'].toString(),
      nationality: json['nationality'],
      bio: json['bio'],
      jerseyNumber: json['jersey_number'],
      points: json['points'],
      rebounds: json['rebounds'],
      assists: json['assists'],

      height: json['height_cm']?.toString(),
      weight: json['weight_kg']?.toString(),


      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      image: imagePath != null
          ? 'http://darcitybasketball.com/storage/$imagePath'
          : null,

    );
  }
}
