import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/game_stats/debug/game_stats_lineup_debug_log.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_api_session.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_context.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_snapshot.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_report.dart';
import 'package:dar_city_app/features/game_stats/models/live_stat_event.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/services/game_service.dart';

/// Coach game-stats — matches, roster, and live session APIs.
class GameStatsService {
  static const matchesPerPickerPage = 5;

  /// Upcoming fixtures only — no finished or calendar-past games.
  static Future<List<Game>> fetchSelectableMatches() async {
    final all = await MatchService.fetchScheduleCalendar();
    final now = DateTime.now();
    final today = _dateOnly(now);

    final filtered = all.where((game) => !isPastMatch(game, now: now, today: today)).toList();

    filtered.sort((a, b) {
      final ad = a.scheduledAt ?? DateTime(2100);
      final bd = b.scheduledAt ?? DateTime(2100);
      return ad.compareTo(bd);
    });

    return filtered;
  }

  static bool isPastMatch(Game game, {DateTime? now, DateTime? today}) {
    if (game.isFinished) return true;

    final scheduled = game.scheduledAt?.toLocal();
    if (scheduled == null) return false;

    final current = now ?? DateTime.now();
    final day = today ?? _dateOnly(current);
    final matchDay = _dateOnly(scheduled);

    if (matchDay.isBefore(day)) return true;

    return false;
  }

  static Game? defaultMatch(List<Game> matches) {
    if (matches.isEmpty) return null;

    final today = _dateOnly(DateTime.now());
    final todays = matches.where((game) {
      if (game.scheduledAt == null) return false;
      return _dateOnly(game.scheduledAt!.toLocal()) == today;
    }).toList();

    if (todays.isNotEmpty) return todays.first;
    return matches.first;
  }

  static bool isToday(Game game) {
    if (game.scheduledAt == null) return false;
    return _dateOnly(game.scheduledAt!.toLocal()) == _dateOnly(DateTime.now());
  }

  static bool isSameMatch(Game a, Game b) {
    if (a.id != 0 && b.id != 0 && a.id == b.id) return true;
    return a.homeTeam == b.homeTeam &&
        a.awayTeam == b.awayTeam &&
        a.scheduledAt == b.scheduledAt;
  }

  static Game resolveSelected(List<Game> matches, {Game? current}) {
    if (matches.isEmpty) {
      throw StateError('resolveSelected requires at least one match');
    }
    if (current != null) {
      for (final game in matches) {
        if (isSameMatch(game, current)) return game;
      }
    }
    return defaultMatch(matches)!;
  }

  static int pageIndexForMatch(List<Game> matches, Game? selected) {
    if (selected == null || matches.isEmpty) return 0;
    final index = matches.indexWhere((g) => g.id == selected.id);
    if (index < 0) return 0;
    return index ~/ matchesPerPickerPage;
  }

  static List<List<Game>> chunkMatches(List<Game> matches) {
    final pages = <List<Game>>[];
    for (var i = 0; i < matches.length; i += matchesPerPickerPage) {
      final end = (i + matchesPerPickerPage).clamp(0, matches.length);
      pages.add(matches.sublist(i, end));
    }
    return pages;
  }

  static Future<List<Person>> fetchMatchRoster(int matchId) async {
    final context = await fetchMatchLineupContext(matchId);
    return context.players;
  }

