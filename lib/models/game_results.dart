import 'package:intl/intl.dart';

class Result {
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final String? competition;
  final DateTime? scheduledAt;

  Result({
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    this.competition,
    this.scheduledAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    // This function now correctly parses the custom date format from the backend.
    DateTime? _parseCustomDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // The format must EXACTLY match the backend format: 'd M Y, H:i'
        return DateFormat('d MMM yyyy, HH:mm').parse(dateStr);
      } catch (e) {
        // If parsing fails, return null instead of crashing.
        return null;
      }
    }

    return Result(
      // Corrected keys to match the backend API
      teamA: json['home_team'] ?? 'Team A',
      teamB: json['away_team'] ?? 'Team B',
      scoreA: json['home_score'] ?? 0,
      scoreB: json['away_score'] ?? 0,
      competition: json['competition'],
      scheduledAt: _parseCustomDate(json['scheduled_at']),
    );
  }
}
