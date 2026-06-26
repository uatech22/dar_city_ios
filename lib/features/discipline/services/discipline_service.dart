import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';

/// Screens #15, #16, #17 — Discipline
class DisciplineService {
  /// GET /player/discipline
  static Future<DisciplineSummary> fetchPlayerDiscipline({String? filter}) async {
    final query = filter != null ? '?filter=$filter' : '';
    final json = await FeatureApiClient.getJson('/player/discipline$query');
    return DisciplineSummary.fromJson(json);
  }

  /// POST /coach/discipline/penalties
  static Future<IssuePenaltyResult> issuePenalty(IssuePenaltyPayload payload) async {
    final json = await FeatureApiClient.postJson(
      '/coach/discipline/penalties',
      payload.toJson(),
    );
    return IssuePenaltyResult.fromJson(json);
  }

  /// GET /player/alerts — excludes coach/system log entries.
  static Future<List<PerformanceAlert>> fetchPlayerAlerts() async {
    final list = await FeatureApiClient.getJsonList('/player/alerts');
    return list
        .map((e) => PerformanceAlert.fromJson(e as Map<String, dynamic>))
        .where((a) => a.isPlayerFacing)
        .toList();
  }

  /// GET /coach/alerts
  static Future<List<PerformanceAlert>> fetchCoachAlerts() async {
    final list = await FeatureApiClient.getJsonList('/coach/alerts');
    return list
        .map((e) => PerformanceAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
