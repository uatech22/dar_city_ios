class Game {
  final int id;
  final String date;
  final String time;
  final String venue;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final DateTime? scheduledAt;

  Game({
    required this.id,
    required this.date,
    required this.time,
    required this.venue,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    this.scheduledAt,
  });

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

    String homeTeamName = 'TBD';
    if (json['home_team'] is Map) {
      homeTeamName = json['home_team']['name'] as String? ?? 'TBD';
    } else if (json['home_team'] is String) {
      homeTeamName = json['home_team'];
    }

    String awayTeamName = 'TBD';
    if (json['away_team'] is Map) {
      awayTeamName = json['away_team']['name'] as String? ?? 'TBD';
    } else if (json['away_team'] is String) {
      awayTeamName = json['away_team'];
    }

    String venue = 'TBD';
    if (json['venue'] is Map) {
      venue = json['venue']['name'] as String? ?? 'TBD';
    } else if (json['venue'] is String) {
      venue = json['venue'];
    }

    return Game(
      id: json['id'] as int? ?? 0,
      date: date,
      time: time,
      scheduledAt: scheduledDateTime,
      venue: venue,
      homeTeam: homeTeamName,
      awayTeam: awayTeamName,
      homeTeamLogo: json['home_team_logo'],
      awayTeamLogo: json['away_team_logo'],
    );
  }
}
