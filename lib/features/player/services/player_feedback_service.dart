import 'package:dar_city_app/features/player/models/player_feedback.dart';
import 'package:dar_city_app/features/player/services/player_dashboard_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/services/team_service.dart';

/// Screen #11 — Provide Player Feedback
class PlayerFeedbackService {
  /// GET /team/coaches (auth) with public fallback
  static Future<List<Person>> fetchCoaches() async {
    try {
      final list = await FeatureApiClient.getJsonList('/team/coaches');
      return list
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        return await TeamService.fetchCoaches();
      } catch (_) {
        return [];
      }
    }
  }

  /// POST /player/feedback
  /// Auth: player
  static Future<PlayerFeedback> submit(PlayerFeedbackPayload payload) async {
    final json = await FeatureApiClient.postJson(
      '/player/feedback',
      payload.toJson(),
    );
    return PlayerFeedback.fromJson(json);
  }

  /// Resolves optional coach_id when not provided explicitly.
  static Future<int?> resolveCoachId() => PlayerDashboardService.resolveCoachId();
}
