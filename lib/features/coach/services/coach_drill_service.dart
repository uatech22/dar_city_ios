import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/person.dart';

/// Screens #4, #5, #6 — Drills (create, assign, reminders)
class CoachDrillService {
  /// POST /coach/drills
  /// Screen #5 — Add New Drill
  /// Auth: coach
  static Future<Drill> createDrill(CreateDrillPayload payload) async {
    final json = await FeatureApiClient.postJson('/coach/drills', payload.toJson());
    return Drill.fromJson(json);
  }

  /// GET /coach/drills
  /// Screen #6 — Assign Drills (drill picker)
  /// Auth: coach
  static Future<List<Drill>> fetchDrills() async {
    final list = await FeatureApiClient.getJsonList('/coach/drills');
    return list.map((e) => Drill.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /coach/drills/players
  /// Screen #6 — Assign Drills (roster-eligible players only)
  /// Auth: coach
  static Future<List<Person>> fetchDrillRosterPlayers() async {
    final list = await FeatureApiClient.getJsonList('/coach/drills/players');
    return list
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /coach/drills/assign
  /// Screen #6 — Assign Drills
  /// Auth: coach
  static Future<Map<String, dynamic>> assignDrills(AssignDrillsPayload payload) async {
    return FeatureApiClient.postJson('/coach/drills/assign', payload.toJson());
  }

  /// GET /coach/drills/assignments
  /// Assigned Drills list (coach team view)
  static Future<List<CoachDrillAssignment>> fetchAssignments() async {
    final list = await FeatureApiClient.getJsonList('/coach/drills/assignments');
    return list
        .map((e) => CoachDrillAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /coach/drills/{drillId}/reminders
  /// Screen #4 — Send Drill Reminders
  /// Auth: coach
  static Future<List<DrillReminderPlayer>> fetchReminderTargets(String drillId) async {
    final list = await FeatureApiClient.getJsonList(
      '/coach/drills/$drillId/reminders',
    );
    return list
        .map((e) => DrillReminderPlayer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Builds reminders list from existing per-drill endpoints (no dedicated list API).
  static Future<List<DrillReminderOverviewItem>> fetchReminderOverview({
    String? trainingId,
  }) async {
    final drills = sortDrillsNewestFirst(
      filterDrillsBySession(await fetchDrills(), trainingId),
    );
    if (drills.isEmpty) return [];

    final batches = await Future.wait(
      drills.map((drill) async {
        try {
          final players = await fetchReminderTargets(drill.id);
          return players
              .where((p) => p.needsReminder)
              .map(
                (p) => DrillReminderOverviewItem(
                  drillId: drill.id,
                  drillName: drill.name,
                  playerId: p.playerId,
                  playerName: p.playerName,
                  status: p.status,
                ),
              )
              .toList();
        } catch (_) {
          return <DrillReminderOverviewItem>[];
        }
      }),
    );
    return batches.expand((batch) => batch).toList();
  }

  /// POST /coach/drills/{drillId}/reminders
  /// Screen #4 — Send Drill Reminders
  /// Auth: coach
  /// Body: { "message": "...", "player_ids": [1,2,3] }
  static Future<Map<String, dynamic>> sendReminders({
    required String drillId,
    required String message,
    required List<int> playerIds,
  }) async {
    return FeatureApiClient.postJson('/coach/drills/$drillId/reminders', {
      'message': message,
      'player_ids': playerIds,
    });
  }
}
