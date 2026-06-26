/// Regulation quarter length + OT defaults for coach game stats.
abstract final class GameStatsPeriodConfig {
  static const defaultRegulationSeconds = 600;
  static const overtimeSeconds = 300;

  static const regulationPresets = <Duration>[
    Duration(minutes: 10),
    Duration(minutes: 12),
    Duration(minutes: 8),
  ];

  static String formatPeriodLabel(int periodNumber) {
    if (periodNumber <= 4) return 'Q$periodNumber';
    if (periodNumber == 5) return 'OT';
    return 'OT${periodNumber - 4}';
  }

  static String feedFilterLabel(int periodNumber) => formatPeriodLabel(periodNumber);

  /// Feed filter tabs available while live at [currentPeriod] (Q1..current, OT..).
  static List<int> coveredPeriodFilters(int currentPeriod) {
    if (currentPeriod < 1) return const [1];
    return List.generate(currentPeriod, (index) => index + 1);
  }

  static String formatDurationLabel(Duration duration) {
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (m > 0 && s > 0) return '$m:${s.toString().padLeft(2, '0')}';
    if (m > 0) return '$m:00';
    return '0:${s.toString().padLeft(2, '0')}';
  }

  /// Reads coach-picked regulation length from session/match JSON.
  static int parseRegulationSeconds(Map<String, dynamic> json) {
    for (final key in const [
      'quarter_duration_seconds',
      'period_duration_seconds',
      'regulation_period_seconds',
      'q_duration_seconds',
    ]) {
      final parsed = _positiveInt(json[key]);
      if (parsed != null) return parsed;
    }

    for (final key in const [
      'quarter_duration_minutes',
      'period_duration_minutes',
      'q_duration_minutes',
      'quarter_duration',
      'q_duration',
    ]) {
      final minutes = _positiveInt(json[key]);
      if (minutes != null) return minutes * 60;
    }

    final match = json['match'];
    if (match is Map<String, dynamic>) {
      return parseRegulationSeconds(match);
    }
    if (match is Map) {
      return parseRegulationSeconds(Map<String, dynamic>.from(match));
    }

    return defaultRegulationSeconds;
  }

  static int parseOvertimeSeconds(Map<String, dynamic> json) {
    for (final key in const [
      'overtime_duration_seconds',
      'ot_duration_seconds',
    ]) {
      final parsed = _positiveInt(json[key]);
      if (parsed != null) return parsed;
    }

    final match = json['match'];
    if (match is Map<String, dynamic>) {
      return parseOvertimeSeconds(match);
    }
    if (match is Map) {
      return parseOvertimeSeconds(Map<String, dynamic>.from(match));
    }

    return overtimeSeconds;
  }

  static int regulationMinutesFromSeconds(int seconds) => seconds ~/ 60;

  static int? _positiveInt(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }
}
