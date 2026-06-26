import 'package:dar_city_app/features/game_stats/debug/game_stats_lineup_debug_log.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_snapshot.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_api_session.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_report_builder.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_report.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_session.dart';
import 'package:dar_city_app/features/game_stats/models/live_stat_event.dart';
import 'package:dar_city_app/features/game_stats/services/game_stats_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/utils/team_name_short.dart';

/// How to merge server clock fields when applying a session snapshot.
enum GameStatsClockSyncMode {
  /// Use server clock as-is (load, undo, clock/period patches).
  full,
  /// Keep local clock — scoring/stats/subs must not touch the timer.
  preserve,
  /// Foul only — pause without changing remaining time.
  pauseOnly,
}

/// How to merge server lineup when applying a session snapshot.
enum GameStatsLineupSyncMode {
  /// Replace on-court and bench from the server (load, undo).
  full,
  /// Keep current on-court / bench; still merge player records into match roster.
  preserve,
}

/// Live stats state — local fallback or synced from `/coach/game-stats/sessions`.
class GameStatsLiveController {
  GameStatsLiveController({
    required this.match,
    required List<Person> startingFive,
    List<Person>? roster,
    this.apiSessionId,
  })  : onCourt = List<Person>.from(startingFive),
        bench = _buildBench(roster ?? startingFive, startingFive),
        matchRoster = _buildMatchRoster(roster ?? startingFive, startingFive);

  factory GameStatsLiveController.fromSession(GameStatsSession session) {
    final ctrl = GameStatsLiveController(
      match: session.match,
      startingFive: session.startingFive,
      roster: session.roster,
      apiSessionId: session.apiSessionId,
    );
    if (session.apiSnapshot != null) {
      ctrl.applyApiSession(session.apiSnapshot!);
      ctrl.markLineupSynced();
    } else {
      ctrl.regulationPeriodSeconds = session.quarterDurationSeconds;
      ctrl.clockRemaining = Duration(seconds: session.quarterDurationSeconds);
    }
    ctrl.applyCoachQuarterDuration(session);
    ctrl.overtimeDurationSeconds = session.overtimeDurationSeconds;
    if (session.roster != null && session.roster!.isNotEmpty) {
      ctrl.setMatchLineup(session.roster!);
    }
    return ctrl;
  }

  void applyCoachQuarterDuration(GameStatsSession session) {
    final coachSeconds = session.quarterDurationSeconds;
    if (coachSeconds <= 0) return;

    regulationPeriodSeconds = coachSeconds;

    final snap = session.apiSnapshot;
    if (snap == null) {
      if (period == 1) {
        clockRemaining = Duration(seconds: coachSeconds);
      }
      return;
    }

    // API often echoes match default (e.g. 12:00) even when coach sent 10:00 on create.
    if (snap.period == 1 &&
        !snap.clockRunning &&
        snap.regulationPeriodSeconds != coachSeconds &&
        snap.clockRemainingSeconds == snap.regulationPeriodSeconds) {
      clockRemaining = Duration(seconds: coachSeconds);
    }
  }

  /// Apply match-day lineup (5–12). Never mix with full squad roster.
  void setMatchLineup(List<Person> lineup) {
    matchRoster = List<Person>.from(lineup);
    _pinnedMatchLineup = List<Person>.from(lineup);
    bench = matchRoster
        .where((p) => !onCourt.any((o) => o.id == p.id))
        .toList();
  }

  /// Ensures sub picker has full match-day squad (API session may only return starters).
  void mergeMatchRoster(List<Person> players) {
    matchRoster = _mergePlayerLists(matchRoster, players, const []);
    bench = matchRoster
        .where((p) => !onCourt.any((o) => o.id == p.id))
        .toList();
  }

  Game match;
  int? apiSessionId;

  bool get isRemote => apiSessionId != null;

  int teamScore = 0;
  List<Person> onCourt;
  List<Person> bench;
  List<Person> matchRoster;

  /// Coach-assigned match squad — never shrink below this during refresh.
  List<Person>? _pinnedMatchLineup;

