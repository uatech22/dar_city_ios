class LiveMatch {
  final String homeTeam;
  final String awayTeam;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final int homeScore;
  final int awayScore;
  final int quarter;

  LiveMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    required this.quarter,
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    // Safely parse numbers that might be sent as strings.
    int _parseFlexibleInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return LiveMatch(
      homeTeam: json['home_team'] as String? ?? 'TBD',
      awayTeam: json['away_team'] as String? ?? 'TBD',
      homeTeamLogo: json['home_team_logo'] as String? ?? '',
      awayTeamLogo: json['away_team_logo'] as String? ?? '',
      homeScore: _parseFlexibleInt(json['home_score']),
      awayScore: _parseFlexibleInt(json['away_score']),
      quarter: _parseFlexibleInt(json['quarter']), // This will now handle the string "1"
    );
  }
}
