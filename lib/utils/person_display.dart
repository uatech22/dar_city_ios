import 'package:dar_city_app/models/person.dart';

/// Parses DOB from API values (ISO, `yyyy-MM-dd HH:mm:ss`, `dd-MM-yyyy`, `dd/MM/yyyy`).
DateTime? parsePersonDateOfBirth(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final isoCandidate = raw.contains(' ') && !raw.contains('T')
      ? raw.replaceFirst(' ', 'T')
      : raw;
  final parsed = DateTime.tryParse(isoCandidate);
  if (parsed != null) return parsed;

  final dmy = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');
  final match = dmy.firstMatch(raw);
  if (match != null) {
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

DateTime? parsePersonDobFromJson(Map<String, dynamic> json) {
  for (final key in ['dob', 'date_of_birth', 'birth_date', 'birthday']) {
    final parsed = parsePersonDateOfBirth(json[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

String? stringFromPersonField(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map) {
    for (final key in ['name', 'label', 'title', 'slug', 'role']) {
      final nested = value[key];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }
  }
  return null;
}

String parsePersonRoleFromJson(Map<String, dynamic> json) {
  for (final key in ['role_in_team', 'role', 'job_title', 'staff_role']) {
    final value = stringFromPersonField(json[key]);
    if (value != null) return value;
  }
  return '';
}

String parsePersonPositionFromJson(Map<String, dynamic> json) {
  return stringFromPersonField(json['position']) ?? '';
}

/// Human-readable role, e.g. `sports-manager` → `Sports Manager`.
String formatRoleLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final normalized = trimmed.toLowerCase().replaceAll('_', '-');
  const known = {
    'coach': 'Coach',
    'coach-role': 'Coach',
    'staff': 'Staff',
    'medic': 'Medic',
    'player': 'Player',
    'prospect': 'Prospect',
    'sports-manager': 'Sports Manager',
    'super-administrator': 'Super Administrator',
    'assistant-coach': 'Assistant Coach',
    'head-coach': 'Head Coach',
  };
  if (known.containsKey(normalized)) {
    return known[normalized]!;
  }

  if (trimmed.contains(' ') && trimmed != trimmed.toLowerCase()) {
    return trimmed;
  }

  return trimmed
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

bool isPlayerTeamRole(String role) {
  final normalized = role.toLowerCase().replaceAll('_', '-').trim();
  return normalized.isEmpty ||
      normalized == 'player' ||
      normalized == 'prospect';
}

bool isGenericStaffRole(String role) {
  final normalized = role.toLowerCase().replaceAll('_', '-').trim();
  return normalized == 'coach' ||
      normalized == 'coach-role' ||
      normalized == 'staff' ||
      normalized == 'medic';
}

extension PersonDisplay on Person {
  String get displayRoleLabel => formatRoleLabel(role);

  String? get formattedDateOfBirth {
    final value = dob;
    if (value == null) return null;
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }

  /// Primary label on team cards and profile subtitle.
  String get displayTeamLabel {
    final roleLabel = displayRoleLabel;
    final pos = position.trim();

    if (isPlayerTeamRole(role)) {
      if (pos.isNotEmpty) return pos;
      if (roleLabel.isNotEmpty && roleLabel.toLowerCase() != 'player') {
        return roleLabel;
      }
      return roleLabel.isNotEmpty ? roleLabel : 'Player';
    }

    if (!isGenericStaffRole(role) && roleLabel.isNotEmpty) return roleLabel;
    if (pos.isNotEmpty) return pos;
    if (roleLabel.isNotEmpty) return roleLabel;
    return 'Staff';
  }

  bool get showRoleInfoItem {
    final roleLabel = displayRoleLabel;
    if (roleLabel.isEmpty) return false;
    if (isPlayerTeamRole(role)) {
      return roleLabel.toLowerCase() != 'player' &&
          roleLabel.toLowerCase() != position.trim().toLowerCase();
    }
    return roleLabel.toLowerCase() != position.trim().toLowerCase();
  }
}
