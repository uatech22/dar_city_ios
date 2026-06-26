import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';

/// Screen #7 — Manage Training Session
class CoachTrainingSessionService {
  /// GET /coach/training-sessions?status=upcoming|past
  /// Auth: coach
  static Future<List<TrainingSession>> fetchSessions({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final list = await FeatureApiClient.getJsonList(
      '/coach/training-sessions$query',
    );
    return list
        .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /coach/training-sessions
  /// Auth: coach
  static Future<TrainingSession> createSession(
    CreateTrainingSessionPayload payload,
  ) async {
    final json = await FeatureApiClient.postJson(
      '/coach/training-sessions',
      payload.toJson(),
    );
    return TrainingSession.fromJson(json);
  }

  /// PUT /coach/training-sessions/{sessionId}
  /// Auth: coach
  static Future<TrainingSession> updateSession(
    String sessionId,
    CreateTrainingSessionPayload payload,
  ) async {
    final json = await FeatureApiClient.putJson(
      '/coach/training-sessions/$sessionId',
      payload.toJson(),
    );
    return TrainingSession.fromJson(json);
  }
}
