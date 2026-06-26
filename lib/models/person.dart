import 'package:dar_city_app/features/shared/json_parse.dart';
import 'package:dar_city_app/utils/person_display.dart';

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
  final String? transferStatus;
  final bool? onLoan;
  final bool? isActive;

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
    this.transferStatus,
    this.onLoan,
    this.isActive,
  });

  String get fullName => '$firstName $lastName';

  /// Active squad only — excludes loaned / temporarily sold players.
  bool get isAssignableForDrills {
    if (isActive == false) return false;
    if (onLoan == true) return false;
    final status = (transferStatus ?? '').toLowerCase();
    if (status.contains('loan') ||
        status.contains('sold') ||
        status == 'transferred' ||
        status == 'inactive') {
      return false;
    }
    return true;
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: intFromJson(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      position: parsePersonPositionFromJson(json),
      role: parsePersonRoleFromJson(json),
      nationality: stringFromPersonField(json['nationality']),
      bio: stringFromPersonField(json['bio']),
      jerseyNumber: intFromJsonNullable(json['jersey_number']),
      points: intFromJsonNullable(json['points']),
      rebounds: intFromJsonNullable(json['rebounds']),
      assists: intFromJsonNullable(json['assists']),
      age: intFromJsonNullable(json['age']),
      height: json['height_cm']?.toString(),
      weight: json['weight_kg']?.toString(),
      transferStatus: json['transfer_status'] as String? ??
          json['player_status'] as String? ??
          json['roster_status'] as String?,
      onLoan: _boolFromJson(json['on_loan']) ??
          _boolFromJson(json['is_on_loan']) ??
          _boolFromJson(json['is_loaned']),
      isActive: _boolFromJson(json['is_active']) ??
          _boolFromJson(json['is_available']),
      dob: parsePersonDobFromJson(json),
      image: _resolvePersonImage(
        json['passport_picture'] ?? json['avatar_url'] ?? json['image_url'],
      ),
    );
  }
}

String? _resolvePersonImage(dynamic imagePath) {
  if (imagePath == null) return null;
  final path = imagePath.toString().trim();
  if (path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'http://darcitybasketball.com/storage/$path';
}

bool? _boolFromJson(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
  }
  return null;
}
