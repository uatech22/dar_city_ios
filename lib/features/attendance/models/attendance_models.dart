import 'package:flutter/material.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/shared/json_parse.dart';

import 'package:dar_city_app/features/discipline/models/discipline_models.dart';

/// Shared attendance status values from API spec.
const attendanceStatuses = [
  'present',
  'late',
  'absent',
  'none',
  'warning',
  'noshow',
  'default',
];

String attendanceStatusLabel(String status) {
  switch (status) {
    case 'present':
      return 'Present';
    case 'late':
      return 'Late';
    case 'absent':
      return 'Absent';
    case 'none':
      return 'Not marked';
    case 'warning':
      return 'Warning';
    case 'noshow':
      return 'No show';
    default:
      return status.replaceAll('_', ' ');
  }
}

Color attendanceStatusColor(String status) {
  switch (status) {
    case 'present':
      return DarColors.greenBright;
    case 'late':
      return DarColors.eliteGold;
    case 'absent':
    case 'noshow':
      return DarColors.accentRed;
    case 'warning':
      return DarColors.eliteCoral;
    default:
      return DarColors.muted;
  }
}

/// Screens #12, #13, #14 — Attendance
class AttendanceManagementSummary {
  const AttendanceManagementSummary({
    required this.squadAttendanceRate,
    required this.tokensEarnedWeekly,
    required this.pendingPenalties,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.roster,
  });

  final String squadAttendanceRate;
  final int tokensEarnedWeekly;
  final int pendingPenalties;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final List<RosterPlayerAttendance> roster;

