import 'package:dar_city_app/RootScreenNavigation.dart';
import 'package:dar_city_app/features/coach/coach_root_screen.dart';
import 'package:dar_city_app/features/player/player_root_screen.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/services/profile_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Maps backend user roles to the correct app shell after login / cold start.
class RoleNavigation {
  RoleNavigation._();

  /// Legacy helper — returns first string role field (not used for routing).
  static String? parseRoleFromMap(Map<String, dynamic> user) {
    final appRole = user['app_role'];
    if (appRole is String && appRole.isNotEmpty) return appRole;

    final role = _stringFromRoleValue(user['role']);
    if (role != null && role.isNotEmpty) return role;

    return null;
  }

  /// Best role for navigation — scans app_role, role, role_in_team, roles[].
  static String? resolveNavigationRoleFromMap(Map<String, dynamic> user) {
    final teamRole = _stringFromRoleValue(user['role_in_team']);
    if (teamRole != null && _isCoachTeamRole(_normalizeRoleKey(teamRole))) {
      return teamRole;
    }

    final candidates = _collectRoleCandidates(user);
    if (candidates.isEmpty) return null;

    for (final candidate in candidates) {
      if (_isCoachShellRole(_normalizeRoleKey(candidate))) return candidate;
    }
    for (final candidate in candidates) {
      if (_shellForRole(candidate) == _player) return candidate;
    }
    for (final candidate in candidates) {
      if (_shellForRole(candidate) == _sponsor) return candidate;
    }

    return candidates.first;
  }

  /// Async resolver — if API still says fan but user can hit /coach/*, use coach shell.
  static Future<String?> resolveNavigationRoleForUser(
    Map<String, dynamic> user,
  ) async {
    final role = resolveNavigationRoleFromMap(user);
    if (usesCoachShell(role)) return role ?? 'coach';
    if (_shellForRole(role) == _player) return role;

    final personId = user['person_id'];
    if (personId != null && _shellForRole(role) == _fan) {
      final coachAccess = await _hasCoachApiAccess();
      if (coachAccess) {
        if (kDebugMode) {
          debugPrint(
            'RoleNavigation: /coach/dashboard OK — routing person_id=$personId to coach shell',
          );
        }
        return 'coach';
      }
    }

    return role;
  }

  /// Pull role from common login / register response shapes.
  static String? parseRoleFromResponse(Map<String, dynamic> data) {
    final user = _extractUser(data);
    if (user != null) {
      return resolveNavigationRoleFromMap(user);
    }

    final topLevel = resolveNavigationRoleFromMap(data);
    if (topLevel != null) return topLevel;

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return parseRoleFromResponse(nested);
    }

