import 'dart:convert';

import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_snapshot.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:flutter/foundation.dart';

/// Console debug output for match lineup / sub picker (visible in `flutter run`).
abstract final class GameStatsLineupDebugLog {
  /// Step 2 — coach picked match-day squad (not yet sent to API).
  static void logMatchLineupSelected({
    required int matchId,
    required List<Person> matchLineup,
  }) {
    if (!kDebugMode) return;

    final ids = matchLineup.map((p) => p.id).toList();
    final buf = StringBuffer()
      ..writeln()
      ..writeln('══════════════════════════════════════════════════════════')
      ..writeln('GAME STATS — MATCH LINEUP SELECTED (step 2, local only)')
      ..writeln('match_id: $matchId')
      ..writeln('selected count: ${ids.length} (will send on Start Game)')
      ..writeln('player ids: $ids')
      ..writeln('players: ${_players(matchLineup)}')
      ..writeln('more than 5: ${ids.length > 5}')
      ..writeln('══════════════════════════════════════════════════════════');

    debugPrint(buf.toString());
  }

  /// Logged right before `POST /coach/game-stats/sessions`.
  static void logCreateSessionRequest({
    required int matchId,
    required List<int> matchLineupPlayerIds,
    required List<int> startingFivePlayerIds,
    required int captainPlayerId,
    int? quarterDurationSeconds,
    List<Person>? matchLineupPlayers,
  }) {
    if (!kDebugMode) return;

    final buf = StringBuffer()
      ..writeln()
      ..writeln('══════════════════════════════════════════════════════════')
      ..writeln('GAME STATS — CREATE SESSION (sent to backend)')
      ..writeln('POST /coach/game-stats/sessions')
      ..writeln('match_id: $matchId')
      ..writeln(
        'quarter_duration_seconds: ${quarterDurationSeconds ?? "(not set)"}',
      )
      ..writeln(
        'match_lineup_player_ids (${matchLineupPlayerIds.length}): $matchLineupPlayerIds',
      )
      ..writeln(
        'starting_five_player_ids (${startingFivePlayerIds.length}): $startingFivePlayerIds',
      )
      ..writeln('captain_player_id: $captainPlayerId')
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln(
        'VERIFY: match_lineup count is ${matchLineupPlayerIds.length} '
        '(need 5–12; more than 5 = ${matchLineupPlayerIds.length > 5})',
      );
    if (matchLineupPlayers != null && matchLineupPlayers.isNotEmpty) {
      buf.writeln('match lineup players: ${_players(matchLineupPlayers)}');
    }
    buf
      ..writeln('full JSON body:')
      ..writeln(
        _pretty({
          'match_id': matchId,
          'match_lineup_player_ids': matchLineupPlayerIds,
          'starting_five_player_ids': startingFivePlayerIds,
          'captain_player_id': captainPlayerId,
        }),
      )
      ..writeln('══════════════════════════════════════════════════════════');

    debugPrint(buf.toString());
  }

  /// Logged when live console opens — compare with starting-lineup screen.
  static void logLiveConsoleLineup({
    required int matchId,
    required int? sessionId,
    required List<Person> sessionRoster,
    required List<Person> pinnedLineup,
    required List<Person> matchRoster,
    required List<Person> onCourt,
    required List<Person> bench,
    String source = 'live console init',
  }) {
    if (!kDebugMode) return;

    final buf = StringBuffer()
      ..writeln()
      ..writeln('══════════════════════════════════════════════════════════')
      ..writeln('GAME STATS — LIVE CONSOLE LINEUP ($source)')
      ..writeln('match_id: $matchId | session_id: $sessionId')
      ..writeln('session.roster passed in: ${sessionRoster.length} → ${_players(sessionRoster)}')
      ..writeln('pinned match lineup: ${pinnedLineup.length} → ${_players(pinnedLineup)}')
      ..writeln('controller matchRoster: ${matchRoster.length} → ${_players(matchRoster)}')
      ..writeln('on court: ${onCourt.length} → ${_players(onCourt)}')
      ..writeln('bench (sub picker): ${bench.length} → ${_players(bench)}')
      ..writeln(
        'SUB will work if bench > 0 (need matchRoster > 5). '
        'bench=${bench.length}, matchRoster=${matchRoster.length}',
      )
      ..writeln('══════════════════════════════════════════════════════════');

    debugPrint(buf.toString());
  }

