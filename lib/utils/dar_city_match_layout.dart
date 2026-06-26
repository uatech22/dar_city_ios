import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/game_results.dart';
import 'package:dar_city_app/models/live_matches.dart';
import 'package:intl/intl.dart';

bool isDarCityTeamName(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('dar city') ||
      normalized.contains('darcity') ||
      normalized.contains('dar-city');
}

/// Fan schedule layout: Dar City on the left when home, on the right when away.
/// That matches venue order (home left, away right).
extension DarCityFanGameLayout on Game {
  bool get isDarCityHome => isDarCityTeamName(homeTeam);

  bool get isDarCityAway => isDarCityTeamName(awayTeam);

  String get fanLeftShort => homeTeamShort;

  String get fanRightShort => awayTeamShort;

  String get fanLeftLogo => homeTeamLogo;

  String get fanRightLogo => awayTeamLogo;

  int? get fanLeftScore => homeScore;

  int? get fanRightScore => awayScore;

  bool get fanLeftIsDarCity => isDarCityHome;

  bool get fanRightIsDarCity => isDarCityAway;

  String get opponentTeam => isDarCityHome ? awayTeam : homeTeam;

  String get opponentShort => isDarCityHome ? awayTeamShort : homeTeamShort;

  String get opponentLogo => isDarCityHome ? awayTeamLogo : homeTeamLogo;

  String get displayTime {
    if (scheduledAt != null) {
      return DateFormat.jm().format(scheduledAt!.toLocal());
    }
    if (time != 'TBD' && time.isNotEmpty) return time;
    return 'TBD';
  }

  DateTime? get calendarDate {
    if (scheduledAt != null) {
      final d = scheduledAt!.toLocal();
      return DateTime(d.year, d.month, d.day);
    }
    final parsed = DateTime.tryParse(date);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  String get detailDateLabel {
    final d = calendarDate ?? scheduledAt?.toLocal();
    if (d == null) return date;
    return DateFormat('MMM d').format(d);
  }

  String get matchupLabel => '$homeTeamShort VS $awayTeamShort';

  int? get darCityScore {
    if (!hasResult) return null;
    return isDarCityHome ? homeScore : awayScore;
  }

  int? get opponentResultScore {
    if (!hasResult) return null;
    return isDarCityHome ? awayScore : homeScore;
  }

  bool get darCityWon {
    final ours = darCityScore;
    final theirs = opponentResultScore;
    if (ours == null || theirs == null) return false;
    return ours > theirs;
  }

  String get darCityResultLine {
    final ours = darCityScore;
    final theirs = opponentResultScore;
    if (ours == null || theirs == null) return '';
    final prefix = darCityWon ? 'W' : 'L';
    return '$prefix $ours-$theirs';
  }

  bool get isUpcoming {
    if (isFinished) return false;
    final at = scheduledAt ?? DateTime.tryParse(date);
    if (at == null) return true;
    return at.toLocal().isAfter(DateTime.now());
  }
}

extension DarCityFanLiveMatchLayout on LiveMatch {
  bool get isDarCityHome => isDarCityTeamName(homeTeam);

  bool get isDarCityAway => isDarCityTeamName(awayTeam);

  String get fanLeftName => homeTeam;

  String get fanRightName => awayTeam;

  String get fanLeftLogo => homeTeamLogo;

  String get fanRightLogo => awayTeamLogo;

  int get fanLeftScore => homeScore;

  int get fanRightScore => awayScore;

  bool get fanLeftIsDarCity => isDarCityHome;

  bool get fanRightIsDarCity => isDarCityAway;
}

extension DarCityFanResultLayout on Result {
  bool get isDarCityHome => isDarCityTeamName(teamA);

  String get fanLeftShort => teamAShort;

  String get fanRightShort => teamBShort;

  int get fanLeftScore => scoreA;

  int get fanRightScore => scoreB;
}
