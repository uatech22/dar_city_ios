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
    return LiveMatch(
      homeTeam: json['home_team'],
      awayTeam: json['away_team'],
      homeTeamLogo: json['home_team_logo'],
      awayTeamLogo: json['away_team_logo'],
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      quarter: json['quarter'],
    );
  }
}
