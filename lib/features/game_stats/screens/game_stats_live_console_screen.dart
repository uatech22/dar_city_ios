import 'dart:async';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/game_stats/debug/game_stats_lineup_debug_log.dart';
import 'package:dar_city_app/features/game_stats/controllers/game_stats_live_controller.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_session.dart';
import 'package:dar_city_app/features/game_stats/models/live_stat_event.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_game_report_screen.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_landscape_viewport.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_player_avatar.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step 3 — live stats console (stats_main layout, rotated landscape viewport).
class GameStatsLiveConsoleScreen extends StatefulWidget {
  const GameStatsLiveConsoleScreen({super.key, required this.session});

  final GameStatsSession session;

  @override
  State<GameStatsLiveConsoleScreen> createState() => _GameStatsLiveConsoleScreenState();
}

class _GameStatsLiveConsoleScreenState extends State<GameStatsLiveConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _livePulse;
  late final GameStatsLiveController _ctrl;
  Timer? _clockTimer;

  int _feedPeriodFilter = 1;
  _PendingPlayerPick? _pendingPick;
  bool _busy = false;
  bool _refreshingPicker = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GameStatsLiveController.fromSession(widget.session);
    _feedPeriodFilter = _ctrl.period;
    _livePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_ctrl.clockRunning) return;
      setState(() => _ctrl.tickClock());
    });
    _enterConsoleMode();
    _ensureMatchLineup();
  }

  /// Match lineup from session/API — never pull full club squad into subs.
  void _ensureMatchLineup() {
    var lineup = widget.session.roster ?? const <Person>[];
    final snap = widget.session.apiSnapshot;
    if (lineup.length <= GameStatsSession.requiredStarters && snap != null) {
      final merged = snap.mergedMatchLineup;
      if (merged.length > lineup.length) lineup = merged;
    }
    if (lineup.isNotEmpty) {
      _ctrl.setMatchLineup(lineup);
    }
    GameStatsLineupDebugLog.logLiveConsoleLineup(
      matchId: widget.session.match.id,
      sessionId: widget.session.apiSessionId,
      sessionRoster: lineup,
      pinnedLineup: _ctrl.pinnedMatchLineup,
      matchRoster: _ctrl.matchRoster,
      onCourt: _ctrl.onCourt,
      bench: _ctrl.benchPlayers,
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _livePulse.dispose();
    _exitConsoleMode();
    super.dispose();
  }

  void _showError(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DarColors.cardDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _applyAsync(Future<bool> action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await action;
      if (!ok) {
        _showError(_ctrl.lastError);
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPlayerPicker(_PendingPlayerPick pick) async {
    if (_busy || _refreshingPicker) return;

    if (_ctrl.isRemote) {
      setState(() => _refreshingPicker = true);
      final ok = await _ctrl.refreshSessionForPicker(
        force: pick.isSub,
        logLineup: pick.isSub,
      );
      if (!mounted) return;
      setState(() => _refreshingPicker = false);
      if (!ok) {
        _showError(_ctrl.lastError);
        return;
      }
      GameStatsLineupDebugLog.logLiveConsoleLineup(
        matchId: _ctrl.match.id,
        sessionId: _ctrl.apiSessionId,
        sessionRoster: widget.session.roster ?? const [],
        pinnedLineup: _ctrl.pinnedMatchLineup,
        matchRoster: _ctrl.matchRoster,
        onCourt: _ctrl.onCourt,
        bench: _ctrl.benchPlayers,
        source: pick.isSub ? 'after SUB refresh' : 'after picker refresh',
      );
    }

    if (!mounted) return;
    setState(() => _pendingPick = pick);
  }

  void _beginScore(LiveStatKind kind, {required bool missed}) {
    _openPlayerPicker(_PendingPlayerPick.score(kind, missed: missed));
  }

  void _beginStat(LiveStatKind kind) {
    if (kind == LiveStatKind.sub) {
      _openPlayerPicker(const _PendingPlayerPick.subOut());
      return;
    }
    _openPlayerPicker(_PendingPlayerPick.stat(kind));
  }

  void _cancelPendingPick() => setState(() => _pendingPick = null);

  void _onPlayerPicked(Person player) async {
    final pending = _pendingPick;
    if (pending == null || _busy) return;

    switch (pending.type) {
      case _PendingPickType.score:
        if (pending.missed) {
          await _applyAsync(_ctrl.missForPlayer(player, pending.kind!));
        } else {
          await _applyAsync(_ctrl.scoreForPlayer(player, pending.kind!));
        }
        break;
      case _PendingPickType.stat:
        await _applyAsync(_ctrl.recordStatForPlayer(player, pending.kind!));
        break;
      case _PendingPickType.subOut:
        if (!_ctrl.isOnCourt(player)) {
          _showError('Select a player currently on court.');
          return;
        }
        setState(() => _pendingPick = _PendingPlayerPick.subIn(player));
        return;
      case _PendingPickType.subIn:
        if (_ctrl.isOnCourt(player)) {
          _showError('Select a player from the bench.');
          return;
        }
        await _applyAsync(
          _ctrl.substitute(playerOut: pending.playerOut!, playerIn: player),
        );
        if (!mounted) return;
        if (_ctrl.lastError == null) {
          setState(() => _pendingPick = null);
        }
        return;
    }
    if (!mounted) return;
    setState(() => _pendingPick = null);
  }

  void _selectPeriodFilter(int filter) {
    setState(() {
      _feedPeriodFilter = filter;
      _pendingPick = null;
    });
  }

  Future<void> _advancePeriod() async {
    await _applyAsync(_ctrl.advancePeriod());
    if (!mounted) return;
    setState(() => _feedPeriodFilter = _ctrl.period);
  }

  int get _effectiveFeedPeriodFilter {
    final options = GameStatsLiveController.coveredPeriodFilters(_ctrl.period);
    if (options.contains(_feedPeriodFilter)) return _feedPeriodFilter;
    return _ctrl.period;
  }

  Future<void> _openMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DarColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assessment_outlined, color: DarColors.accentRed),
              title: const Text('View game report', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: DarColors.accentRed),
              title: const Text('Toggle game clock', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'clock'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'report') {
      await _openGameReport();
    } else if (action == 'clock') {
      await _applyAsync(_ctrl.toggleClock());
    }
  }

  Future<void> _toggleClock() => _applyAsync(_ctrl.toggleClock());

  Future<void> _openGameReport() async {
    if (!mounted) return;
    await GameStatsGameReportScreen.show(context, controller: _ctrl);
  }

  Future<void> _undo() => _applyAsync(_ctrl.undo());

  Future<void> _editClock() async {
    final result = await showDialog<Duration>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: _ClockEditSheet(initial: _ctrl.clockRemaining),
      ),
    );
    if (result == null || !mounted) return;
    await _applyAsync(_ctrl.setClock(result));
  }

  Future<void> _enterConsoleMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitConsoleMode() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _leaveConsole() async {
    await _exitConsoleMode();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveConsole();
      },
      child: GameStatsLandscapeViewport(
        child: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            final layout = DarLayoutMetrics.of(context);
            final buttonSize = (media.size.height * 0.155).clamp(42.0, 58.0);
            final edgePad = layout.isTablet ? 16.0 : 10.0;

            return Scaffold(
              backgroundColor: DarColors.background,
              body: Stack(
                children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    DarColors.accentRed.withValues(alpha: 0.14),
                    DarColors.background,
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DarColors.accentRed.withValues(alpha: 0.08),
                    Colors.transparent,
                    DarColors.cardDark.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(edgePad, 6, edgePad, 8),
                child: Column(
                  children: [
                    _TopBar(
                      teamScore: _ctrl.teamScore,
                      livePulse: _livePulse,
                      onBack: _leaveConsole,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 28,
                            child: _ConsolePanel(
                              title: 'SCORING',
                              child: _LeftScoringPanel(
                                buttonSize: buttonSize,
                                onMiss: (kind) => _beginScore(kind, missed: true),
                                onMade: (kind) => _beginScore(kind, missed: false),
                                onMenu: _openMenu,
                                onUndo: _undo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 36,
                            child: _ConsolePanel(
                              title: 'MATCH CENTER',
                              child: _CenterPanel(
                                feed: _ctrl.filteredFeed(_effectiveFeedPeriodFilter),
                                periodFilter: _effectiveFeedPeriodFilter,
                                currentPeriod: _ctrl.period,
                                livePeriodLabel: _ctrl.periodLabel,
                                clockLabel: _ctrl.clockLabel,
                                clockRunning: _ctrl.clockRunning,
                                onPeriodSelected: _selectPeriodFilter,
                                onAdvancePeriod: _advancePeriod,
                                onEditClock: _editClock,
                                onToggleClock: _toggleClock,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 28,
                            child: _ConsolePanel(
                              title: 'ACTIONS',
                              child: _RightActionsPanel(
                                buttonSize: buttonSize,
                                onAction: _beginStat,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_pendingPick != null)
              Positioned.fill(
                child: _FullScreenPlayerPicker(
                  pick: _pendingPick!,
                  controller: _ctrl,
                  onPick: _onPlayerPicked,
                  onCancel: _cancelPendingPick,
                ),
              ),
            if (_busy || _refreshingPicker)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x44000000),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DarColors.accentRed,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.teamScore,
    required this.livePulse,
    required this.onBack,
  });

  final int teamScore;
  final Animation<double> livePulse;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PrevButton(onTap: onBack),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: livePulse,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: DarColors.accentRed.withValues(alpha: 0.12 + livePulse.value * 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarColors.accentRed.withValues(alpha: 0.45 + livePulse.value * 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DarColors.accentRed.withValues(alpha: 0.7 + livePulse.value * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: DarColors.accentRed.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: DarColors.accentRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DC',
                style: TextStyle(
                  color: DarColors.accentRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'GOALS',
                style: TextStyle(
                  color: DarColors.muted.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$teamScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'GAME STATS',
          style: TextStyle(
            color: DarColors.muted.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarColors.cardDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              title,
              style: TextStyle(
                color: DarColors.muted.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: child)),
        ],
      ),
    );
  }
}

class _LeftScoringPanel extends StatelessWidget {
  const _LeftScoringPanel({
    required this.buttonSize,
    required this.onMiss,
    required this.onMade,
    required this.onMenu,
    required this.onUndo,
  });

  final double buttonSize;
  final ValueChanged<LiveStatKind> onMiss;
  final ValueChanged<LiveStatKind> onMade;
  final VoidCallback onMenu;
  final VoidCallback onUndo;

  static const _pointTypes = <(String, LiveStatKind)>[
    ('2pt', LiveStatKind.score2),
    ('3pt', LiveStatKind.score3),
    ('1pt', LiveStatKind.score1),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ScoringStrip(
                  label: 'MISS',
                  color: DarColors.accentRed,
                  buttonSize: buttonSize,
                  buttons: _pointTypes,
                  onTap: onMiss,
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: DarColors.muted.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _ScoringStrip(
                  label: 'MADE',
                  color: Colors.white,
                  buttonSize: buttonSize,
                  buttons: _pointTypes,
                  onTap: onMade,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: DarColors.muted.withValues(alpha: 0.12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _ToolButton(icon: Icons.menu_rounded, label: 'Menu', onTap: onMenu),
            const SizedBox(width: 8),
            _ToolButton(icon: Icons.undo_rounded, label: 'Undo', onTap: onUndo),
          ],
        ),
      ],
    );
  }
}

class _ScoringStrip extends StatelessWidget {
  const _ScoringStrip({
    required this.label,
    required this.color,
    required this.buttonSize,
    required this.buttons,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double buttonSize;
  final List<(String, LiveStatKind)> buttons;
  final ValueChanged<LiveStatKind> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final entry in buttons)
                _CircleStatButton(
                  label: entry.$1,
                  color: color,
                  size: buttonSize,
                  onTap: () => onTap(entry.$2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterPanel extends StatelessWidget {
  const _CenterPanel({
    required this.feed,
    required this.periodFilter,
    required this.currentPeriod,
    required this.livePeriodLabel,
    required this.clockLabel,
    required this.clockRunning,
    required this.onPeriodSelected,
    required this.onAdvancePeriod,
    required this.onEditClock,
    required this.onToggleClock,
  });

  final List<LiveStatEvent> feed;
  final int periodFilter;
  final int currentPeriod;
  final String livePeriodLabel;
  final String clockLabel;
  final bool clockRunning;
  final ValueChanged<int> onPeriodSelected;
  final VoidCallback onAdvancePeriod;
  final VoidCallback onEditClock;
  final VoidCallback onToggleClock;

  String get _emptyLabel {
    final tab = GameStatsLiveController.filterTabLabel(periodFilter);
    return 'No events in $tab yet';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: DarColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
            ),
            child: feed.isEmpty
                ? Center(
                    child: Text(
                      _emptyLabel,
                      style: TextStyle(color: DarColors.muted.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: feed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) => _PlayFeedRow(
                      event: feed[index],
                      highlight: index == 0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PeriodDropdownChip(
              value: periodFilter,
              currentPeriod: currentPeriod,
              onSelected: onPeriodSelected,
            ),
            const SizedBox(width: 6),
            _NextPeriodButton(
              livePeriodLabel: livePeriodLabel,
              onTap: onAdvancePeriod,
            ),
            const SizedBox(width: 8),
            _ClockChip(
              label: clockLabel,
              wide: true,
              mono: true,
              running: clockRunning,
            ),
            const SizedBox(width: 6),
            _ToolButton(
              icon: clockRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: onToggleClock,
              compact: true,
              active: clockRunning,
            ),
            const SizedBox(width: 4),
            _ToolButton(icon: Icons.edit_outlined, onTap: onEditClock, compact: true),
          ],
        ),
      ],
    );
  }
}

class _NextPeriodButton extends StatelessWidget {
  const _NextPeriodButton({
    required this.livePeriodLabel,
    required this.onTap,
  });

  final String livePeriodLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                livePeriodLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.skip_next_rounded, color: DarColors.accentRed, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodDropdownChip extends StatefulWidget {
  const _PeriodDropdownChip({
    required this.value,
    required this.currentPeriod,
    required this.onSelected,
  });

  final int value;
  final int currentPeriod;
  final ValueChanged<int> onSelected;

  @override
  State<_PeriodDropdownChip> createState() => _PeriodDropdownChipState();
}

class _PeriodDropdownChipState extends State<_PeriodDropdownChip> {
  final _chipKey = GlobalKey();

  List<int> get _options =>
      GameStatsLiveController.coveredPeriodFilters(widget.currentPeriod);

  Future<void> _openMenu() async {
    final box = _chipKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;

    final options = _options;
    if (options.isEmpty) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    const itemHeight = 30.0;
    final labels = options.map(GameStatsLiveController.filterTabLabel).toList();
    final longest = labels.fold<int>(0, (max, label) => label.length > max ? label.length : max);
    final menuWidth = (longest * 8.0 + 20).clamp(52.0, 80.0);
    final menuHeight = options.length * itemHeight + 10;

    final picked = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (dialogContext) {
        final screenH = MediaQuery.sizeOf(dialogContext).height;
        final left = offset.dx + (size.width - menuWidth) / 2;
        final top = (offset.dy - menuHeight - 6).clamp(8.0, screenH - menuHeight - 8);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.35)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: menuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: DarColors.cardDark.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < options.length; i++)
                        _PeriodMenuItem(
                          label: labels[i],
                          selected: options[i] == widget.value,
                          onTap: () => Navigator.pop(dialogContext, options[i]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (picked == null || !mounted) return;
    widget.onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = GameStatsLiveController.filterTabLabel(widget.value);
    final fontSize = label.length > 2 ? 8.0 : 10.0;

    return Material(
      key: _chipKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: _openMenu,
        customBorder: const CircleBorder(),
        splashColor: DarColors.accentRed.withValues(alpha: 0.15),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DarColors.accentRed.withValues(alpha: 0.14),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: 0.12),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: DarColors.accentRed,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodMenuItem extends StatelessWidget {
  const _PeriodMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? DarColors.accentRed.withValues(alpha: 0.18) : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : DarColors.muted.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenPlayerPicker extends StatelessWidget {
  const _FullScreenPlayerPicker({
    required this.pick,
    required this.controller,
    required this.onPick,
    required this.onCancel,
  });

  final _PendingPlayerPick pick;
  final GameStatsLiveController controller;
  final ValueChanged<Person> onPick;
  final VoidCallback onCancel;

  bool _canSelect(Person player) {
    return switch (pick.type) {
      _PendingPickType.score || _PendingPickType.stat => controller.isOnCourt(player),
      _PendingPickType.subOut => controller.isOnCourt(player),
      _PendingPickType.subIn => !controller.isOnCourt(player),
    };
  }

  Color _accentFor(Person player) {
    if (pick.isSub) {
      if (pick.type == _PendingPickType.subIn && pick.playerOut?.id == player.id) {
        return DarColors.muted;
      }
      return controller.isOnCourt(player) ? DarColors.accentRed : Colors.white;
    }
    return pick.missed ? DarColors.accentRed : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final accent = pick.isSub
        ? DarColors.accentRed
        : (pick.missed ? DarColors.accentRed : Colors.white);
    final onCourt = controller.onCourt;
    final bench = controller.benchPlayers;
    final useRosterLayout = pick.isSub;

    return Material(
      color: DarColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DarColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DarColors.muted.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pick.title,
                              style: TextStyle(
                                color: accent,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pick.subtitle,
                              style: TextStyle(
                                color: DarColors.muted.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: useRosterLayout
                        ? _RosterPickScroll(
                            onCourt: onCourt,
                            bench: bench,
                            canSelect: _canSelect,
                            accentFor: _accentFor,
                            onPick: onPick,
                          )
                        : _OnCourtPickGrid(
                            players: onCourt,
                            accent: accent,
                            missed: pick.missed,
                            onPick: onPick,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnCourtPickGrid extends StatelessWidget {
  const _OnCourtPickGrid({
    required this.players,
    required this.accent,
    required this.missed,
    required this.onPick,
  });

  final List<Person> players;
  final Color accent;
  final bool missed;
  final ValueChanged<Person> onPick;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text('No players on court', style: TextStyle(color: DarColors.muted.withValues(alpha: 0.8))),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) => _PlayerPickCard(
        player: players[index],
        accent: accent,
        highlighted: true,
        onTap: () => onPick(players[index]),
      ),
    );
  }
}

class _RosterPickScroll extends StatelessWidget {
  const _RosterPickScroll({
    required this.onCourt,
    required this.bench,
    required this.canSelect,
    required this.accentFor,
    required this.onPick,
  });

  final List<Person> onCourt;
  final List<Person> bench;
  final bool Function(Person) canSelect;
  final Color Function(Person) accentFor;
  final ValueChanged<Person> onPick;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _SectionLabel(title: 'ON COURT', count: onCourt.length)),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final player = onCourt[index];
                final selectable = canSelect(player);
                return _PlayerPickCard(
                  player: player,
                  accent: accentFor(player),
                  highlighted: selectable,
                  showLiveBadge: true,
                  enabled: selectable,
                  onTap: selectable ? () => onPick(player) : null,
                );
              },
              childCount: onCourt.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _SectionLabel(title: 'BENCH', count: bench.length)),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final player = bench[index];
              final selectable = canSelect(player);
              return _PlayerPickCard(
                player: player,
                accent: accentFor(player),
                highlighted: selectable,
                enabled: selectable,
                onTap: selectable ? () => onPick(player) : null,
              );
            },
            childCount: bench.length,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: DarColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPickCard extends StatelessWidget {
  const _PlayerPickCard({
    required this.player,
    required this.accent,
    this.highlighted = false,
    this.showLiveBadge = false,
    this.enabled = true,
    this.onTap,
  });

  final Person player;
  final Color accent;
  final bool highlighted;
  final bool showLiveBadge;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.38;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarColors.cardDark.withValues(alpha: 0.95),
                  DarColors.surface.withValues(alpha: enabled ? 0.85 : 0.5),
                ],
              ),
              border: Border.all(
                color: highlighted
                    ? accent.withValues(alpha: enabled ? 0.7 : 0.25)
                    : DarColors.muted.withValues(alpha: 0.15),
                width: highlighted ? 1.8 : 1,
              ),
              boxShadow: highlighted && enabled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    GameStatsPlayerAvatar(
                      player: player,
                      size: 52,
                      highlighted: highlighted && enabled,
                      ringColor: accent,
                    ),
                    if (player.jerseyNumber != null)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: DarColors.accentRed,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${player.jerseyNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (showLiveBadge)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: DarColors.accentRed.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  player.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (player.position.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    player.position.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayFeedRow extends StatelessWidget {
  const _PlayFeedRow({required this.event, this.highlight = false});

  final LiveStatEvent event;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final statColor = event.isMiss ? DarColors.accentRed : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? DarColors.accentRed.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? DarColors.accentRed.withValues(alpha: 0.25)
              : DarColors.muted.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: statColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event.stat,
              style: TextStyle(
                color: statColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.periodLabel,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.95),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  event.clockLabel,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.75),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          if (event.count != null)
            Text(
              '(${event.count})',
              style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 11),
            ),
        ],
      ),
    );
  }
}

enum _PendingPickType { score, stat, subOut, subIn }

class _PendingPlayerPick {
  const _PendingPlayerPick._(
    this.type,
    this.kind, {
    this.missed = false,
    this.playerOut,
  });

  const _PendingPlayerPick.score(LiveStatKind kind, {required bool missed})
      : this._(_PendingPickType.score, kind, missed: missed);
  const _PendingPlayerPick.stat(LiveStatKind kind) : this._(_PendingPickType.stat, kind);
  const _PendingPlayerPick.subOut() : this._(_PendingPickType.subOut, null);
  const _PendingPlayerPick.subIn(Person playerOut)
      : this._(_PendingPickType.subIn, null, playerOut: playerOut);

  final _PendingPickType type;
  final LiveStatKind? kind;
  final bool missed;
  final Person? playerOut;

  bool get isSub => type == _PendingPickType.subOut || type == _PendingPickType.subIn;

  String get title => switch (type) {
        _PendingPickType.score => switch (kind) {
            LiveStatKind.score3 => missed ? '3PT Missed' : '3PT Scored',
            LiveStatKind.score2 => missed ? '2PT Missed' : '2PT Scored',
            LiveStatKind.score1 => missed ? 'Free Throw Missed' : 'Free Throw Scored',
            _ => 'Select player',
          },
        _PendingPickType.stat => switch (kind) {
            LiveStatKind.defReb => 'Defensive Rebound',
            LiveStatKind.offReb => 'Offensive Rebound',
            LiveStatKind.turnover => 'Turnover',
            LiveStatKind.steal => 'Steal',
            LiveStatKind.assist => 'Assist',
            LiveStatKind.block => 'Block',
            LiveStatKind.foul => 'Foul',
            _ => 'Select player',
          },
        _PendingPickType.subOut => 'Substitution',
        _PendingPickType.subIn => 'Substitution',
      };

  String get subtitle => switch (type) {
        _PendingPickType.score || _PendingPickType.stat => 'Tap the on-court player',
        _PendingPickType.subOut => 'Step 1 — select player leaving the court',
        _PendingPickType.subIn =>
          'Step 2 — sub in for ${GameStatsLiveController.shortPlayerName(playerOut!)}',
      };
}

class _RightActionsPanel extends StatelessWidget {
  const _RightActionsPanel({
    required this.buttonSize,
    required this.onAction,
  });

  final double buttonSize;
  final ValueChanged<LiveStatKind> onAction;

  static const _rows = [
    (
      _ActionButtonData('def reb', Colors.white, LiveStatKind.defReb),
      _ActionButtonData('off reb', Colors.white, LiveStatKind.offReb),
    ),
    (
      _ActionButtonData('to', Colors.white, LiveStatKind.turnover),
      _ActionButtonData('stl', Colors.white, LiveStatKind.steal),
    ),
    (
      _ActionButtonData('asst', Colors.white, LiveStatKind.assist),
      _ActionButtonData('blk', Colors.white, LiveStatKind.block),
    ),
    (
      _ActionButtonData('sub', DarColors.accentRed, LiveStatKind.sub, oval: true),
      _ActionButtonData('foul', Colors.white, LiveStatKind.foul, oval: true),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final row in _rows)
          Row(
            children: [
              Expanded(child: Center(child: _ActionButton(data: row.$1, size: buttonSize, onAction: onAction))),
              const SizedBox(width: 8),
              Expanded(child: Center(child: _ActionButton(data: row.$2, size: buttonSize, onAction: onAction))),
            ],
          ),
      ],
    );
  }
}

class _ActionButtonData {
  const _ActionButtonData(this.label, this.color, this.kind, {this.oval = false});

  final String label;
  final Color color;
  final LiveStatKind kind;
  final bool oval;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.data,
    required this.size,
    required this.onAction,
  });

  final _ActionButtonData data;
  final double size;
  final ValueChanged<LiveStatKind> onAction;

  @override
  Widget build(BuildContext context) {
    if (data.oval) {
      return _OvalStatButton(
        label: data.label,
        color: data.color,
        size: size,
        onTap: () => onAction(data.kind),
      );
    }
    return _CircleStatButton(
      label: data.label,
      color: data.color,
      size: size,
      onTap: () => onAction(data.kind),
    );
  }
}

class _CircleStatButton extends StatelessWidget {
  const _CircleStatButton({
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRed = color == DarColors.accentRed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isRed ? 0.08 : 0.04),
            border: Border.all(color: color.withValues(alpha: 0.85), width: 1.5),
            boxShadow: isRed
                ? [BoxShadow(color: DarColors.accentRed.withValues(alpha: 0.12), blurRadius: 10)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: (size * 0.17).clamp(9.0, 12.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OvalStatButton extends StatelessWidget {
  const _OvalStatButton({
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRed = color == DarColors.accentRed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        splashColor: color.withValues(alpha: 0.15),
        child: Ink(
          width: size * 1.12,
          height: size * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            color: color.withValues(alpha: isRed ? 0.1 : 0.04),
            border: Border.all(color: color.withValues(alpha: 0.85), width: 1.5),
            boxShadow: isRed
                ? [BoxShadow(color: DarColors.accentRed.withValues(alpha: 0.14), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: (size * 0.16).clamp(9.0, 11.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockChip extends StatelessWidget {
  const _ClockChip({
    required this.label,
    this.wide = false,
    this.mono = false,
    this.running = false,
  });

  final String label;
  final bool wide;
  final bool mono;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 9, vertical: 6),
      decoration: BoxDecoration(
        color: running
            ? DarColors.accentRed.withValues(alpha: 0.15)
            : DarColors.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: running
              ? DarColors.accentRed.withValues(alpha: 0.5)
              : DarColors.muted.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: wide ? 12 : 11,
          fontFamily: mono ? 'monospace' : null,
          letterSpacing: mono ? 0.5 : 0,
        ),
      ),
    );
  }
}

class _PrevButton extends StatelessWidget {
  const _PrevButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: DarColors.surface.withValues(alpha: 0.8),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: DarColors.accentRed, size: 16),
              SizedBox(width: 4),
              Text(
                'Prev',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.compact = false,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool compact;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? DarColors.accentRed : DarColors.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: active
                ? DarColors.accentRed.withValues(alpha: 0.12)
                : DarColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? DarColors.accentRed.withValues(alpha: 0.45)
                  : DarColors.muted.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: compact ? 16 : 18),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockEditSheet extends StatefulWidget {
  const _ClockEditSheet({required this.initial});

  final Duration initial;

  static const _presets = <Duration>[
    Duration(minutes: 10),
    Duration(minutes: 8),
    Duration(minutes: 5),
    Duration(minutes: 2),
    Duration(minutes: 1),
    Duration(seconds: 30),
  ];

  @override
  State<_ClockEditSheet> createState() => _ClockEditSheetState();
}

class _ClockEditSheetState extends State<_ClockEditSheet> {
  late Duration _draft;
  int _pickerKey = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _setPreset(Duration value) {
    setState(() {
      _draft = value;
      _pickerKey++;
    });
  }

  String _presetLabel(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (m > 0 && s > 0) return '$m:${s.toString().padLeft(2, '0')}';
    if (m > 0) return '$m:00';
    return '0:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: DarColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: DarColors.accentRed, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Set game clock',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: DarColors.muted.withValues(alpha: 0.9)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final preset in _ClockEditSheet._presets)
                  _ClockPresetChip(
                    label: _presetLabel(preset),
                    selected: _draft == preset,
                    onTap: () => _setPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    pickerTextStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: CupertinoTimerPicker(
                  key: ValueKey(_pickerKey),
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: _draft,
                  minuteInterval: 1,
                  secondInterval: 1,
                  onTimerDurationChanged: (value) => _draft = value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DarColors.muted,
                      side: BorderSide(color: DarColors.muted.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _draft),
                    style: FilledButton.styleFrom(
                      backgroundColor: DarColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPresetChip extends StatelessWidget {
  const _ClockPresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? DarColors.accentRed.withValues(alpha: 0.2)
                : DarColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : DarColors.muted.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
