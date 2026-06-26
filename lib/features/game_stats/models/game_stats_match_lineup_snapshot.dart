import 'package:dar_city_app/models/person.dart';

/// Parsed rows from `match_lineups` — full assigned squad + who is on court.
class GameStatsMatchLineupSnapshot {
  const GameStatsMatchLineupSnapshot({
    required this.lineup,
    required this.onCourt,
  });

  final List<Person> lineup;
  final List<Person> onCourt;

  static GameStatsMatchLineupSnapshot fromRows(List<dynamic> rows) {
    final lineup = <Person>[];
    final onCourt = <Person>[];
    final seen = <int>{};

    for (final item in rows) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final person = _personFromLineupRow(map);
      if (person == null || !seen.add(person.id)) continue;
      lineup.add(person);
      if (_isOnCourtFlag(map['is_on_court'])) {
        onCourt.add(person);
      }
    }

    return GameStatsMatchLineupSnapshot(lineup: lineup, onCourt: onCourt);
  }

  static Person? _personFromLineupRow(Map<String, dynamic> map) {
    final nested = map['player'];
    if (nested is Map) {
      return Person.fromJson(Map<String, dynamic>.from(nested));
    }
    if (map.containsKey('first_name') || map.containsKey('id')) {
      try {
        return Person.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool _isOnCourtFlag(dynamic value) {
    return value == true || value == 1 || value == '1';
  }
}
