import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';

/// Screens #8, #9 — Player drills
class PlayerDrillService {
  /// GET /player/drills/assigned
  /// Screen #8 — View Assigned Drills
  /// Auth: player
  static Future<List<AssignedDrill>> fetchAssignedDrills() async {
    final list = await FeatureApiClient.getJsonList('/player/drills/assigned');
    return list
        .map((e) => AssignedDrill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /player/drills/completion
  /// Screen #9 — Mark Drill Completed (checklist)
  /// Auth: player
  static Future<List<DrillCompletionItem>> fetchCompletionItems() async {
    final list = await FeatureApiClient.getJsonList('/player/drills/completion');
    return list
        .map((e) => DrillCompletionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /player/drills/completion
  /// Screen #9 — Mark Drill Completed
  /// Auth: player
  static Future<Map<String, dynamic>> markComplete(
    MarkDrillCompletePayload payload,
  ) async {
    return FeatureApiClient.patchJson(
      '/player/drills/completion',
      payload.toJson(),
    );
  }
}
