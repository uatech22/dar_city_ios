import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';

/// Per-player line for the in-game Dar City stats report.
class GameStatsPlayerReportRow {
  const GameStatsPlayerReportRow({
    required this.player,
    required this.points,
    required this.fgMade,
    required this.fgAtt,
    required this.ftMade,
    required this.ftAtt,
    required this.defReb,
    required this.offReb,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.turnovers,
    required this.fouls,
    required this.onCourt,
  });

  final Person player;
  final int points;
  final int fgMade;
  final int fgAtt;
  final int ftMade;
  final int ftAtt;
  final int defReb;
  final int offReb;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int fouls;
  final bool onCourt;

  int get rebounds => defReb + offReb;

  String get fgLine => fgAtt == 0 ? '0/0' : '$fgMade/$fgAtt';

  String? get fgPct =>
      fgAtt == 0 ? null : '${((fgMade / fgAtt) * 100).round()}%';

  String get ftLine => ftAtt == 0 ? '0/0' : '$ftMade/$ftAtt';

  bool get hasStats =>
      points > 0 ||
      fgAtt > 0 ||
      ftAtt > 0 ||
      rebounds > 0 ||
      assists > 0 ||
      steals > 0 ||
      blocks > 0 ||
      turnovers > 0 ||
      fouls > 0;
}

/// Team totals for the mini report header.
class GameStatsTeamTotals {
  const GameStatsTeamTotals({
    required this.points,
    required this.fgMade,
    required this.fgAtt,
    required this.ftMade,
    required this.ftAtt,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.turnovers,
    required this.fouls,
  });

  final int points;
  final int fgMade;
  final int fgAtt;
  final int ftMade;
  final int ftAtt;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int fouls;

  String? get fgPct =>
      fgAtt == 0 ? null : '${((fgMade / fgAtt) * 100).round()}%';
}

/// Snapshot used by the live game report screen.
class GameStatsGameReport {
  const GameStatsGameReport({
    required this.match,
    required this.teamScore,
    required this.period,
    required this.periodLabel,
    required this.clockLabel,
    required this.clockRunning,
    required this.opponentLabel,
    required this.teamTotals,
    required this.players,
  });

  final Game match;
  final int teamScore;
  final int period;
  final String periodLabel;
  final String clockLabel;
  final bool clockRunning;
  final String opponentLabel;
  final GameStatsTeamTotals teamTotals;
  final List<GameStatsPlayerReportRow> players;
}