    return null;
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    if (data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }
    final nested = data['data'];
    if (nested is Map<String, dynamic> && nested['user'] is Map<String, dynamic>) {
      return nested['user'] as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> persistRoleFromResponse(Map<String, dynamic> data) async {
    final user = _extractUser(data);
    if (user != null) {
      final role = await resolveNavigationRoleForUser(user);
      if (kDebugMode) {
        debugPrint(
          'RoleNavigation: login user=${user['email']} '
          'candidates=${_collectRoleCandidates(user)} '
          'role_in_team=${user['role_in_team']} person_id=${user['person_id']} -> $role',
        );
      }
      if (role != null) {
        await SessionManager().saveRole(role);
      }

      final personId = user['person_id'];
      if (personId is int) {
        await SessionManager().savePersonId(personId);
      }

      final userId = user['id'];
      if (userId is int) {
        await SessionManager().saveUserId(userId);
      } else if (userId is String) {
        final parsed = int.tryParse(userId);
        if (parsed != null) await SessionManager().saveUserId(parsed);
      }

      final teamId = user['team_id'];
      if (teamId is int) {
        await SessionManager().saveTeamId(teamId);
      }
      return;
    }

    final role = parseRoleFromResponse(data);
    if (role != null) {
      await SessionManager().saveRole(role);
    }
  }

  static Widget homeForRole(String? role) {
    switch (_shellForRole(role)) {
      case _coach:
        return const CoachRootScreen();
      case _player:
        return const PlayerRootScreen();
      case _fan:
      case _sponsor:
      default:
        return RootScreen();
    }
  }

  /// Refresh role from `/profile` (+ coach API probe when backend sends fan).
  static Future<Widget> resolveAuthenticatedHome() async {
    try {
      final profile = await ProfileService().getProfile();
      if (profile.personId != null) {
        await SessionManager().savePersonId(profile.personId);
      }
      if (profile.id != null) {
        await SessionManager().saveUserId(profile.id);
      }
      final roleMap = profile.toRoleMap(
        personId: profile.personId ?? SessionManager().getPersonId(),
      );
      final role = await resolveNavigationRoleForUser(roleMap);
      if (kDebugMode) {
        debugPrint(
          'RoleNavigation: profile role_in_team=${profile.roleInTeam} '
          'app_role=${profile.appRole} role=${profile.role} roles=${profile.roles} -> $role',
        );
      }
      if (role != null && role.isNotEmpty) {
        await SessionManager().saveRole(role);
        return homeForRole(role);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RoleNavigation: profile fetch failed: $e');
      }
    }

    final savedRole = SessionManager().getRole();
    if (savedRole != null && savedRole.isNotEmpty) {
      return homeForRole(savedRole);
    }

    return RootScreen();
  }

  /// Coach app shell: coach, sports-manager, super-administrator, staff, etc.
  static bool usesCoachShell(String? role) => _shellForRole(role) == _coach;

  static String _shellForRole(String? role) {
    final value = _normalizeRoleKey(role);
    if (_isCoachShellRole(value) || _isCoachTeamRole(value)) return _coach;
    if (value == 'player' || value == 'prospect') return _player;
    if (value == 'sponsor') return _sponsor;
    return _fan;
  }

  static String _normalizeRoleKey(String? role) {
    if (role == null) return '';
    return role
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// From `people.role_in_team` — matches backend coach middleware.
  static bool _isCoachTeamRole(String value) {
    if (value.isEmpty) return false;
    const coachTeamRoles = {'coach', 'staff', 'medic'};
    return coachTeamRoles.contains(value);
  }

  static bool _isCoachShellRole(String value) {
    if (value.isEmpty) return false;

    if (_isCoachTeamRole(value)) return true;

    const exactCoachRoles = {
      'coach',
      'coach-role',
      'sports-manager',
      'super-administrator',
      'super-admin',
      'staff',
      'internal-team',
    };
    if (exactCoachRoles.contains(value)) return true;

    if (value.contains('sports') && value.contains('manager')) return true;
    if (value.contains('super') && value.contains('admin')) return true;

    return value.contains('coach') ||
        value.contains('sports-manager') ||
        value.contains('super-administrator') ||
        value.contains('internal');
  }

  static String? _stringFromRoleValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map) {
      for (final key in ['name', 'slug', 'key', 'role']) {
        final nested = value[key];
        if (nested is String && nested.trim().isNotEmpty) return nested.trim();
      }
    }
    return null;
  }

  static List<String> _collectRoleCandidates(Map<String, dynamic> user) {
    final seen = <String>{};
    final candidates = <String>[];

    void add(dynamic value) {
      final parsed = _stringFromRoleValue(value);
      if (parsed == null || seen.contains(parsed)) return;
      seen.add(parsed);
      candidates.add(parsed);
    }

    add(user['app_role']);
    add(user['role']);
    add(user['role_in_team']);
    add(user['role_name']);
    add(user['primary_role']);

    final roles = user['roles'];
    if (roles is List) {
      for (final item in roles) {
        add(item);
        if (item is Map) {
          add(item['name']);
          add(item['slug']);
          add(item['key']);
          add(item['role']);
        }
      }
    }

    return candidates;
  }

  static Future<bool> _hasCoachApiAccess() async {
    try {
      await FeatureApiClient.getJson('/coach/dashboard');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RoleNavigation: coach dashboard probe failed: $e');
      }
      return false;
    }
  }

  static const _coach = 'coach';
  static const _player = 'player';
  static const _fan = 'fan';
  static const _sponsor = 'sponsor';
}
