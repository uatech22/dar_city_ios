import 'package:dar_city_app/navigation/role_navigation.dart';

class Profile {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? appRole;
  final String? roleInTeam;
  final List<String> roles;
  final int? personId;
  final String? passportImageUrl;
  final String? roleName;

  Profile({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.appRole,
    this.roleInTeam,
    this.roles = const [],
    this.personId,
    this.passportImageUrl,
    this.roleName,
  });

  String? get effectiveRole => RoleNavigation.resolveNavigationRoleFromMap(
        toRoleMap(),
      );

  /// Human-readable role for dashboard headers.
  String? get displayRoleLabel {
    if (roleName?.trim().isNotEmpty == true) return roleName!.trim();
    if (roleInTeam?.trim().isNotEmpty == true) return roleInTeam!.trim();
    if (role?.trim().isNotEmpty == true) {
      return role!
          .replaceAll('-', ' ')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return null;
  }

  Map<String, dynamic> toRoleMap({int? personId}) => {
        'app_role': appRole,
        'role': role,
        'role_in_team': roleInTeam,
        'roles': roles,
        'person_id': personId ?? this.personId,
      };

  factory Profile.fromJson(Map<String, dynamic> json) {
    final roles = <String>[];
    final rawRoles = json['roles'];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        if (item is String) {
          roles.add(item);
        } else if (item is Map) {
          for (final key in ['name', 'slug', 'key', 'role']) {
            final value = item[key];
            if (value is String && value.trim().isNotEmpty) {
              roles.add(value);
              break;
            }
          }
        }
      }
    }

    String? parseRoleField(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is Map) {
        for (final key in ['name', 'slug', 'key', 'role']) {
          final nested = value[key];
          if (nested is String && nested.trim().isNotEmpty) return nested.trim();
        }
      }
      return null;
    }

    final personIdRaw = json['person_id'];
    final personId = personIdRaw is int
        ? personIdRaw
        : (personIdRaw is String ? int.tryParse(personIdRaw) : null);

    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : (idRaw is String ? int.tryParse(idRaw) : null);

    return Profile(
      id: id,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'],
      role: parseRoleField(json['role']),
      appRole: json['app_role']?.toString(),
      roleInTeam: json['role_in_team']?.toString(),
      roles: roles,
      personId: personId,
      passportImageUrl: json['passport'],
      roleName: json['role_name']?.toString(),
    );
  }
}