  factory AttendanceManagementSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceManagementSummary(
      squadAttendanceRate: json['squad_attendance_rate'] as String? ?? '0%',
      tokensEarnedWeekly: intFromJson(json['tokens_earned_weekly']),
      pendingPenalties: intFromJson(json['pending_penalties']),
      presentCount: intFromJson(json['present_count']),
      lateCount: intFromJson(json['late_count']),
      absentCount: intFromJson(json['absent_count']),
      roster: (json['roster'] as List<dynamic>? ?? [])
          .map((e) => RosterPlayerAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parses `"92%"` → `92.0`
  double get ratePercent {
    final digits = squadAttendanceRate.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  int get rosterSize => roster.length;

  int get atRiskCount => roster.where((p) => isAtRiskStatus(p.status)).length;

  Map<String, int> get statusBreakdown {
    final counts = <String, int>{};
    for (final p in roster) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    return counts;
  }

  List<RosterPlayerAttendance> rosterFiltered({
    String? search,
    AttendanceRosterFilter filter = AttendanceRosterFilter.all,
  }) {
    var list = roster;
    if (filter != AttendanceRosterFilter.all) {
      list = list.where((p) => matchesRosterFilter(p.status, filter)).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.details.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  static bool isAtRiskStatus(String status) => _isAtRisk(status);

  static bool matchesRosterFilter(String status, AttendanceRosterFilter filter) {
    switch (filter) {
      case AttendanceRosterFilter.all:
        return true;
      case AttendanceRosterFilter.present:
        return status == 'present';
      case AttendanceRosterFilter.late:
        return status == 'late';
      case AttendanceRosterFilter.absent:
        return status == 'absent' || status == 'noshow';
      case AttendanceRosterFilter.atRisk:
        return isAtRiskStatus(status);
    }
  }

  static bool _isAtRisk(String status) =>
      status == 'warning' || status == 'noshow' || status == 'absent';
}

enum AttendanceRosterFilter {
  all,
  present,
  late,
  absent,
  atRisk,
}

extension AttendanceRosterFilterLabel on AttendanceRosterFilter {
  String get label {
    switch (this) {
      case AttendanceRosterFilter.all:
        return 'All';
      case AttendanceRosterFilter.present:
        return 'Present';
      case AttendanceRosterFilter.late:
        return 'Late';
      case AttendanceRosterFilter.absent:
        return 'Absent';
      case AttendanceRosterFilter.atRisk:
        return 'At risk';
    }
  }
}

class RosterPlayerAttendance {
  const RosterPlayerAttendance({
    required this.playerId,
    required this.name,
    required this.details,
    required this.status,
    this.avatarUrl,
    this.penalty,
  });

  final int playerId;
  final String name;
  final String details;
  final String status;
  final String? avatarUrl;
  final SalaryPenaltyDetail? penalty;

  factory RosterPlayerAttendance.fromJson(Map<String, dynamic> json) {
    return RosterPlayerAttendance(
      playerId: intFromJson(json['player_id']),
      name: json['name'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'none',
      avatarUrl: json['avatar_url'] as String?,
      penalty: SalaryPenaltyDetail.fromJsonNullable(json['penalty']),
    );
  }
}

class DailyAttendanceSummary {
  const DailyAttendanceSummary({
    required this.dateLabel,
    required this.playerName,
    required this.attendanceStatus,
    required this.tokenBalance,
    required this.penaltyCount,
    required this.streakDays,
    this.upcomingDrill,
    this.coachNote,
  });

  final String dateLabel;
  final String playerName;
  final String attendanceStatus;
  final int tokenBalance;
  final int penaltyCount;
  final int streakDays;
  final String? upcomingDrill;
  final String? coachNote;

  bool get isCheckedIn =>
      attendanceStatus == 'present' || attendanceStatus == 'late';

  factory DailyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceSummary(
      dateLabel: json['date_label']?.toString() ?? 'Today',
      playerName: json['player_name']?.toString() ?? 'Player',
      attendanceStatus: json['attendance_status']?.toString() ?? 'none',
      tokenBalance: parseTokenBalance(json),
      penaltyCount: intFromJson(json['penalty_count'] ?? 0),
      streakDays: intFromJson(json['streak_days'] ?? 0),
      upcomingDrill: json['upcoming_drill'] as String?,
      coachNote: json['coach_note'] as String?,
    );
  }
}

/// Player attendance view built from live APIs (daily + discipline + profile).
class PlayerAttendanceDashboard {
  const PlayerAttendanceDashboard({
    required this.playerName,
    required this.dateLabel,
    required this.attendanceStatus,
    required this.tokenBalance,
    required this.penaltyCount,
    required this.streakDays,
    required this.recentHistory,
    this.salaryImpactLabel,
    this.salaryImpactValue,
    this.upcomingDrill,
    this.coachNote,
    this.hasDisciplineApi = false,
    this.hasDailyApi = false,
  });

  final String playerName;
  final String dateLabel;
  final String attendanceStatus;
  final int tokenBalance;
  final int penaltyCount;
  final int streakDays;
  final List<DisciplineHistoryItem> recentHistory;
  final String? salaryImpactLabel;
  final String? salaryImpactValue;
  final String? upcomingDrill;
  final String? coachNote;
  final bool hasDisciplineApi;
  final bool hasDailyApi;

  bool get isMarked =>
      attendanceStatus != 'none' && attendanceStatus != 'default';

  static PlayerAttendanceDashboard merge({
    required String playerName,
    DisciplineSummary? discipline,
    DailyAttendanceSummary? daily,
  }) {
    final penalties = discipline?.history.where((h) => h.isPenalty).length ??
        daily?.penaltyCount ??
        0;

    return PlayerAttendanceDashboard(
      playerName: daily?.playerName ?? playerName,
      dateLabel: daily?.dateLabel ?? _todayLabel(),
      attendanceStatus: daily?.attendanceStatus ?? 'none',
      tokenBalance: discipline?.tokenBalance ?? daily?.tokenBalance ?? 0,
      penaltyCount: penalties,
      streakDays: daily?.streakDays ?? 0,
      recentHistory: discipline?.history.take(8).toList() ?? const [],
      salaryImpactLabel: discipline?.salaryImpactLabel,
      salaryImpactValue: discipline?.salaryImpactValue,
      upcomingDrill: daily?.upcomingDrill,
      coachNote: daily?.coachNote,
      hasDisciplineApi: discipline != null,
      hasDailyApi: daily != null,
    );
  }

  static String _todayLabel() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1].toUpperCase()}, '
        '${months[now.month - 1].toUpperCase()} ${now.day}';
  }
}

class CheckInResult {
  const CheckInResult({
    required this.message,
    required this.attendanceStatus,
    this.tokenAwarded,
    this.tokenBalance,
    this.streakDays,
  });

  final String message;
  final String attendanceStatus;
  final int? tokenAwarded;
  final int? tokenBalance;
  final int? streakDays;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      message: json['message'] as String? ?? 'Check-in recorded',
      attendanceStatus: json['attendance_status'] as String? ?? 'present',
      tokenAwarded: json['token_awarded'] as int?,
      tokenBalance: json['token_balance'] as int?,
      streakDays: json['streak_days'] as int?,
    );
  }
}

class SessionAttendanceSummary {
  const SessionAttendanceSummary({
    required this.sessionId,
    required this.dateLabel,
    required this.sessionTitle,
    required this.presentRate,
    required this.players,
  });

  final String sessionId;
  final String dateLabel;
  final String sessionTitle;
  final String presentRate;
  final List<SessionPlayerAttendance> players;