  /// Players + saved quarter length for lineup / time picker.
  static Future<GameStatsMatchLineupContext> fetchMatchLineupContext(
    int matchId,
  ) async {
    for (final path in [
      '/coach/game-stats/matches/$matchId',
      '/coach/game-stats/matches/$matchId/roster',
    ]) {
      try {
        if (path.endsWith('/roster')) {
          final data = await FeatureApiClient.getJson(path);
          final players = _playersFromPayload(data);
          if (players.isNotEmpty) {
            return GameStatsMatchLineupContext.fromJson(data, players: players);
          }
        } else {
          final data = await FeatureApiClient.getJson(path);
          final players = _playersFromPayload(data);
          final context = GameStatsMatchLineupContext.fromJson(
            data,
            players: players,
          );
          if (players.isNotEmpty || context.quarterDurationSeconds > 0) {
            if (players.isEmpty) {
              final roster = await CoachDrillService.fetchDrillRosterPlayers();
              return GameStatsMatchLineupContext(
                players: roster.where((p) => p.isAssignableForDrills).toList(),
                quarterDurationSeconds: context.quarterDurationSeconds,
                overtimeDurationSeconds: context.overtimeDurationSeconds,
              );
            }
            return context;
          }
        }
      } catch (_) {
        // Try next path.
      }
    }

    try {
      final list = await FeatureApiClient.getJsonList(
        '/coach/game-stats/matches/$matchId/roster',
      );
      final players = list
          .whereType<Map>()
          .map((e) => Person.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.isAssignableForDrills)
          .toList();
      if (players.isNotEmpty) {
        return GameStatsMatchLineupContext(
          players: players,
          quarterDurationSeconds: GameStatsPeriodConfig.defaultRegulationSeconds,
          overtimeDurationSeconds: GameStatsPeriodConfig.overtimeSeconds,
        );
      }
    } catch (_) {
      // Fall through.
    }

    final roster = await CoachDrillService.fetchDrillRosterPlayers();
    return GameStatsMatchLineupContext(
      players: roster.where((p) => p.isAssignableForDrills).toList(),
      quarterDurationSeconds: GameStatsPeriodConfig.defaultRegulationSeconds,
      overtimeDurationSeconds: GameStatsPeriodConfig.overtimeSeconds,
    );
  }

