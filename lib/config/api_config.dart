class ApiConfig {
  /// Single source of truth for all API calls (fan app + V2 coach/player features).
  static const String baseUrl = 'https://darcitybasketball.com/api';

  /// Live / in-session screens — chat, live scores, seat holds, roll call.
  static const Duration refreshIntervalFast = Duration(seconds: 50); //5

  /// Lists, dashboards, browse screens — news, drills, schedules, rosters.
  static const Duration refreshIntervalSlow = Duration(seconds: 500); //50

  /// @deprecated Use [refreshIntervalFast] or [refreshIntervalSlow].
  static const Duration refreshInterval = refreshIntervalSlow;
}