  /// Full match-day squad pinned at session start (for debug + sub picker floor).
  List<Person> get pinnedMatchLineup =>
      List<Person>.unmodifiable(_pinnedMatchLineup ?? const []);

  final List<LiveStatEvent> feed = [];
  final List<_LiveSnapshot> _history = [];

  int period = 1;
  Duration clockRemaining =
      const Duration(seconds: GameStatsPeriodConfig.defaultRegulationSeconds);
  bool clockRunning = false;
  bool canUndo = false;

  int regulationPeriodSeconds = GameStatsPeriodConfig.defaultRegulationSeconds;
  int overtimeDurationSeconds = GameStatsPeriodConfig.overtimeSeconds;
  String? _apiPeriodLabel;

  final Map<int, Map<String, int>> _playerStatTotals = {};

  static String filterTabLabel(int periodNumber) =>
      GameStatsPeriodConfig.feedFilterLabel(periodNumber);

  static List<int> coveredPeriodFilters(int currentPeriod) =>
      GameStatsPeriodConfig.coveredPeriodFilters(currentPeriod);

  String? get lastError => _lastError;
  String? _lastError;

  DateTime? _lastLineupSyncAt;
  static const pickerLineupRefreshMaxAge = Duration(seconds: 8);

  void clearError() => _lastError = null;

  /// Pull latest on-court + match lineup from backend before player pickers.
  /// Does not touch clock, feed, score, or period.
  Future<bool> refreshSessionForPicker({bool force = false, bool logLineup = false}) async {
    final sessionId = apiSessionId;
    if (sessionId == null) return true;

    if (!force &&
        _lastLineupSyncAt != null &&
        DateTime.now().difference(_lastLineupSyncAt!) < pickerLineupRefreshMaxAge) {
      return true;
    }

    try {
      final sessionRaw = await GameStatsService.fetchSessionJson(sessionId);
      final snapshot = GameStatsService.parseSessionPayload(sessionRaw);
      final lineupAttempts = <String>[];
      final tableLineup = await GameStatsService.fetchMatchLineupSnapshot(
        match.id,
        debugAttempts: logLineup ? lineupAttempts : null,
      );

      applyLineupFromSnapshot(snapshot, tableLineup: tableLineup);

      if (logLineup) {
        GameStatsLineupDebugLog.logSubPickerRefresh(
          matchId: match.id,
          sessionId: sessionId,
          sessionRaw: sessionRaw,
          lineupFetchAttempts: lineupAttempts,
          tableLineup: tableLineup,
          pinnedLineup: List<Person>.from(_pinnedMatchLineup ?? const []),
          sessionRoster: snapshot.roster,
          sessionOnCourt: snapshot.onCourt,
          sessionBench: snapshot.bench,
          sessionMerged: snapshot.mergedMatchLineup,
          finalMatchRoster: List<Person>.from(matchRoster),
          finalOnCourt: List<Person>.from(onCourt),
          finalBench: List<Person>.from(bench),
        );
      }

      return true;
    } on FeatureApiException catch (e) {
      _lastError = e.message?.toString() ?? 'Could not refresh players.';
      return false;
    } catch (_) {
      _lastError = 'Could not refresh players.';
      return false;
    }
  }

  void applyLineupFromSnapshot(
    GameStatsApiSession snapshot, {
    GameStatsMatchLineupSnapshot? tableLineup,
  }) {
    apiSessionId = snapshot.id;
    final merged = _mergePlayerLists(
      _mergePlayerLists(
        _pinnedMatchLineup ?? const <Person>[],
        tableLineup?.lineup ?? const <Person>[],
        const <Person>[],
      ),
      snapshot.mergedMatchLineup,
      const <Person>[],
    );
    matchRoster = merged.isNotEmpty ? merged : snapshot.mergedMatchLineup;
    if (_pinnedMatchLineup != null &&
        _pinnedMatchLineup!.length > matchRoster.length) {
      matchRoster = _mergePlayerLists(matchRoster, _pinnedMatchLineup!, const []);
    }

    if (tableLineup != null && tableLineup.onCourt.isNotEmpty) {
      onCourt = List<Person>.from(tableLineup.onCourt);
    } else {
      onCourt = List<Person>.from(snapshot.onCourt);
    }
    bench = matchRoster
        .where((p) => !onCourt.any((o) => o.id == p.id))
        .toList();
    _lastLineupSyncAt = DateTime.now();
    _lastError = null;
  }