  static List<Person> _playersFromPayload(Map<String, dynamic> data) {
    for (final key in const ['players', 'roster']) {
      final raw = data[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Person.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.isAssignableForDrills)
            .toList();
      }
    }
    return const [];
  }

  /// Assigned match squad from `match_lineups` (not full club roster, not session on-court only).
  static Future<GameStatsMatchLineupSnapshot?> fetchMatchLineupSnapshot(
    int matchId, {
    List<String>? debugAttempts,
  }) async {
    final attempts = debugAttempts ?? <String>[];
    final listPaths = [
      '/coach/game-stats/matches/$matchId/match-lineups',
      '/coach/game-stats/matches/$matchId/match_lineups',
      '/coach/game-stats/matches/$matchId/lineup',
      '/coach/matches/$matchId/match-lineups',
      '/coach/matches/$matchId/match_lineups',
      '/coach/matches/$matchId/lineups',
    ];

    for (final path in listPaths) {
      try {
        final list = await FeatureApiClient.getJsonList(path);
        final parsed = GameStatsMatchLineupSnapshot.fromRows(list);
        attempts.add('OK $path → list[${list.length}] parsed[${parsed.lineup.length}]');
        if (parsed.lineup.isNotEmpty) return parsed;
      } catch (e) {
        attempts.add('FAIL $path → $e');
      }
    }

    final objectPaths = [
      '/coach/game-stats/matches/$matchId/match-lineups',
      '/coach/game-stats/matches/$matchId/lineup',
      '/coach/matches/$matchId/match-lineups',
    ];

    for (final path in objectPaths) {
      try {
        final data = await FeatureApiClient.getJson(path);
        for (final key in const [
          'data',
          'lineup',
          'match_lineup',
          'match_lineups',
          'players',
          'roster',
        ]) {
          final raw = data[key];
          if (raw is List) {
            final parsed = GameStatsMatchLineupSnapshot.fromRows(raw);
            attempts.add(
              'OK $path key="$key" → list[${raw.length}] parsed[${parsed.lineup.length}]',
            );
            if (parsed.lineup.isNotEmpty) return parsed;
          }
        }
        attempts.add('OK $path → object but no lineup list keys');
      } catch (e) {
        attempts.add('FAIL $path → $e');
      }
    }

    attempts.add('No match_lineups endpoint returned players for match_id=$matchId');
    return null;
  }

  static Future<GameStatsActiveSessionRef?> fetchActiveSession(int matchId) async {
    try {
      final data = await FeatureApiClient.getJson(
        '/coach/game-stats/matches/$matchId/active-session',
      );

      final session = data['session'];
      if (session is Map<String, dynamic>) {
        final id = session['id'] ?? session['session_id'];
        if (id != null) {
          return GameStatsActiveSessionRef.fromJson({
            ...session,
            'session_id': id,
            'match_id': session['match_id'] ?? matchId,
          });
        }
      }
      if (data['session_id'] != null) {
        return GameStatsActiveSessionRef.fromJson({
          ...data,
          'match_id': data['match_id'] ?? matchId,
        });
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<GameStatsApiSession> fetchSession(int sessionId) async {
    final data = await fetchSessionJson(sessionId);
    return _parseSessionPayload(data);
  }

  static Future<Map<String, dynamic>> fetchSessionJson(int sessionId) async {
    return FeatureApiClient.getJson('/coach/game-stats/sessions/$sessionId');
  }

  static Future<GameStatsApiSession> createSession({
    required int matchId,
    required List<int> matchLineupPlayerIds,
    required List<int> startingFivePlayerIds,
    required int captainPlayerId,
    required int quarterDurationSeconds,
  }) async {
    final quarterMinutes =
        GameStatsPeriodConfig.regulationMinutesFromSeconds(quarterDurationSeconds);
    GameStatsLineupDebugLog.logCreateSessionRequest(
      matchId: matchId,
      matchLineupPlayerIds: matchLineupPlayerIds,
      startingFivePlayerIds: startingFivePlayerIds,
      captainPlayerId: captainPlayerId,
      quarterDurationSeconds: quarterDurationSeconds,
    );
    try {
      final body = {
        'match_id': matchId,
        'match_lineup_player_ids': matchLineupPlayerIds,
        'starting_five_player_ids': startingFivePlayerIds,
        'captain_player_id': captainPlayerId,
        'quarter_duration_seconds': quarterDurationSeconds,
        'quarter_duration_minutes': quarterMinutes,
      };
      final data = await FeatureApiClient.postJson(
        '/coach/game-stats/sessions',
        body,
      );
      return _parseSessionPayload(data);
    } on FeatureApiException catch (e) {
      if (e.statusCode == 409) {
        final active = await fetchActiveSession(matchId);
        if (active != null) {
          return fetchSession(active.sessionId);
        }
      }
      rethrow;
    }
  }

  static bool isSubstitutionAction(String action) {
    return action == 'substitution' || action == 'sub' || action == 'substitute';
  }

  static Future<GameStatsApiSession> postEvent({
    required int sessionId,
    required String action,
    int? playerId,
    int? playerOutId,
    int? playerInId,
    int? clockRemainingSeconds,
    bool? clockRunning,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (isSubstitutionAction(action)) {
      final outId = playerOutId ?? playerId;
      final inId = playerInId;
      // Laravel backend stores player_id + secondary_player_id on game_stats_events.
      body['player_id'] = outId;
      body['secondary_player_id'] = inId;
      // Spec aliases — keep for APIs that expect these names.
      body['player_out_id'] = outId;
      body['player_in_id'] = inId;
    } else {
      body['player_id'] = playerId;
    }
    if (clockRemainingSeconds != null) {
      body['clock_remaining_seconds'] = clockRemainingSeconds;
    }
    if (clockRunning != null) {
      body['clock_running'] = clockRunning;
    }

    final data = await FeatureApiClient.postJson(
      '/coach/game-stats/sessions/$sessionId/events',
      body,
    );
    return _parseSessionPayload(data);
  }

  static Future<GameStatsApiSession> undo(int sessionId) async {
    final data = await FeatureApiClient.postJson(
      '/coach/game-stats/sessions/$sessionId/undo',
      {},
    );
    return _parseSessionPayload(data);
  }

  static Future<GameStatsApiSession> patchClock({
    required int sessionId,
    bool? toggle,
    bool? clockRunning,
    int? clockRemainingSeconds,
  }) async {
    final body = <String, dynamic>{};
    if (toggle == true) body['toggle'] = true;
    if (clockRunning != null) body['clock_running'] = clockRunning;
    if (clockRemainingSeconds != null) {
      body['clock_remaining_seconds'] = clockRemainingSeconds;
    }

    final data = await FeatureApiClient.patchJson(
      '/coach/game-stats/sessions/$sessionId/clock',
      body,
    );
    return _parseSessionPayload(data);
  }

  static Future<GameStatsApiSession> patchPeriod({
    required int sessionId,
    bool advance = false,
    int? period,
  }) async {
    final body = <String, dynamic>{};
    if (advance) body['advance'] = true;
    if (period != null) body['period'] = period;

    final data = await FeatureApiClient.patchJson(
      '/coach/game-stats/sessions/$sessionId/period',
      body,
    );
    return _parseSessionPayload(data);
  }

  static Future<GameStatsGameReport> fetchReport({
    required int sessionId,
    required Game match,
  }) async {
    final data = await FeatureApiClient.getJson(
      '/coach/game-stats/sessions/$sessionId/report',
    );
    return parseGameStatsReport(data, match);
  }

  static Future<GameStatsApiSession> postSubstitution({
    required int sessionId,
    required int playerOutId,
    required int playerInId,
    required int clockRemainingSeconds,
    required bool clockRunning,
  }) async {
    if (playerOutId <= 0 || playerInId <= 0) {
      throw FeatureApiException(
        422,
        'Invalid players for substitution. Pick one on court and one from the bench.',
      );
    }

    const actions = ['substitution', 'sub', 'substitute'];
    FeatureApiException? lastError;

    for (var i = 0; i < actions.length; i++) {
      try {
        return await postEvent(
          sessionId: sessionId,
          action: actions[i],
          playerOutId: playerOutId,
          playerInId: playerInId,
          clockRemainingSeconds: clockRemainingSeconds,
          clockRunning: clockRunning,
        );
      } on FeatureApiException catch (e) {
        lastError = e;
        if (e.statusCode != 422 && e.statusCode != 400) rethrow;
        if (i == actions.length - 1) rethrow;
      }
    }

    throw lastError ?? FeatureApiException(422, 'Substitution failed.');
  }

  static Future<GameStatsApiSession> postEventForKind({
    required int sessionId,
    required LiveStatKind kind,
    required bool missed,
    Person? player,
    Person? playerOut,
    Person? playerIn,
    required int clockRemainingSeconds,
    required bool clockRunning,
  }) {
    final action = GameStatsApiSession.actionFor(kind, missed: missed);
    if (isSubstitutionAction(action)) {
      return postSubstitution(
        sessionId: sessionId,
        playerOutId: playerOut?.id ?? 0,
        playerInId: playerIn?.id ?? 0,
        clockRemainingSeconds: clockRemainingSeconds,
        clockRunning: clockRunning,
      );
    }
    return postEvent(
      sessionId: sessionId,
      action: action,
      playerId: player?.id,
      clockRemainingSeconds: clockRemainingSeconds,
      clockRunning: clockRunning,
    );
  }

  static GameStatsApiSession _parseSessionPayload(Map<String, dynamic> data) {
    final sessionJson = data['session'];
    if (sessionJson is Map<String, dynamic>) {
      return GameStatsApiSession.fromJson(sessionJson);
    }
    return GameStatsApiSession.fromJson(data);
  }

  /// Public wrapper for session JSON already fetched (debug / refresh flows).
  static GameStatsApiSession parseSessionPayload(Map<String, dynamic> data) =>
      _parseSessionPayload(data);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
