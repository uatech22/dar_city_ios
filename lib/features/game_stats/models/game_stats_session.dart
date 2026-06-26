import 'package:dar_city_app/features/game_stats/models/game_stats_api_session.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';

/// Session passed from lineup → live stats console.
class GameStatsSession {
  const GameStatsSession({
    required this.match,
    required this.startingFive,
    this.roster,
    this.captainPlayerId,
    this.apiSessionId,
    this.apiSnapshot,
    this.quarterDurationSeconds = GameStatsPeriodConfig.defaultRegulationSeconds,
    this.overtimeDurationSeconds = GameStatsPeriodConfig.overtimeSeconds,
  });

  final Game match;
  final List<Person> startingFive;

  /// Match-day squad (5–12) — who dressed for this game. NOT full club roster.
  final List<Person>? roster;

  /// Player id of the on-court captain (must be one of [startingFive]).
  final int? captainPlayerId;

  /// Backend session id — set after `POST /coach/game-stats/sessions`.
  final int? apiSessionId;

  /// Initial server snapshot from create/resume (avoids extra GET on console open).
  final GameStatsApiSession? apiSnapshot;

  /// Regulation quarter length in seconds (Q1–Q4). OT is always 5:00.
  final int quarterDurationSeconds;

  /// Overtime period length in seconds (default 300).
  final int overtimeDurationSeconds;

  static const minMatchLineup = 5;
  static const maxMatchLineup = 12;
  static const requiredStarters = 5;

  bool get isRemote => apiSessionId != null;

  factory GameStatsSession.fromApi(GameStatsApiSession api) {
    final matchLineup = api.mergedMatchLineup;
    return GameStatsSession(
      match: api.match,
      startingFive: List<Person>.from(api.onCourt),
      roster: matchLineup,
      apiSessionId: api.id,
      apiSnapshot: api,
      quarterDurationSeconds: api.regulationPeriodSeconds,
      overtimeDurationSeconds: api.overtimeDurationSeconds,
    );
  }
}
