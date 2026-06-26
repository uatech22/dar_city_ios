import 'package:dar_city_app/features/coach/models/coach_dashboard.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';

/// Screen #1 — Coach Training Dashboard
class CoachDashboardService {
  /// GET /coach/dashboard
  /// Auth: coach (Internal Team)
  static Future<CoachDashboard> fetchDashboard() async {
    final json = await FeatureApiClient.getJson('/coach/dashboard');
    return CoachDashboard.fromJson(json);
  }
}
