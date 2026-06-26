import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/game_stats/debug/game_stats_lineup_debug_log.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_session.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_live_console_screen.dart';
import 'package:dar_city_app/features/game_stats/services/game_stats_service.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_lineup_widgets.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:flutter/material.dart';

/// Step 3 — from match lineup, pick exactly five starters and one captain.
class GameStatsStartingLineupScreen extends StatefulWidget {
  const GameStatsStartingLineupScreen({
    super.key,
    required this.match,
    required this.matchLineup,
    required this.quarterDurationSeconds,
    this.overtimeDurationSeconds = GameStatsPeriodConfig.overtimeSeconds,
  });

  final Game match;
  final List<Person> matchLineup;
  final int quarterDurationSeconds;
  final int overtimeDurationSeconds;

  @override
  State<GameStatsStartingLineupScreen> createState() =>
      _GameStatsStartingLineupScreenState();
}

class _GameStatsStartingLineupScreenState extends State<GameStatsStartingLineupScreen> {
  final Set<int> _selectedIds = {};
  int? _captainId;
  String? _validationMessage;
  bool _submitting = false;

  void _togglePlayer(Person player) {
    setState(() {
      _validationMessage = null;
      if (_selectedIds.contains(player.id)) {
        _selectedIds.remove(player.id);
        if (_captainId == player.id) _captainId = null;
      } else if (_selectedIds.length < GameStatsSession.requiredStarters) {
        _selectedIds.add(player.id);
      } else {
        _validationMessage =
            'Starting five is exactly ${GameStatsSession.requiredStarters} players — tap someone to deselect first.';
      }
    });
  }

  void _setCaptain(Person player) {
    if (!_selectedIds.contains(player.id)) return;
    setState(() {
      _validationMessage = null;
      _captainId = player.id;
    });
  }

  Future<void> _submit() async {
    final count = _selectedIds.length;
    if (count < GameStatsSession.requiredStarters) {
      setState(() {
        _validationMessage =
            'Pick ${GameStatsSession.requiredStarters - count} more starter${GameStatsSession.requiredStarters - count == 1 ? '' : 's'} — you need exactly ${GameStatsSession.requiredStarters}.';
      });
      return;
    }
    if (_captainId == null) {
      setState(() {
        _validationMessage = 'Choose a captain from your starting five (tap SET CAPTAIN on a starter).';
      });
      return;
    }

    setState(() {
      _validationMessage = null;
      _submitting = true;
    });

    try {
      final active = await GameStatsService.fetchActiveSession(widget.match.id);
      if (active != null) {
        final apiSession = await GameStatsService.fetchSession(active.sessionId);
        if (!mounted) return;
        final starters =
            widget.matchLineup.where((p) => _selectedIds.contains(p.id)).toList();
        final resumeSession = GameStatsSession(
          match: widget.match,
          startingFive: starters.isNotEmpty ? starters : apiSession.onCourt,
          roster: widget.matchLineup,
          captainPlayerId: _captainId,
          apiSessionId: apiSession.id,
          apiSnapshot: apiSession,
          quarterDurationSeconds: apiSession.regulationPeriodSeconds,
          overtimeDurationSeconds: apiSession.overtimeDurationSeconds,
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameStatsLiveConsoleScreen(session: resumeSession),
          ),
        );
        return;
      }

      final matchLineupIds = widget.matchLineup.map((p) => p.id).toList();
      final starterIds = _selectedIds.toList();

      GameStatsLineupDebugLog.logCreateSessionRequest(
        matchId: widget.match.id,
        matchLineupPlayerIds: matchLineupIds,
        startingFivePlayerIds: starterIds,
        captainPlayerId: _captainId!,
        quarterDurationSeconds: widget.quarterDurationSeconds,
        matchLineupPlayers: widget.matchLineup,
      );

      final apiSession = await GameStatsService.createSession(
        matchId: widget.match.id,
        matchLineupPlayerIds: matchLineupIds,
        startingFivePlayerIds: starterIds,
        captainPlayerId: _captainId!,
        quarterDurationSeconds: widget.quarterDurationSeconds,
      );

      if (!mounted) return;
      final starters =
          widget.matchLineup.where((p) => _selectedIds.contains(p.id)).toList();
      final session = GameStatsSession(
        match: widget.match,
        startingFive: starters,
        roster: widget.matchLineup,
        captainPlayerId: _captainId,
        apiSessionId: apiSession.id,
        apiSnapshot: apiSession,
        quarterDurationSeconds: widget.quarterDurationSeconds,
        overtimeDurationSeconds: widget.overtimeDurationSeconds,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameStatsLiveConsoleScreen(session: session),
        ),
      );
    } on FeatureApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _validationMessage = e.message?.toString() ?? 'Could not start game stats session.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validationMessage = 'Could not start game stats session. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = widget.matchLineup;
    final count = _selectedIds.length;
    final startersReady = count == GameStatsSession.requiredStarters;
    final ready = startersReady && _captainId != null;
    final layout = DarLayoutMetrics.of(context);
    final crossAxisCount = layout.lineupGridColumns;
    final h = layout.horizontalPadding;

    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                GameStatsLineupHeader(
                  match: widget.match,
                  title: 'Starting Five',
                  hint: 'Pick who starts on court, then choose a captain.',
                  selectionLabel: startersReady
                      ? (_captainId != null
                          ? '$count / ${GameStatsSession.requiredStarters} · Captain set'
                          : '$count / ${GameStatsSession.requiredStarters} · Pick captain')
                      : '$count / ${GameStatsSession.requiredStarters} selected',
                  ready: ready,
                  onCancel: () => Navigator.pop(context),
                  onConfirm: _submit,
                ),
                if (_validationMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(h, 0, h, 8),
                    child: GameStatsLineupValidationBanner(message: _validationMessage!),
                  ),
                Expanded(
                  child: roster.isEmpty
                      ? const GameStatsLineupEmptyRoster(
                          message: 'No players in match lineup',
                          subtitle: 'Go back and select your match lineup first.',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(h, 8, h, 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: roster.length,
                          itemBuilder: (context, index) {
                            final player = roster[index];
                            final selected = _selectedIds.contains(player.id);
                            final isCaptain = _captainId == player.id;
                            return GameStatsLineupPlayerCard(
                              player: player,
                              selected: selected,
                              isCaptain: isCaptain,
                              showCaptainAction: selected && !isCaptain,
                              onTap: () => _togglePlayer(player),
                              onCaptainTap: () => _setCaptain(player),
                            );
                          },
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(h, 12, h, 12 + MediaQuery.paddingOf(context).bottom),
                  decoration: BoxDecoration(
                    color: DarColors.navBar,
                    border: Border(top: BorderSide(color: DarColors.muted.withValues(alpha: 0.12))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ready
                            ? 'Lineup locked in — tap Continue to open the live stats console'
                            : startersReady
                                ? 'Tap SET CAPTAIN on one of your five starters'
                                : 'Tap players to select exactly ${GameStatsSession.requiredStarters} starters from the match lineup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: ready ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: DarColors.accentRed,
                            disabledBackgroundColor: DarColors.cardDark,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: DarColors.muted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: ready
                                    ? DarColors.accentRed
                                    : DarColors.muted.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Continue to Live Stats',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_submitting)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
