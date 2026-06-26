import 'package:dar_city_app/utils/match_logo.dart';
import 'package:dar_city_app/utils/team_name_short.dart';

class Game {
  const Game({
    required this.id,
    required this.date,
    required this.time,
    required this.venue,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamShort,
    required this.awayTeamShort,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    this.scheduledAt,
    this.homeScore,
    this.awayScore,
    this.isFinished = false,
  });

  final int id;
  final String date;
  final String time;
  final String venue;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamShort;
  final String awayTeamShort;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final DateTime? scheduledAt;
  final int? homeScore;
  final int? awayScore;
  final bool isFinished;

  bool get hasResult =>
      isFinished && homeScore != null && awayScore != null;

  factory Game.fromJson(Map<String, dynamic> json) {
    DateTime? scheduledDateTime;
    String date = 'TBD';
    String time = 'TBD';

    if (json['scheduled_at'] != null) {
      final rawDate = json['scheduled_at'].toString();
      final parsableDate = rawDate.replaceFirst(' ', 'T');
      scheduledDateTime = DateTime.tryParse(parsableDate);

      if (scheduledDateTime != null) {
        final localTime = scheduledDateTime.toLocal();
        date =
            '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
        time =
            '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
      }
    }

    final homeTeamName = teamFullNameFromApi(json['home_team']);
    final awayTeamName = teamFullNameFromApi(json['away_team']);
    final homeShort =
        teamNameFromApi(json['home_team'], fallback: shortTeamName(homeTeamName));
    final awayShort =
        teamNameFromApi(json['away_team'], fallback: shortTeamName(awayTeamName));

    String venue = 'TBD';
    if (json['venue'] is Map) {
      venue = json['venue']['name'] as String? ?? 'TBD';
    } else if (json['venue'] is String) {
      venue = json['venue'];
    }

    final homeScoreRaw = json['home_score'];
    final awayScoreRaw = json['away_score'];
    final hasScores = homeScoreRaw != null && awayScoreRaw != null;
    final status = json['status']?.toString().toLowerCase() ?? '';
    final finished = hasScores ||
        status == 'finished' ||
        status == 'final' ||
        status == 'completed';

    return Game(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      date: date,
      time: time,
      scheduledAt: scheduledDateTime,
      venue: venue,
      homeTeam: homeTeamName,
      awayTeam: awayTeamName,
      homeTeamShort: homeShort,
      awayTeamShort: awayShort,
      homeTeamLogo: logoFromMatchJson(json, home: true),
      awayTeamLogo: logoFromMatchJson(json, home: false),
      homeScore: hasScores ? _parseScore(homeScoreRaw) : null,
      awayScore: hasScores ? _parseScore(awayScoreRaw) : null,
      isFinished: finished,
    );
  }

  static int _parseScore(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
