import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_snapshot.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_report.dart';
import 'package:dar_city_app/features/game_stats/models/live_stat_event.dart';
import 'package:dar_city_app/features/shared/json_parse.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/utils/team_name_short.dart';

/// Server session snapshot from `/coach/game-stats/sessions/*`.
class GameStatsApiSession {
  const GameStatsApiSession({
    required this.id,
    required this.matchId,
    required this.status,
    required this.match,
    required this.teamScore,
    required this.period,
    required this.periodLabel,
    required this.clockRemainingSeconds,
    required this.clockLabel,
    required this.clockRunning,
    required this.onCourt,
    required this.bench,
    required this.roster,
    required this.feed,
    required this.playerStatTotals,
    required this.canUndo,
    required this.regulationPeriodSeconds,
    required this.overtimeDurationSeconds,
  });

  final int id;
  final int matchId;
  final String status;
  final Game match;
  final int teamScore;
  final int period;
  final String periodLabel;
  final int clockRemainingSeconds;
  final String clockLabel;
  final bool clockRunning;
  final List<Person> onCourt;
  final List<Person> bench;
  final List<Person> roster;
  final List<LiveStatEvent> feed;
  final Map<int, Map<String, int>> playerStatTotals;
  final bool canUndo;
  final int regulationPeriodSeconds;
  final int overtimeDurationSeconds;

  /// Full match-day lineup (5–12): `match_lineup` + on-court + bench, de-duplicated.
  List<Person> get mergedMatchLineup {
    final seen = <int>{};
    final merged = <Person>[];
    for (final player in [...roster, ...onCourt, ...bench]) {
      if (seen.add(player.id)) merged.add(player);
    }
    return merged;
  }

  factory GameStatsApiSession.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'];
  final match = matchJson is Map<String, dynamic>
      ? Game.fromJson(matchJson)
      : Game(
          id: intFromJson(json['match_id']),
          date: 'TBD',
          time: 'TBD',
          venue: 'TBD',
          homeTeam: 'TBD',
          awayTeam: 'TBD',
          homeTeamShort: 'DC',
          awayTeamShort: 'TBD',
          homeTeamLogo: '',
          awayTeamLogo: '',
        );

    var onCourt = _people(json['on_court']);
    var roster = _people(json['match_lineup'] ?? json['roster']);
    var bench = _people(json['bench']);

    final tableRows = json['match_lineups'] ?? json['match_lineup_players'];
    if (tableRows is List && tableRows.isNotEmpty) {
      final parsed = GameStatsMatchLineupSnapshot.fromRows(tableRows);
      if (parsed.lineup.isNotEmpty) {
        roster = parsed.lineup;
        if (parsed.onCourt.isNotEmpty) {
          onCourt = parsed.onCourt;
        }
        bench = parsed.lineup
            .where((p) => !onCourt.any((o) => o.id == p.id))
            .toList();
      }
    }

    final regulationSeconds = GameStatsPeriodConfig.parseRegulationSeconds(json);
    final overtimeSeconds = GameStatsPeriodConfig.parseOvertimeSeconds(json);
    final periodNum = _intOr(json['period'], fallback: 1);

    return GameStatsApiSession(
      id: intFromJson(json['id']),
      matchId: intFromJson(json['match_id']),
      status: json['status']?.toString() ?? 'live',
      match: match,
      teamScore: _intOr(json['team_score']),
      period: periodNum,
      periodLabel: json['period_label']?.toString() ??
          GameStatsPeriodConfig.formatPeriodLabel(periodNum),
      clockRemainingSeconds: _intOr(
        json['clock_remaining_seconds'],
        fallback: regulationSeconds,
      ),
      clockLabel: json['clock_label']?.toString() ??
          GameStatsPeriodConfig.formatDurationLabel(
            Duration(seconds: regulationSeconds),
          ),
      clockRunning: json['clock_running'] == true,
      onCourt: onCourt,
      bench: bench,
      roster: roster,
      feed: _feed(json['feed']),
      playerStatTotals: _statTotals(json['player_stat_totals']),
      canUndo: json['can_undo'] != false,
      regulationPeriodSeconds: regulationSeconds,
      overtimeDurationSeconds: overtimeSeconds,
    );
  }

  static List<Person> _people(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Person.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<LiveStatEvent> _feed(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => _feedEvent(Map<String, dynamic>.from(e)))
        .toList();
  }

  static LiveStatEvent _feedEvent(Map<String, dynamic> json) {
    return LiveStatEvent(
      stat: json['stat']?.toString() ?? '',
      jersey: _intOr(json['jersey_number']),
      name: json['player_name']?.toString() ?? '',
      period: _intOr(json['period'], fallback: 1),
      periodLabel: json['period_label']?.toString() ??
          GameStatsPeriodConfig.formatPeriodLabel(_intOr(json['period'], fallback: 1)),
      clockLabel: json['clock_label']?.toString() ?? '10:00',
      count: intFromJsonNullable(json['count']),
      isMiss: json['is_miss'] == true,
    );
  }

  static Map<int, Map<String, int>> _statTotals(dynamic raw) {
    if (raw is! Map) return {};
    final out = <int, Map<String, int>>{};
    raw.forEach((key, value) {
      final playerId = int.tryParse(key.toString());
      if (playerId == null || value is! Map) return;
      final stats = <String, int>{};
      value.forEach((statKey, statVal) {
        stats[statKey.toString()] = _intOr(statVal);
      });
      out[playerId] = stats;
    });
    return out;
  }

  Duration get clockRemaining => Duration(seconds: clockRemainingSeconds);

  static String actionFor(LiveStatKind kind, {required bool missed}) {
    return switch (kind) {
      LiveStatKind.score2 => missed ? 'score_2_miss' : 'score_2_made',
      LiveStatKind.score3 => missed ? 'score_3_miss' : 'score_3_made',
      LiveStatKind.score1 => missed ? 'score_1_miss' : 'score_1_made',
      LiveStatKind.defReb => 'def_reb',
      LiveStatKind.offReb => 'off_reb',
      LiveStatKind.turnover => 'turnover',
      LiveStatKind.steal => 'steal',
      LiveStatKind.assist => 'assist',
      LiveStatKind.block => 'block',
      LiveStatKind.foul => 'foul',
      LiveStatKind.sub => 'substitution',
    };
  }
}

