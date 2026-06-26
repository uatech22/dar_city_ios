import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_report.dart';
import 'package:dar_city_app/features/game_stats/models/live_stat_event.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';

/// Builds per-quarter / per-OT box score lines from the live play-by-play feed.
abstract final class GameStatsPeriodReportBuilder {
  static GameStatsGameReport build({
    required int forPeriod,
    required List<LiveStatEvent> feed,
    required List<Person> roster,
    required Game match,
    required String opponentLabel,
    required bool Function(Person player) isOnCourt,
    String Function(Person player)? shortName,
  }) {
    final tallies = <int, _PlayerTally>{};

    for (final event in feed) {
      if (event.period != forPeriod) continue;
      final player = _matchPlayer(event, roster, shortName);
      if (player == null) continue;
      tallies.putIfAbsent(player.id, () => _PlayerTally()).apply(event);
    }

    final rows = <GameStatsPlayerReportRow>[];
    for (final player in roster) {
      final tally = tallies[player.id];
      if (tally == null || !tally.hasStats) continue;
      rows.add(tally.toRow(player, onCourt: isOnCourt(player)));
    }

    rows.sort((a, b) {
      final byPts = b.points.compareTo(a.points);
      if (byPts != 0) return byPts;
      return a.player.fullName.compareTo(b.player.fullName);
    });

    var teamPoints = 0;
    var fgMade = 0;
    var fgAtt = 0;
    var ftMade = 0;
    var ftAtt = 0;
    var rebounds = 0;
    var assists = 0;
    var steals = 0;
    var blocks = 0;
    var turnovers = 0;
    var fouls = 0;

    for (final row in rows) {
      teamPoints += row.points;
      fgMade += row.fgMade;
      fgAtt += row.fgAtt;
      ftMade += row.ftMade;
      ftAtt += row.ftAtt;
      rebounds += row.rebounds;
      assists += row.assists;
      steals += row.steals;
      blocks += row.blocks;
      turnovers += row.turnovers;
      fouls += row.fouls;
    }

    return GameStatsGameReport(
      match: match,
      teamScore: teamPoints,
      period: forPeriod,
      periodLabel: GameStatsPeriodConfig.feedFilterLabel(forPeriod),
      clockLabel: '—',
      clockRunning: false,
      opponentLabel: opponentLabel,
      teamTotals: GameStatsTeamTotals(
        points: teamPoints,
        fgMade: fgMade,
        fgAtt: fgAtt,
        ftMade: ftMade,
        ftAtt: ftAtt,
        rebounds: rebounds,
        assists: assists,
        steals: steals,
        blocks: blocks,
        turnovers: turnovers,
        fouls: fouls,
      ),
      players: rows,
    );
  }

  static Person? _matchPlayer(
    LiveStatEvent event,
    List<Person> roster,
    String Function(Person player)? shortName,
  ) {
    if (event.jersey > 0) {
      for (final player in roster) {
        if (player.jerseyNumber == event.jersey) return player;
      }
    }

    final eventName = event.name.trim().toLowerCase();
    if (eventName.isEmpty) return null;

    for (final player in roster) {
      final short = shortName?.call(player) ?? player.fullName;
      if (short.toLowerCase() == eventName) return player;
      if (player.fullName.toLowerCase() == eventName) return player;
    }
    return null;
  }
}

final class _PlayerTally {
  int twoMade = 0;
  int twoMiss = 0;
  int threeMade = 0;
  int threeMiss = 0;
  int ftMade = 0;
  int ftMiss = 0;
  int defReb = 0;
  int offReb = 0;
  int assists = 0;
  int steals = 0;
  int blocks = 0;
  int turnovers = 0;
  int fouls = 0;

  bool get hasStats =>
      twoMade > 0 ||
      twoMiss > 0 ||
      threeMade > 0 ||
      threeMiss > 0 ||
      ftMade > 0 ||
      ftMiss > 0 ||
      defReb > 0 ||
      offReb > 0 ||
      assists > 0 ||
      steals > 0 ||
      blocks > 0 ||
      turnovers > 0 ||
      fouls > 0;

  int get points => twoMade * 2 + threeMade * 3 + ftMade;

  void apply(LiveStatEvent event) {
    switch (_normalizeStat(event.stat)) {
      case _FeedStat.twoMade:
        twoMade++;
      case _FeedStat.twoMiss:
        twoMiss++;
      case _FeedStat.threeMade:
        threeMade++;
      case _FeedStat.threeMiss:
        threeMiss++;
      case _FeedStat.ftMade:
        ftMade++;
      case _FeedStat.ftMiss:
        ftMiss++;
      case _FeedStat.defReb:
        defReb++;
      case _FeedStat.offReb:
        offReb++;
      case _FeedStat.assist:
        assists++;
      case _FeedStat.steal:
        steals++;
      case _FeedStat.block:
        blocks++;
      case _FeedStat.turnover:
        turnovers++;
      case _FeedStat.foul:
        fouls++;
      case _FeedStat.unknown:
        break;
    }
  }

  GameStatsPlayerReportRow toRow(Person player, {required bool onCourt}) {
    return GameStatsPlayerReportRow(
      player: player,
      points: points,
      fgMade: twoMade + threeMade,
      fgAtt: twoMade + threeMade + twoMiss + threeMiss,
      ftMade: ftMade,
      ftAtt: ftMade + ftMiss,
      defReb: defReb,
      offReb: offReb,
      assists: assists,
      steals: steals,
      blocks: blocks,
      turnovers: turnovers,
      fouls: fouls,
      onCourt: onCourt,
    );
  }
}

enum _FeedStat {
  twoMade,
  twoMiss,
  threeMade,
  threeMiss,
  ftMade,
  ftMiss,
  defReb,
  offReb,
  assist,
  steal,
  block,
  turnover,
  foul,
  unknown,
}

_FeedStat _normalizeStat(String raw) {
  final key = raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  return switch (key) {
    '2pt' || 'score_2_made' || 'score_2' => _FeedStat.twoMade,
    '2pt_miss' || 'score_2_miss' => _FeedStat.twoMiss,
    '3pt' || 'score_3_made' || 'score_3' => _FeedStat.threeMade,
    '3pt_miss' || 'score_3_miss' => _FeedStat.threeMiss,
    'ft' || 'score_1_made' || 'score_1' || 'free_throw_made' => _FeedStat.ftMade,
    'ft_miss' || 'score_1_miss' || 'free_throw_miss' => _FeedStat.ftMiss,
    'def_reb' || 'defreb' || 'defensive_rebound' => _FeedStat.defReb,
    'off_reb' || 'offreb' || 'offensive_rebound' => _FeedStat.offReb,
    'asst' || 'assist' || 'assists' => _FeedStat.assist,
    'stl' || 'steal' || 'steals' => _FeedStat.steal,
    'blk' || 'block' || 'blocks' => _FeedStat.block,
    'to' || 'turnover' || 'turnovers' => _FeedStat.turnover,
    'foul' || 'fouls' || 'pf' => _FeedStat.foul,
    _ => _FeedStat.unknown,
  };
}