  factory SessionAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return SessionAttendanceSummary(
      sessionId: uuidFromJson(json['session_id']),
      dateLabel: json['date_label'] as String,
      sessionTitle: json['session_title'] as String,
      presentRate: json['present_rate'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => SessionPlayerAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parses `"92%"` → `92.0`
  double get ratePercent {
    final digits = presentRate.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  int get rosterSize => players.length;

  int get presentCount => players.where((p) => p.status == 'present').length;

  int get lateCount => players.where((p) => p.status == 'late').length;

  int get absentCount =>
      players.where((p) => p.status == 'absent' || p.status == 'noshow').length;

  int get unmarkedCount => players.where((p) => p.status == 'none').length;

  int get atRiskCount =>
      players.where((p) => AttendanceManagementSummary.isAtRiskStatus(p.status)).length;

  Map<String, int> get statusBreakdown {
    final counts = <String, int>{};
    for (final p in players) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    return counts;
  }

  List<SessionPlayerAttendance> playersFiltered({
    String? search,
    AttendanceRosterFilter filter = AttendanceRosterFilter.all,
  }) {
    var list = players;
    if (filter != AttendanceRosterFilter.all) {
      list = list
          .where((p) => AttendanceManagementSummary.matchesRosterFilter(p.status, filter))
          .toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.details.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }
}

class SessionPlayerAttendance {
  const SessionPlayerAttendance({
    required this.playerId,
    required this.name,
    required this.details,
    required this.status,
    this.timeIn,
    this.penalty,
  });

  final int playerId;
  final String name;
  final String details;
  final String status;
  /// Arrival / mark time from API — `time_in`, `check_in_time`, or `arrival_time`.
  final String? timeIn;
  final SalaryPenaltyDetail? penalty;

  factory SessionPlayerAttendance.fromJson(Map<String, dynamic> json) {
    return SessionPlayerAttendance(
      playerId: intFromJson(json['player_id']),
      name: json['name'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'none',
      timeIn: json['time_in'] as String? ??
          json['check_in_time'] as String? ??
          json['arrival_time'] as String?,
      penalty: SalaryPenaltyDetail.fromJsonNullable(json['penalty']),
    );
  }
}

/// Auto/manual salary penalty from `salary_penalties` (nested under `penalty` on roster).
class SalaryPenaltyDetail {
  const SalaryPenaltyDetail({
    required this.tokens,
    required this.totalAmount,
    required this.currency,
    this.penaltyId,
    this.status,
  });

  final int tokens;
  final int totalAmount;
  final String currency;
  final String? penaltyId;
  final String? status;

  static SalaryPenaltyDetail? fromJsonNullable(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return SalaryPenaltyDetail.fromJson(json);
  }

  factory SalaryPenaltyDetail.fromJson(Map<String, dynamic> json) {
    return SalaryPenaltyDetail(
      tokens: intFromJson(json['tokens']),
      totalAmount: intFromJson(json['total_amount']),
      currency: json['currency'] as String? ?? 'TZS',
      penaltyId: json['penalty_id']?.toString(),
      status: json['status'] as String?,
    );
  }

  String get formattedAmount => formatPenaltyMoney(totalAmount, currency);
}

String formatPenaltyMoney(int amount, [String currency = 'TZS']) {
  final formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '$currency $formatted';
}

class MarkSessionAttendancePayload {
  const MarkSessionAttendancePayload({
    required this.sessionId,
    required this.records,
    this.attendanceDate,
  });

  final String sessionId;
  final List<AttendanceRecord> records;
  /// ISO date `YYYY-MM-DD` for multi-day sessions.
  final String? attendanceDate;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.playerId,
    required this.status,
    this.timeIn,
  });

  final int playerId;
  final String status;
  /// `HH:mm` (24h) — stored in `training_attendances.time_in`
  final String? timeIn;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'status': status,
        if (timeIn != null) 'time_in': timeIn,
      };
}

/// Parse API time string → [TimeOfDay] (`09:30`, `09:30:00`, `9:30 AM`).
TimeOfDay? parseAttendanceTimeIn(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final amPm = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$', caseSensitive: false);
  final match = amPm.firstMatch(raw);
  if (match != null) {
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  return null;
}

/// Format for POST `records[].time_in`
String formatAttendanceTimeIn(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

bool attendanceStatusNeedsTime(String status) {
  return status == 'present' || status == 'late' || status == 'absent';
}

String attendanceTimeFieldLabel(String status) {
  switch (status) {
    case 'present':
      return 'Arrival time';
    case 'late':
      return 'Arrived at';
    case 'absent':
      return 'Marked at';
    default:
      return 'Time';
  }
}

class MarkAllPresentResult {
  const MarkAllPresentResult({
    required this.message,
    this.playersUpdated,
  });

  final String message;
  final int? playersUpdated;

  factory MarkAllPresentResult.fromJson(Map<String, dynamic> json) {
    return MarkAllPresentResult(
      message: json['message'] as String? ?? 'All players marked present',
      playersUpdated: json['players_updated'] as int?,
    );
  }
}
