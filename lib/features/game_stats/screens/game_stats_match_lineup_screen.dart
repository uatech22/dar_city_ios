import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/game_stats/debug/game_stats_lineup_debug_log.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_match_lineup_context.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_session.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_starting_lineup_screen.dart';
import 'package:dar_city_app/features/game_stats/services/game_stats_service.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_lineup_widgets.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_quarter_duration_sheet.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:flutter/material.dart';

/// Step 2 — pick match-day squad (5–12 players who dress for this match).
class GameStatsMatchLineupScreen extends StatefulWidget {
  const GameStatsMatchLineupScreen({super.key, required this.match});

  final Game match;

  @override
  State<GameStatsMatchLineupScreen> createState() => _GameStatsMatchLineupScreenState();
}

class _GameStatsMatchLineupScreenState extends State<GameStatsMatchLineupScreen> {
  late Future<GameStatsMatchLineupContext> _lineupContextFuture;
  final Set<int> _selectedIds = {};
  String? _validationMessage;
  Duration _quarterDuration = GameStatsPeriodConfig.regulationPresets.first;
  int _overtimeDurationSeconds = GameStatsPeriodConfig.overtimeSeconds;
  bool _appliedApiQuarterDuration = false;

  @override
  void initState() {
    super.initState();
    _lineupContextFuture = GameStatsService.fetchMatchLineupContext(widget.match.id)
        .then((context) {
      if (mounted &&
          !_appliedApiQuarterDuration &&
          context.quarterDurationSeconds > 0) {
        setState(() {
          _appliedApiQuarterDuration = true;
          _quarterDuration = context.quarterDuration;
          _overtimeDurationSeconds = context.overtimeDurationSeconds;
        });
      }
      return context;
    });
  }

  void _togglePlayer(Person player) {
    setState(() {
      _validationMessage = null;
      if (_selectedIds.contains(player.id)) {
        _selectedIds.remove(player.id);
      } else if (_selectedIds.length >= GameStatsSession.maxMatchLineup) {
        _validationMessage =
            'Match lineup is limited to ${GameStatsSession.maxMatchLineup} players — remove someone first.';
      } else {
        _selectedIds.add(player.id);
      }
    });
  }

  void _continue(List<Person> fullRoster) {
    final count = _selectedIds.length;
    if (count < GameStatsSession.minMatchLineup) {
      setState(() {
        _validationMessage =
            'Pick at least ${GameStatsSession.minMatchLineup} players for this match (${GameStatsSession.minMatchLineup}–${GameStatsSession.maxMatchLineup}).';
      });
      return;
    }

    final matchLineup = fullRoster.where((p) => _selectedIds.contains(p.id)).toList();

    GameStatsLineupDebugLog.logMatchLineupSelected(
      matchId: widget.match.id,
      matchLineup: matchLineup,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameStatsStartingLineupScreen(
          match: widget.match,
          matchLineup: matchLineup,
          quarterDurationSeconds: _quarterDuration.inSeconds,
          overtimeDurationSeconds: _overtimeDurationSeconds,
        ),
      ),
    );
  }

  Future<void> _pickQuarterDuration() async {
    final picked = await GameStatsQuarterDurationSheet.show(
      context,
      initial: _quarterDuration,
    );
    if (picked != null && mounted) {
      setState(() => _quarterDuration = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedIds.length;
    final ready = count >= GameStatsSession.minMatchLineup &&
        count <= GameStatsSession.maxMatchLineup;

    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        SafeArea(
        child: FeatureAsyncBody<GameStatsMatchLineupContext>(
          future: _lineupContextFuture,
          onRetry: () {
            setState(() {
              _appliedApiQuarterDuration = false;
              _lineupContextFuture =
                  GameStatsService.fetchMatchLineupContext(widget.match.id).then((context) {
                if (mounted &&
                    !_appliedApiQuarterDuration &&
                    context.quarterDurationSeconds > 0) {
                  setState(() {
                    _appliedApiQuarterDuration = true;
                    _quarterDuration = context.quarterDuration;
                    _overtimeDurationSeconds = context.overtimeDurationSeconds;
                  });
                }
                return context;
              });
            });
          },
          builder: (context, lineupContext) {
            final roster = lineupContext.players;
            final layout = DarLayoutMetrics.of(context);
            final crossAxisCount = layout.lineupGridColumns;
            final h = layout.horizontalPadding;

            return Column(
              children: [
                GameStatsLineupHeader(
                  match: widget.match,
                  title: 'Match Lineup',
                  hint: 'Who is dressed and available for this game?',
                  selectionLabel: '$count / ${GameStatsSession.minMatchLineup}–${GameStatsSession.maxMatchLineup} selected',
                  ready: ready,
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () => _continue(roster),
                ),
                if (_validationMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(h, 0, h, 8),
                    child: GameStatsLineupValidationBanner(message: _validationMessage!),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(h, 0, h, 8),
                  child: _QuarterDurationBar(
                    duration: _quarterDuration,
                    onTap: _pickQuarterDuration,
                  ),
                ),
                Expanded(
                  child: roster.isEmpty
                      ? const GameStatsLineupEmptyRoster(
                          message: 'No players on this match roster',
                          subtitle: 'Add squad players first, then return to set the match lineup.',
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
                            return GameStatsLineupPlayerCard(
                              player: player,
                              selected: _selectedIds.contains(player.id),
                              onTap: () => _togglePlayer(player),
                            );
                          },
                        ),
                ),
                GameStatsLineupSelectionFooter(
                  label: ready
                      ? 'Match lineup ready — set your starting five next'
                      : 'Select ${GameStatsSession.minMatchLineup}–${GameStatsSession.maxMatchLineup} players for this match',
                  ready: ready,
                  onContinue: () => _continue(roster),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _QuarterDurationBar extends StatelessWidget {
  const _QuarterDurationBar({
    required this.duration,
    required this.onTap,
  });

  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = GameStatsPeriodConfig.formatDurationLabel(duration);
    return Material(
      color: DarColors.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: DarColors.accentRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quarter length (Q1–Q4)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$label per quarter · OT always 5:00',
                      style: TextStyle(
                        color: DarColors.muted.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: DarColors.accentRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: DarColors.muted.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
