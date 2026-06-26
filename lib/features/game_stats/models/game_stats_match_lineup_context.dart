import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/models/person.dart';

/// Roster + quarter timing for the match lineup step.
class GameStatsMatchLineupContext {
  const GameStatsMatchLineupContext({
    required this.players,
    required this.quarterDurationSeconds,
    required this.overtimeDurationSeconds,
  });

  final List<Person> players;
  final int quarterDurationSeconds;
  final int overtimeDurationSeconds;

  Duration get quarterDuration =>
      Duration(seconds: quarterDurationSeconds);

  static GameStatsMatchLineupContext fromJson(
    Map<String, dynamic> json, {
    List<Person> players = const [],
  }) {
    return GameStatsMatchLineupContext(
      players: players,
      quarterDurationSeconds: GameStatsPeriodConfig.parseRegulationSeconds(json),
      overtimeDurationSeconds: GameStatsPeriodConfig.parseOvertimeSeconds(json),
    );
  }
}