class GameStatsActiveSessionRef {
  const GameStatsActiveSessionRef({
    required this.sessionId,
    required this.matchId,
    required this.status,
  });

  final int sessionId;
  final int matchId;
  final String status;

  factory GameStatsActiveSessionRef.fromJson(Map<String, dynamic> json) {
    return GameStatsActiveSessionRef(
      sessionId: intFromJson(json['session_id']),
      matchId: intFromJson(json['match_id']),
      status: json['status']?.toString() ?? 'live',
    );
  }
}

GameStatsGameReport parseGameStatsReport(Map<String, dynamic> json, Game match) {
  final totalsJson = json['team_totals'] as Map<String, dynamic>? ?? {};
  final teamTotals = GameStatsTeamTotals(
    points: _intOr(totalsJson['points'] ?? json['team_score']),
    fgMade: _intOr(totalsJson['fg_made']),
    fgAtt: _intOr(totalsJson['fg_att']),
    ftMade: _intOr(totalsJson['ft_made']),
    ftAtt: _intOr(totalsJson['ft_att']),
    rebounds: _intOr(totalsJson['rebounds']),
    assists: _intOr(totalsJson['assists']),
    steals: _intOr(totalsJson['steals']),
    blocks: _intOr(totalsJson['blocks']),
    turnovers: _intOr(totalsJson['turnovers']),
    fouls: _intOr(totalsJson['fouls']),
  );

  final playersRaw = json['players'];
  final rows = <GameStatsPlayerReportRow>[];
  if (playersRaw is List) {
    for (final item in playersRaw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final playerJson = map['player'];
      if (playerJson is! Map) continue;
      rows.add(
        GameStatsPlayerReportRow(
          player: Person.fromJson(Map<String, dynamic>.from(playerJson)),
          points: _intOr(map['points']),
          fgMade: _intOr(map['fg_made']),
          fgAtt: _intOr(map['fg_att']),
          ftMade: _intOr(map['ft_made']),
          ftAtt: _intOr(map['ft_att']),
          defReb: _intOr(map['def_reb']),
          offReb: _intOr(map['off_reb']),
          assists: _intOr(map['assists']),
          steals: _intOr(map['steals']),
          blocks: _intOr(map['blocks']),
          turnovers: _intOr(map['turnovers']),
          fouls: _intOr(map['fouls']),
          onCourt: map['on_court'] == true,
        ),
      );
    }
  }

  final opponent = json['opponent_label']?.toString();
  final opponentLabel = opponent != null && opponent.isNotEmpty
      ? opponent
      : GameStatsLiveControllerOpponent.opponentShortLabel(match);

  return GameStatsGameReport(
    match: match,
    teamScore: _intOr(json['team_score']),
    period: _intOr(json['period'], fallback: 1),
    periodLabel: json['period_label']?.toString() ?? 'Q1',
    clockLabel: json['clock_label']?.toString() ?? '10:00',
    clockRunning: json['clock_running'] == true,
    opponentLabel: opponentLabel,
    teamTotals: teamTotals,
    players: rows,
  );
}

/// Opponent label helper without importing the full controller.
abstract final class GameStatsLiveControllerOpponent {
  static String opponentShortLabel(Game match) {
    final home = match.homeTeam.toLowerCase();
    if (home.contains('dar city') || home.contains('darcity')) {
      return match.awayTeamShort.isNotEmpty
          ? match.awayTeamShort
          : shortTeamName(match.awayTeam);
    }
    return match.homeTeamShort.isNotEmpty
        ? match.homeTeamShort
        : shortTeamName(match.homeTeam);
  }
}

int _intOr(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  try {
    return intFromJson(value);
  } catch (_) {
    return fallback;
  }
}