  static void logSubPickerRefresh({
    required int matchId,
    required int? sessionId,
    required Map<String, dynamic> sessionRaw,
    required List<String> lineupFetchAttempts,
    required GameStatsMatchLineupSnapshot? tableLineup,
    required List<Person> pinnedLineup,
    required List<Person> sessionRoster,
    required List<Person> sessionOnCourt,
    required List<Person> sessionBench,
    required List<Person> sessionMerged,
    required List<Person> finalMatchRoster,
    required List<Person> finalOnCourt,
    required List<Person> finalBench,
  }) {
    if (!kDebugMode) return;

    final sessionJson = _sessionPayload(sessionRaw);
    final buf = StringBuffer()
      ..writeln()
      ..writeln('══════════════════════════════════════════════════════════')
      ..writeln('GAME STATS — SUB BUTTON LINEUP DEBUG')
      ..writeln('match_id: $matchId | session_id: $sessionId')
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('SESSION API — lineup-related keys (raw JSON):')
      ..writeln(_pretty(sessionJson))
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('SESSION parsed counts:')
      ..writeln('  roster/match_lineup: ${sessionRoster.length} → ${_players(sessionRoster)}')
      ..writeln('  on_court: ${sessionOnCourt.length} → ${_players(sessionOnCourt)}')
      ..writeln('  bench: ${sessionBench.length} → ${_players(sessionBench)}')
      ..writeln('  mergedMatchLineup: ${sessionMerged.length} → ${_players(sessionMerged)}')
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('MATCH_LINEUPS fetch attempts:');
    if (lineupFetchAttempts.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final line in lineupFetchAttempts) {
        buf.writeln('  $line');
      }
    }
    buf
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('match_lineups table API:')
      ..writeln(
        tableLineup == null
            ? '  null (no endpoint returned players)'
            : '  lineup: ${tableLineup.lineup.length} → ${_players(tableLineup.lineup)}\n'
                '  on_court (is_on_court=1): ${tableLineup.onCourt.length} → ${_players(tableLineup.onCourt)}',
      )
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('pinned lineup (from app at session start): '
          '${pinnedLineup.length} → ${_players(pinnedLineup)}')
      ..writeln('──────────────────────────────────────────────────────────')
      ..writeln('FINAL sub picker will show:')
      ..writeln('  matchRoster: ${finalMatchRoster.length} → ${_players(finalMatchRoster)}')
      ..writeln('  onCourt: ${finalOnCourt.length} → ${_players(finalOnCourt)}')
      ..writeln('  bench: ${finalBench.length} → ${_players(finalBench)}')
      ..writeln('══════════════════════════════════════════════════════════');

    debugPrint(buf.toString());
  }

  static Map<String, dynamic> _sessionPayload(Map<String, dynamic> raw) {
    final session = raw['session'];
    final map = session is Map<String, dynamic> ? session : raw;
    return {
      'match_lineup': map['match_lineup'],
      'match_lineups': map['match_lineups'],
      'roster': map['roster'],
      'on_court': map['on_court'],
      'bench': map['bench'],
      'on_court_player_ids': map['on_court_player_ids'],
      'bench_player_ids': map['bench_player_ids'],
      'roster_player_ids': map['roster_player_ids'],
      'match_lineup_player_ids': map['match_lineup_player_ids'],
    };
  }

  static String _players(List<Person> players) {
    if (players.isEmpty) return '[]';
    final list = players
        .map(
          (p) => {
            'id': p.id,
            'name': p.fullName,
            'jersey': p.jerseyNumber,
            'position': p.position,
          },
        )
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  static String _pretty(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
