import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/utils/match_logo.dart';
import 'package:dar_city_app/utils/team_name_short.dart';
import 'package:intl/intl.dart';

class Result {
  const Result({
    required this.teamA,
    required this.teamB,
    required this.teamAShort,
    required this.teamBShort,
    required this.scoreA,
    required this.scoreB,
    this.competition,
    this.scheduledAt,
    this.homeTeamLogo = '',
    this.awayTeamLogo = '',
    this.id = 0,
  });

  final int id;
  final String teamA;
  final String teamB;
  final String teamAShort;
  final String teamBShort;
  final int scoreA;
  final int scoreB;
  final String? competition;
  final DateTime? scheduledAt;
  final String homeTeamLogo;
  final String awayTeamLogo;

  factory Result.fromJson(Map<String, dynamic> json) {
    final homeName = _teamName(json, home: true);
    final awayName = _teamName(json, home: false);

    return Result(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      teamA: homeName,
      teamB: awayName,
      teamAShort: _teamShort(json, home: true, fullName: homeName),
      teamBShort: _teamShort(json, home: false, fullName: awayName),
      scoreA: _parseScore(json['home_score']),
      scoreB: _parseScore(json['away_score']),
      competition: json['competition']?.toString(),
      scheduledAt: _parseDate(json['scheduled_at']),
      homeTeamLogo: logoFromMatchJson(json, home: true),
      awayTeamLogo: logoFromMatchJson(json, home: false),
    );
  }

  static String _teamName(Map<String, dynamic> json, {required bool home}) {
    final key = home ? 'home_team' : 'away_team';
    final team = json[key];
    if (team is Map) {
      return team['name']?.toString() ?? 'TBD';
    }
    return team?.toString() ?? 'TBD';
  }

  static String _teamShort(
    Map<String, dynamic> json, {
    required bool home,
    required String fullName,
  }) {
    final key = home ? 'home_team' : 'away_team';
    return teamNameFromApi(json[key], fallback: shortTeamName(fullName));
  }

  static int _parseScore(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final iso = raw.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(iso);
    if (parsed != null) return parsed.toLocal();

    for (final pattern in ['d MMM yyyy, HH:mm', 'd MMM yyyy', 'yyyy-MM-dd HH:mm:ss']) {
      try {
        return DateFormat(pattern).parse(raw).toLocal();
      } catch (_) {}
    }
    return null;
  }

  /// Convert finished match to [Game] for the shared schedule calendar.
  Game toScheduleGame() {
    final at = scheduledAt;
    String date = 'TBD';
    String time = 'TBD';
    if (at != null) {
      date =
          '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
      time = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    }

    return Game(
      id: id,
      date: date,
      time: time,
      scheduledAt: at,
      venue: competition ?? '',
      homeTeam: teamA,
      awayTeam: teamB,
      homeTeamShort: teamAShort,
      awayTeamShort: teamBShort,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      homeScore: scoreA,
      awayScore: scoreB,
      isFinished: true,
    );
  }
}