  void markLineupSynced() => _lastLineupSyncAt = DateTime.now();

  void applyApiSession(
    GameStatsApiSession snapshot, {
    GameStatsClockSyncMode clockSync = GameStatsClockSyncMode.full,
    GameStatsLineupSyncMode lineupSync = GameStatsLineupSyncMode.full,
  }) {
    apiSessionId = snapshot.id;
    match = snapshot.match;
    teamScore = snapshot.teamScore;
    period = snapshot.period;
    _apiPeriodLabel = snapshot.periodLabel;
    if (snapshot.regulationPeriodSeconds > 0) {
      regulationPeriodSeconds = snapshot.regulationPeriodSeconds;
    }
    if (snapshot.overtimeDurationSeconds > 0) {
      overtimeDurationSeconds = snapshot.overtimeDurationSeconds;
    }
    switch (clockSync) {
      case GameStatsClockSyncMode.full:
        clockRemaining = snapshot.clockRemaining;
        clockRunning = snapshot.clockRunning;
      case GameStatsClockSyncMode.preserve:
        break;
      case GameStatsClockSyncMode.pauseOnly:
        clockRunning = false;
    }
    matchRoster = _mergePlayerLists(
      _mergePlayerLists(matchRoster, snapshot.roster, snapshot.onCourt),
      snapshot.bench,
      const [],
    );
    final mergedLineup = snapshot.mergedMatchLineup;
    if (mergedLineup.length > matchRoster.length) {
      matchRoster = mergedLineup;
    }
    if (lineupSync == GameStatsLineupSyncMode.full) {
      onCourt = List<Person>.from(snapshot.onCourt);
      bench = matchRoster
          .where((p) => !onCourt.any((o) => o.id == p.id))
          .toList();
    } else {
      bench = matchRoster
          .where((p) => !onCourt.any((o) => o.id == p.id))
          .toList();
    }
    feed
      ..clear()
      ..addAll(snapshot.feed);
    _playerStatTotals
      ..clear()
      ..addAll(
        snapshot.playerStatTotals.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ),
      );
    canUndo = snapshot.canUndo;
    _lastError = null;
  }

  static List<Person> _mergePlayerLists(
    List<Person> roster,
    List<Person> onCourt,
    List<Person> bench,
  ) {
    final seen = <int>{};
    final merged = <Person>[];
    for (final player in [...roster, ...onCourt, ...bench]) {
      if (seen.add(player.id)) merged.add(player);
    }
    return merged;
  }

  static List<Person> _buildBench(List<Person> roster, List<Person> starters) {
    final starterIds = starters.map((p) => p.id).toSet();
    return roster.where((p) => !starterIds.contains(p.id)).toList();
  }

  static List<Person> _buildMatchRoster(List<Person> roster, List<Person> starters) {
    final seen = <int>{};
    final merged = <Person>[];
    for (final player in [...starters, ...roster]) {
      if (seen.add(player.id)) merged.add(player);
    }
    return merged;
  }

  bool isOnCourt(Person player) => onCourt.any((p) => p.id == player.id);

  Set<int> get onCourtIds => onCourt.map((p) => p.id).toSet();

  List<Person> get rosterOnCourtFirst {
    final playing = List<Person>.from(onCourt);
    final rest = matchRoster
        .where((p) => !onCourtIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return [...playing, ...rest];
  }

  List<Person> get benchPlayers =>
      matchRoster.where((p) => !onCourtIds.contains(p.id)).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  static String shortPlayerName(Person player) {
    final parts = player.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}. ${parts.last}';
    }
    return player.fullName;
  }

  List<LiveStatEvent> filteredFeed(int periodFilter) {
    return feed.where((e) => e.period == periodFilter).toList();
  }

  Future<bool> scoreForPlayer(Person player, LiveStatKind kind) {
    if (isRemote) {
      return _remoteEvent(kind: kind, player: player, missed: false);
    }
    return Future.value(_localScoreForPlayer(player, kind));
  }

  Future<bool> missForPlayer(Person player, LiveStatKind kind) {
    if (isRemote) {
      return _remoteEvent(kind: kind, player: player, missed: true);
    }
    return Future.value(_localMissForPlayer(player, kind));
  }

  Future<bool> recordStatForPlayer(Person player, LiveStatKind kind) {
    if (isRemote) {
      return _remoteEvent(kind: kind, player: player, missed: false);
    }
    return Future.value(_localRecordStatForPlayer(player, kind));
  }

  Future<bool> substitute({
    required Person playerOut,
    required Person playerIn,
  }) {
    if (isRemote) {
      return _remoteSubstitute(playerOut: playerOut, playerIn: playerIn);
    }
    return Future.value(_localSubstitute(playerOut: playerOut, playerIn: playerIn));
  }

  Future<bool> undo() {
    if (isRemote) {
      return _remoteUndo();
    }
    return Future.value(_localUndo());
  }

  Future<bool> toggleClock() {
    if (isRemote) {
      return _remotePatchClock(toggle: true);
    }
    clockRunning = !clockRunning;
    return Future.value(true);
  }

  Future<bool> advancePeriod() {
    if (isRemote) {
      return _remotePatchPeriod(advance: true);
    }
    period += 1;
    clockRemaining = _defaultClockForPeriod(period);
    clockRunning = false;
    return Future.value(true);
  }

  Future<bool> setPeriod(int value) {
    if (value < 1) return Future.value(false);
    if (isRemote) {
      return _remotePatchPeriod(period: value);
    }
    period = value;
    _apiPeriodLabel = formatPeriodLabel(value);
    clockRemaining = _defaultClockForPeriod(period);
    clockRunning = false;
    return Future.value(true);
  }

  Duration _defaultClockForPeriod(int periodNumber) {
    final seconds = periodNumber > 4
        ? overtimeDurationSeconds
        : regulationPeriodSeconds;
    return Duration(seconds: seconds);
  }

  /// API period advance may reset to match default (12:00) — keep coach quarter length.
  void _syncClockAfterPeriodChangeIfNeeded() {
    final expected = _defaultClockForPeriod(period);
    if (clockRemaining != expected) {
      clockRemaining = expected;
      clockRunning = false;
    }
  }

  Future<bool> setClock(Duration value) {
    if (isRemote) {
      return _remotePatchClock(
        clockRemainingSeconds: value.inSeconds,
        clockRunning: false,
      );
    }
    clockRemaining = value;
    return Future.value(true);
  }

  Future<GameStatsGameReport> fetchReport() {
    if (isRemote && apiSessionId != null) {
      return GameStatsService.fetchReport(
        sessionId: apiSessionId!,
        match: match,
      );
    }
    return Future.value(buildGameReport());
  }

  void tickClock() {
    if (!clockRunning || clockRemaining.inSeconds <= 0) return;
    clockRemaining -= const Duration(seconds: 1);
    if (clockRemaining.isNegative) {
      clockRemaining = Duration.zero;
      clockRunning = false;
    }
  }

  static String formatPeriodLabel(int periodNumber) =>
      GameStatsPeriodConfig.formatPeriodLabel(periodNumber);

  String get periodLabel =>
      _apiPeriodLabel ?? formatPeriodLabel(period);

  bool get isOvertime => period > 4;

  String get clockLabel {
    final h = clockRemaining.inHours;
    final m = clockRemaining.inMinutes.remainder(60);
    final s = clockRemaining.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _remoteEvent({
    required LiveStatKind kind,
    required Person player,
    required bool missed,
  }) async {
    final sessionId = apiSessionId;
    if (sessionId == null) return false;
    final foulPause = kind == LiveStatKind.foul;
    try {
      final snapshot = await GameStatsService.postEventForKind(
        sessionId: sessionId,
        kind: kind,
        missed: missed,
        player: player,
        clockRemainingSeconds: clockRemaining.inSeconds,
        clockRunning: foulPause ? false : clockRunning,
      );
      applyApiSession(
        snapshot,
        clockSync: kind == LiveStatKind.foul
            ? GameStatsClockSyncMode.pauseOnly
            : GameStatsClockSyncMode.preserve,
        lineupSync: GameStatsLineupSyncMode.preserve,
      );
      return true;
    } on FeatureApiException catch (e) {
      _lastError = e.message?.toString() ?? 'Could not record stat.';
      return false;
    } catch (_) {
      _lastError = 'Could not record stat.';
      return false;
    }
  }

  Future<bool> _remoteSubstitute({
    required Person playerOut,
    required Person playerIn,
  }) async {
    final sessionId = apiSessionId;
    if (sessionId == null) return false;
    if (!onCourt.any((p) => p.id == playerOut.id)) {
      _lastError = 'Pick a player currently on court.';
      return false;
    }
    if (!benchPlayers.any((p) => p.id == playerIn.id)) {
      _lastError = 'Pick a player from the bench.';
      return false;
    }
    if (playerOut.id <= 0 || playerIn.id <= 0) {
      _lastError = 'Invalid player selection for substitution.';
      return false;
    }
    try {
      final snapshot = await GameStatsService.postEventForKind(
        sessionId: sessionId,
        kind: LiveStatKind.sub,
        missed: false,
        playerOut: playerOut,
        playerIn: playerIn,
        clockRemainingSeconds: clockRemaining.inSeconds,
        clockRunning: clockRunning,
      );
      applyApiSession(
        snapshot,
        clockSync: GameStatsClockSyncMode.preserve,
        lineupSync: GameStatsLineupSyncMode.preserve,
      );
      _syncLineupAfterSubstitution(snapshot, playerOut: playerOut, playerIn: playerIn);
      _insertSubstitutionFeed(playerOut, playerIn);
      canUndo = true;
      markLineupSynced();
      return true;
    } on FeatureApiException catch (e) {
      _lastError = e.message?.toString() ?? 'Substitution failed.';
      return false;
    } catch (_) {
      _lastError = 'Substitution failed.';
      return false;
    }
  }

  void _applySubstitutionSwap(Person playerOut, Person playerIn) {
    onCourt = onCourt.map((p) => p.id == playerOut.id ? playerIn : p).toList();
    bench = matchRoster.where((p) => !onCourtIds.contains(p.id)).toList();
  }

  /// Prefer server on-court when it reflects the sub; otherwise swap locally.
  void _syncLineupAfterSubstitution(
    GameStatsApiSession snapshot, {
    required Person playerOut,
    required Person playerIn,
  }) {
    final serverIds = snapshot.onCourt.map((p) => p.id).toSet();
    if (serverIds.length == GameStatsSession.requiredStarters &&
        serverIds.contains(playerIn.id) &&
        !serverIds.contains(playerOut.id)) {
      onCourt = List<Person>.from(snapshot.onCourt);
      bench = matchRoster.where((p) => !onCourtIds.contains(p.id)).toList();
      return;
    }
    _applySubstitutionSwap(playerOut, playerIn);
  }

  bool _feedIncludesSubstitution(Person playerOut, Person playerIn) {
    final outJersey = playerOut.jerseyNumber ?? -1;
    final inJersey = playerIn.jerseyNumber ?? -1;
    var sawOut = false;
    var sawIn = false;
    for (final event in feed.take(8)) {
      if (event.stat == 'SUB OUT' && event.jersey == outJersey) sawOut = true;
      if (event.stat == 'SUB IN' && event.jersey == inJersey) sawIn = true;
    }
    return sawOut && sawIn;
  }

  void _insertSubstitutionFeed(Person playerOut, Person playerIn) {
    if (_feedIncludesSubstitution(playerOut, playerIn)) return;
    feed.insert(
      0,
      _newEvent(
        stat: 'SUB IN',
        jersey: playerIn.jerseyNumber ?? 0,
        name: shortPlayerName(playerIn),
      ),
    );
    feed.insert(
      1,
      _newEvent(
        stat: 'SUB OUT',
        jersey: playerOut.jerseyNumber ?? 0,
        name: shortPlayerName(playerOut),
      ),
    );
  }

  Future<bool> _remoteUndo() async {
    final sessionId = apiSessionId;
    if (sessionId == null) return false;
    try {
      final snapshot = await GameStatsService.undo(sessionId);
      applyApiSession(snapshot);
      return true;
    } on FeatureApiException catch (e) {
      _lastError = e.message?.toString() ?? 'Nothing to undo.';
      return false;
    } catch (_) {
      _lastError = 'Nothing to undo.';
      return false;
    }
  }

  Future<bool> _remotePatchClock({
    bool toggle = false,
    bool? clockRunning,
    int? clockRemainingSeconds,
  }) async {
    final sessionId = apiSessionId;
    if (sessionId == null) return false;

    final wasRunning = this.clockRunning;
    final wasRemaining = clockRemaining;
    if (toggle) {
      this.clockRunning = !this.clockRunning;
    } else {
      if (clockRunning != null) this.clockRunning = clockRunning;
      if (clockRemainingSeconds != null) {
        clockRemaining = Duration(seconds: clockRemainingSeconds);
      }
    }

    try {
      final snapshot = await GameStatsService.patchClock(
        sessionId: sessionId,
        toggle: toggle,
        clockRunning: clockRunning,
        clockRemainingSeconds: clockRemainingSeconds,
      );
      applyApiSession(
        snapshot,
        clockSync: GameStatsClockSyncMode.full,
        lineupSync: GameStatsLineupSyncMode.preserve,
      );
      return true;
    } on FeatureApiException catch (e) {
      this.clockRunning = wasRunning;
      clockRemaining = wasRemaining;
      _lastError = e.message?.toString() ?? 'Clock update failed.';
      return false;
    } catch (_) {
      this.clockRunning = wasRunning;
      clockRemaining = wasRemaining;
      _lastError = 'Clock update failed.';
      return false;
    }
  }

  Future<bool> _remotePatchPeriod({bool advance = false, int? period}) async {
    final sessionId = apiSessionId;
    if (sessionId == null) return false;
    try {
      final snapshot = await GameStatsService.patchPeriod(
        sessionId: sessionId,
        advance: advance,
        period: period,
      );
      applyApiSession(
        snapshot,
        clockSync: GameStatsClockSyncMode.full,
        lineupSync: GameStatsLineupSyncMode.preserve,
      );
      _syncClockAfterPeriodChangeIfNeeded();
      return true;
    } on FeatureApiException catch (e) {
      _lastError = e.message?.toString() ?? 'Period update failed.';
      return false;
    } catch (_) {
      _lastError = 'Period update failed.';
      return false;
    }
  }

  bool _localScoreForPlayer(Person player, LiveStatKind kind) {
    if (!onCourt.any((p) => p.id == player.id)) {
      _lastError = 'Player must be on court.';
      return false;
    }
    final points = _pointsFor(kind);
    if (points == 0) return false;
    _pushSnapshot();
    teamScore += points;
    _addPlayerEvent(player, _scoreLabel(kind));
    return true;
  }

  bool _localMissForPlayer(Person player, LiveStatKind kind) {
    if (!onCourt.any((p) => p.id == player.id)) {
      _lastError = 'Player must be on court.';
      return false;
    }
    if (_pointsFor(kind) == 0) return false;
    _pushSnapshot();
    _addPlayerEvent(player, '${_scoreLabel(kind)} MISS', isMiss: true);
    return true;
  }

  bool _localRecordStatForPlayer(Person player, LiveStatKind kind) {
    if (kind == LiveStatKind.sub) return false;
    if (!onCourt.any((p) => p.id == player.id)) {
      _lastError = 'Player must be on court.';
      return false;
    }
    final label = _statLabel(kind);
    if (label.isEmpty) return false;
    _pushSnapshot();
    if (kind == LiveStatKind.foul) {
      clockRunning = false;
    }
    _addPlayerEvent(player, label);
    return true;
  }

  bool _localSubstitute({
    required Person playerOut,
    required Person playerIn,
  }) {
    if (!onCourt.any((p) => p.id == playerOut.id)) {
      _lastError = 'Pick a player currently on court.';
      return false;
    }
    if (!benchPlayers.any((p) => p.id == playerIn.id)) {
      _lastError = 'Pick a player from the bench.';
      return false;
    }
    _pushSnapshot();
    _applySubstitutionSwap(playerOut, playerIn);
    _insertSubstitutionFeed(playerOut, playerIn);
    return true;
  }

  bool _localUndo() {
    if (_history.isEmpty) {
      _lastError = 'Nothing to undo.';
      return false;
    }
    final snap = _history.removeLast();
    teamScore = snap.teamScore;
    onCourt = List<Person>.from(snap.onCourt);
    bench = List<Person>.from(snap.bench);
    feed
      ..clear()
      ..addAll(snap.feed);
    _playerStatTotals
      ..clear()
      ..addAll(snap.playerStatTotals);
    _lastError = null;
    canUndo = _history.isNotEmpty;
    return true;
  }

  int _pointsFor(LiveStatKind kind) => switch (kind) {
        LiveStatKind.score2 => 2,
        LiveStatKind.score3 => 3,
        LiveStatKind.score1 => 1,
        _ => 0,
      };

  String _scoreLabel(LiveStatKind kind) => switch (kind) {
        LiveStatKind.score3 => '3PT',
        LiveStatKind.score2 => '2PT',
        LiveStatKind.score1 => 'FT',
        _ => '',
      };

  String _statLabel(LiveStatKind kind) => switch (kind) {
        LiveStatKind.defReb => 'DEF REB',
        LiveStatKind.offReb => 'OFF REB',
        LiveStatKind.turnover => 'TO',
        LiveStatKind.steal => 'STL',
        LiveStatKind.assist => 'ASST',
        LiveStatKind.block => 'BLK',
        LiveStatKind.foul => 'FOUL',
        _ => '',
      };

  void _addPlayerEvent(
    Person player,
    String stat, {
    String? displayName,
    bool isMiss = false,
  }) {
    final totals = _playerStatTotals.putIfAbsent(player.id, () => {});
    final next = (totals[stat] ?? 0) + 1;
    totals[stat] = next;
    feed.insert(
      0,
      _newEvent(
        stat: stat,
        jersey: player.jerseyNumber ?? 0,
        name: displayName ?? shortPlayerName(player),
        count: _showCount(stat) ? next : null,
        isMiss: isMiss,
      ),
    );
    canUndo = true;
  }

  LiveStatEvent _newEvent({
    required String stat,
    required int jersey,
    required String name,
    int? count,
    bool isMiss = false,
  }) {
    return LiveStatEvent(
      stat: stat,
      jersey: jersey,
      name: name,
      period: period,
      periodLabel: periodLabel,
      clockLabel: clockLabel,
      count: count,
      isMiss: isMiss,
    );
  }

  bool _showCount(String stat) => stat != 'SUB IN' && stat != 'SUB OUT';

  int _countFor(int playerId, String stat) =>
      _playerStatTotals[playerId]?[stat] ?? 0;

  GameStatsPlayerReportRow _rowForPlayer(Person player) {
    final id = player.id;
    final twoMade = _countFor(id, '2PT');
    final threeMade = _countFor(id, '3PT');
    final twoMiss = _countFor(id, '2PT MISS');
    final threeMiss = _countFor(id, '3PT MISS');
    final ftMade = _countFor(id, 'FT');
    final ftMiss = _countFor(id, 'FT MISS');

    return GameStatsPlayerReportRow(
      player: player,
      points: twoMade * 2 + threeMade * 3 + ftMade,
      fgMade: twoMade + threeMade,
      fgAtt: twoMade + threeMade + twoMiss + threeMiss,
      ftMade: ftMade,
      ftAtt: ftMade + ftMiss,
      defReb: _countFor(id, 'DEF REB'),
      offReb: _countFor(id, 'OFF REB'),
      assists: _countFor(id, 'ASST'),
      steals: _countFor(id, 'STL'),
      blocks: _countFor(id, 'BLK'),
      turnovers: _countFor(id, 'TO'),
      fouls: _countFor(id, 'FOUL'),
      onCourt: isOnCourt(player),
    );
  }

  static String opponentShortLabel(Game match) {
    final home = match.homeTeam.toLowerCase();
    if (home.contains('dar city') || home.contains('darcity')) {
      return match.awayTeamShort.isNotEmpty
          ? match.awayTeamShort
          : shortTeamName(match.awayTeam);
    }
    return match.homeTeamShort.isNotEmpty
        ? match.homeTeamShort
        : shortTeamName(match.homeTeam);
  }

  GameStatsGameReport buildGameReport({int? forPeriod}) {
    if (forPeriod != null) {
      return GameStatsPeriodReportBuilder.build(
        forPeriod: forPeriod,
        feed: feed,
        roster: matchRoster,
        match: match,
        opponentLabel: opponentShortLabel(match),
        isOnCourt: isOnCourt,
        shortName: shortPlayerName,
      );
    }

    final rows = matchRoster.map(_rowForPlayer).toList()
      ..sort((a, b) {
        final byPts = b.points.compareTo(a.points);
        if (byPts != 0) return byPts;
        return a.player.fullName.compareTo(b.player.fullName);
      });

    var fgMade = 0;
    var fgAtt = 0;
    var ftMade = 0;
    var ftAtt = 0;
    var rebounds = 0;
    var assists = 0;
    var steals = 0;
    var blocks = 0;
    var turnovers = 0;
    var fouls = 0;

    for (final row in rows) {
      fgMade += row.fgMade;
      fgAtt += row.fgAtt;
      ftMade += row.ftMade;
      ftAtt += row.ftAtt;
      rebounds += row.rebounds;
      assists += row.assists;
      steals += row.steals;
      blocks += row.blocks;
      turnovers += row.turnovers;
      fouls += row.fouls;
    }

    return GameStatsGameReport(
      match: match,
      teamScore: teamScore,
      period: period,
      periodLabel: periodLabel,
      clockLabel: clockLabel,
      clockRunning: clockRunning,
      opponentLabel: opponentShortLabel(match),
      teamTotals: GameStatsTeamTotals(
        points: teamScore,
        fgMade: fgMade,
        fgAtt: fgAtt,
        ftMade: ftMade,
        ftAtt: ftAtt,
        rebounds: rebounds,
        assists: assists,
        steals: steals,
        blocks: blocks,
        turnovers: turnovers,
        fouls: fouls,
      ),
      players: rows,
    );
  }

  void _pushSnapshot() {
    _history.add(
      _LiveSnapshot(
        teamScore: teamScore,
        onCourt: List<Person>.from(onCourt),
        bench: List<Person>.from(bench),
        feed: List<LiveStatEvent>.from(feed),
        playerStatTotals: _playerStatTotals.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ),
      ),
    );
    _lastError = null;
    canUndo = true;
  }
}

class _LiveSnapshot {
  const _LiveSnapshot({
    required this.teamScore,
    required this.onCourt,
    required this.bench,
    required this.feed,
    required this.playerStatTotals,
  });

  final int teamScore;
  final List<Person> onCourt;
  final List<Person> bench;
  final List<LiveStatEvent> feed;
  final Map<int, Map<String, int>> playerStatTotals;
}
