import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/services/discipline_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/services/profile_service.dart';

/// Screens #12, #13, #14 — Attendance
class AttendanceService {
  /// GET /coach/attendance/management
  /// Screen #12 — Attendance Analytics
  /// Auth: coach
  /// Query: ?search=name (optional)
  static Future<AttendanceManagementSummary> fetchAnalyticsSummary({
    String? search,
  }) async {
    final query = search != null && search.isNotEmpty ? '?search=$search' : '';
    final json = await FeatureApiClient.getJson(
      '/coach/attendance/management$query',
    );
    return AttendanceManagementSummary.fromJson(json);
  }

  /// POST /coach/attendance/mark-all-present
  /// Screen #12 — bulk action
  /// Auth: coach
  static Future<MarkAllPresentResult> markAllPresent({String? sessionId}) async {
    final json = await FeatureApiClient.postJson('/coach/attendance/mark-all-present', {
      if (sessionId != null) 'session_id': sessionId,
    });
    return MarkAllPresentResult.fromJson(json);
  }

  /// GET /player/attendance/daily
  /// Screen #13 — Daily Attendance & Token
  /// Auth: player
  static Future<DailyAttendanceSummary> fetchDailySummary() async {
    final json = await FeatureApiClient.getJson('/player/attendance/daily');
    return DailyAttendanceSummary.fromJson(json);
  }

  /// Player attendance dashboard — merges profile, discipline, and daily API.
  static Future<PlayerAttendanceDashboard> fetchPlayerDashboard() async {
    final profile = await ProfileService().getProfile();

    final optional = await Future.wait([
      _tryFetch(DisciplineService.fetchPlayerDiscipline),
      _tryFetch(fetchDailySummary),
    ]);

    final discipline = optional[0] as DisciplineSummary?;
    final daily = optional[1] as DailyAttendanceSummary?;

    if (discipline == null && daily == null) {
      throw FeatureApiException(
        503,
        'Could not load attendance. Discipline and daily APIs are unavailable.',
      );
    }

    return PlayerAttendanceDashboard.merge(
      playerName: profile.name,
      discipline: discipline,
      daily: daily,
    );
  }

  static Future<T?> _tryFetch<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  /// POST /player/attendance/check-in
  /// Screen #13 — player check-in
  /// Auth: player
  static Future<CheckInResult> checkIn() async {
    final json = await FeatureApiClient.postJson('/player/attendance/check-in', {});
    return CheckInResult.fromJson(json);
  }

  /// GET /coach/attendance/sessions/{sessionId}
  /// Screen #14 — Take Session Attendance
  /// Auth: coach
  static Future<SessionAttendanceSummary> fetchSessionAttendance(
    String sessionId, {
    String? date,
  }) async {
    final query = date != null ? '?date=$date' : '';
    final json = await FeatureApiClient.getJson(
      '/coach/attendance/sessions/$sessionId$query',
    );
    return SessionAttendanceSummary.fromJson(json);
  }

  /// POST /coach/attendance/sessions/{sessionId}/mark
  /// Screen #14 — save attendance marks
  /// Auth: coach
  static Future<Map<String, dynamic>> markSessionAttendance(
    MarkSessionAttendancePayload payload,
  ) async {
    return FeatureApiClient.postJson(
      '/coach/attendance/sessions/${payload.sessionId}/mark',
      {
        'records': payload.records.map((e) => e.toJson()).toList(),
        if (payload.attendanceDate != null) 'attendance_date': payload.attendanceDate,
      },
    );
  }
}
