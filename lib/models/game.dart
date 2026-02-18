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

    if (json['scheduled_at'] is String) {
      // The API returns a non-standard date format, so we replace the space with a 'T'
      final parsableDate = (json['scheduled_at'] as String).replaceFirst(' ', 'T');
      scheduledDateTime = DateTime.tryParse(parsableDate);
      
      if (scheduledDateTime != null) {
        final localTime = scheduledDateTime.toLocal();
        date = '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
        time = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
      }
    }


    const String baseUrl = "http://192.168.1.2:8000/";


    // Handle both nested map and direct string for team names
    final homeTeamName = (json['home_team'] is Map) 
        ? json['home_team']['name'] as String? ?? 'TBD' 
        : json['home_team'] as String? ?? 'TBD';

    final awayTeamName = (json['away_team'] is Map) 
        ? json['away_team']['name'] as String? ?? 'TBD' 
        : json['away_team'] as String? ?? 'TBD';

    // Handle both nested map and top-level string for logos
    String homeLogoPath = (json['home_team'] is Map) 
        ? json['home_team']['logo'] as String? ?? '' 
        : json['home_team_logo'] as String? ?? '';
    
    String awayLogoPath = (json['away_team'] is Map) 
        ? json['away_team']['logo'] as String? ?? '' 
        : json['away_team_logo'] as String? ?? '';

    // The backend might return a full URL or a relative path.
    // This ensures we have a valid, absolute URL.
    final homeTeamLogo = (homeLogoPath.startsWith('http'))
        ? homeLogoPath
        : (homeLogoPath.isNotEmpty ? '$baseUrl$homeLogoPath' : '');

    final awayTeamLogo = (awayLogoPath.startsWith('http'))
        ? awayLogoPath
        : (awayLogoPath.isNotEmpty ? '$baseUrl$awayLogoPath' : '');

    final venue = (json['venue'] is Map) ? json['venue']['name'] as String? ?? 'TBD' : 'TBD';

    return Game(
      id: json['id'] as int? ?? 0,
      date: date,
      time: time,
      scheduledAt: scheduledDateTime,
      venue: venue,
      homeTeam: homeTeamName,
      awayTeam: awayTeamName,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
    );
  }
}
