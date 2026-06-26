import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/services/attendance_service.dart';
import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/services/discipline_service.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/player/services/player_chat_service.dart';
import 'package:dar_city_app/features/player/services/player_drill_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/profile.dart';
import 'package:dar_city_app/services/profile_service.dart';
import 'package:dar_city_app/services/team_service.dart';

/// Aggregated player home dashboard — all sections from live API.
class PlayerDashboardData {
  const PlayerDashboardData({
    required this.profile,
    required this.allDrills,
    this.discipline,
    this.attendance,
    this.allAlerts = const [],
    this.allAnnouncements = const [],
  });

  final Profile profile;
  final List<AssignedDrill> allDrills;
  final DisciplineSummary? discipline;
  final DailyAttendanceSummary? attendance;
  final List<PerformanceAlert> allAlerts;
  final List<Announcement> allAnnouncements;

  int get tokenBalance =>
      discipline?.tokenBalance ?? attendance?.tokenBalance ?? 0;

  String get salaryImpactValue =>
      discipline?.salaryImpactValue ?? attendance?.penaltyCount.toString() ?? '—';

  String get salaryImpactLabel =>
      discipline?.salaryImpactLabel ?? 'ACTIVE PENALTIES';

  String get attendanceStatus =>
      attendance?.attendanceStatus ?? 'none';

  String get dateLabel => attendance?.dateLabel ?? 'Today';

  int get streakDays => attendance?.streakDays ?? 0;

  String? get upcomingDrill => attendance?.upcomingDrill;
}

/// Player home dashboard aggregates.
class PlayerDashboardService {
  static Future<PlayerDashboardData> fetchDashboard() async {
    final profile = await ProfileService().getProfile();
    final drills = await PlayerDrillService.fetchAssignedDrills();

    final optional = await Future.wait([
      _tryFetch(DisciplineService.fetchPlayerDiscipline),
      _tryFetch(AttendanceService.fetchDailySummary),
      _tryFetch(DisciplineService.fetchPlayerAlerts),
      _tryFetch(fetchAnnouncements),
    ]);

    return PlayerDashboardData(
      profile: profile,
      allDrills: drills,
      discipline: optional[0] as DisciplineSummary?,
      attendance: optional[1] as DailyAttendanceSummary?,
      allAlerts: optional[2] as List<PerformanceAlert>? ?? const [],
      allAnnouncements:
          optional[3] as List<Announcement>? ?? const [],
    );
  }

  static Future<PlayerDrillSummary> fetchDrillSummary() async {
    final drills = await PlayerDrillService.fetchAssignedDrills();
    return PlayerDrillSummary.fromDrills(drills);
  }

  /// GET /player/announcements
  static Future<List<Announcement>> fetchAnnouncements() async {
    final list = await FeatureApiClient.getJsonList('/player/announcements');
    return list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Optional coach `people.id` for feedback — team coaches first, then chat history.
  static Future<int?> resolveCoachId() async {
    try {
      final coaches = await TeamService.fetchCoaches();
      if (coaches.isNotEmpty) return coaches.first.id;
    } catch (_) {}

    try {
      final conversations = await PlayerChatService.fetchConversations();
      for (final conversation in conversations) {
        if (conversation.contactType == 'staff') {
          return conversation.otherUserId;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<T?> _tryFetch<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }
}
