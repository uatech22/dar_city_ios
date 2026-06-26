import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/game_stats/controllers/game_stats_live_controller.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_report.dart';
import 'package:dar_city_app/features/game_stats/widgets/game_stats_player_avatar.dart';
import 'package:flutter/material.dart';

/// In-game Dar City box score — opened from the live console menu.
class GameStatsGameReportScreen extends StatefulWidget {
  const GameStatsGameReportScreen({super.key, required this.controller});

  final GameStatsLiveController controller;

  static Future<void> show(
    BuildContext context, {
    required GameStatsLiveController controller,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close game report',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) => GameStatsGameReportScreen(controller: controller),
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GameStatsGameReportScreen> createState() => _GameStatsGameReportScreenState();
}

class _GameStatsGameReportScreenState extends State<GameStatsGameReportScreen> {
  late int _periodFilter;
  late GameStatsGameReport _report;

  @override
  void initState() {
    super.initState();
    _periodFilter = widget.controller.period;
    _report = widget.controller.buildGameReport(forPeriod: _periodFilter);
  }

  void _selectPeriod(int period) {
    setState(() {
      _periodFilter = period;
      _report = widget.controller.buildGameReport(forPeriod: period);
    });
  }

  @override
  Widget build(BuildContext context) {
    final match = _report.match;
    final totals = _report.teamTotals;
    final activePlayers = _report.players.where((r) => r.hasStats).toList();
    final periodOptions =
        GameStatsLiveController.coveredPeriodFilters(widget.controller.period);

    final metrics = DarLayoutMetrics.of(context);
    final screen = MediaQuery.sizeOf(context);
    final maxDialogWidth = metrics.contentWidthFor(screen.width, cap: 920);
    final maxDialogHeight = (screen.height * 0.88).clamp(420.0, 640.0);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth, maxHeight: maxDialogHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
                vertical: 10,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DarColors.cardDark.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ReportHeader(
                      report: _report,
                      matchDate: '${match.date} · ${match.time}',
                      venue: match.venue,
                      periodOptions: periodOptions,
                      periodFilter: _periodFilter,
                      onPeriodSelected: _selectPeriod,
                      onClose: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: _TeamSummaryStrip(totals: totals),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: activePlayers.isEmpty
                            ? Center(
                                child: Text(
                                  'No stats in ${GameStatsPeriodConfig.feedFilterLabel(_periodFilter)} yet.\nLog scoring and actions during this period.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: DarColors.muted.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              )
                            : _PlayerStatsTable(rows: activePlayers),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({
    required this.report,
    required this.matchDate,
    required this.venue,
    required this.periodOptions,
    required this.periodFilter,
    required this.onPeriodSelected,
    required this.onClose,
  });

  final GameStatsGameReport report;
  final String matchDate;
  final String venue;
  final List<int> periodOptions;
  final int periodFilter;
  final ValueChanged<int> onPeriodSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment_outlined, size: 16, color: DarColors.accentRed.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    const Text(
                      'GAME REPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'DC vs ${report.opponentLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  matchDate,
                  style: TextStyle(color: DarColors.muted.withValues(alpha: 0.85), fontSize: 11),
                ),
                if (venue.isNotEmpty && venue != 'TBD')
                  Text(
                    venue,
                    style: TextStyle(color: DarColors.muted.withValues(alpha: 0.7), fontSize: 10),
                  ),
              ],
            ),
          ),
          _ScoreBadge(
            score: report.teamScore,
            periodLabel: GameStatsPeriodConfig.feedFilterLabel(periodFilter),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(height: 4),
              _ReportPeriodPicker(
                options: periodOptions,
                value: periodFilter,
                onSelected: onPeriodSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportPeriodPicker extends StatelessWidget {
  const _ReportPeriodPicker({
    required this.options,
    required this.value,
    required this.onSelected,
  });

  final List<int> options;
  final int value;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'View stats by period',
      initialValue: value,
      onSelected: onSelected,
      color: DarColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.35)),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<int>(
            value: option,
            child: Text(
              GameStatsPeriodConfig.feedFilterLabel(option),
              style: TextStyle(
                color: option == value ? DarColors.accentRed : Colors.white,
                fontWeight: option == value ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DarColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              GameStatsPeriodConfig.feedFilterLabel(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: DarColors.muted.withValues(alpha: 0.9),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.periodLabel,
  });

  final int score;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            periodLabel,
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: DarColors.accentRed,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'PTS',
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.75),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSummaryStrip extends StatelessWidget {
  const _TeamSummaryStrip({required this.totals});

  final GameStatsTeamTotals totals;

  @override
  Widget build(BuildContext context) {
    final fgPct = totals.fgPct ?? '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DarColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _SummaryChip(label: 'FG', value: '${totals.fgMade}/${totals.fgAtt}', sub: fgPct),
          _SummaryChip(label: 'FT', value: '${totals.ftMade}/${totals.ftAtt}'),
          _SummaryChip(label: 'REB', value: '${totals.rebounds}'),
          _SummaryChip(label: 'AST', value: '${totals.assists}'),
          _SummaryChip(label: 'STL', value: '${totals.steals}'),
          _SummaryChip(label: 'BLK', value: '${totals.blocks}'),
          _SummaryChip(label: 'TO', value: '${totals.turnovers}'),
          _SummaryChip(label: 'FOUL', value: '${totals.fouls}'),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DarColors.cardDark.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(width: 4),
            Text(
              sub!,
              style: TextStyle(
                color: DarColors.accentRed.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerStatsTable extends StatelessWidget {
  const _PlayerStatsTable({required this.rows});

  final List<GameStatsPlayerReportRow> rows;

  static const _columns = [
    _Col('PTS', 34),
    _Col('FG', 42),
    _Col('FT', 38),
    _Col('REB', 34),
    _Col('AST', 34),
    _Col('STL', 30),
    _Col('BLK', 30),
    _Col('TO', 28),
    _Col('F', 24),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DarColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _TableHeader(columns: _columns),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: rows.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: DarColors.muted.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) => _PlayerRow(
                row: rows[index],
                columns: _columns,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Col {
  const _Col(this.label, this.width);
  final String label;
  final double width;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns});

  final List<_Col> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: DarColors.cardDark.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 168,
            child: Text(
              'PLAYER',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final col in columns)
            SizedBox(
              width: col.width,
              child: Text(
                col.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DarColors.muted.withValues(alpha: 0.85),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.row,
    required this.columns,
  });

  final GameStatsPlayerReportRow row;
  final List<_Col> columns;

  @override
  Widget build(BuildContext context) {
    final player = row.player;
    final values = [
      '${row.points}',
      row.fgLine,
      row.ftLine,
      '${row.rebounds}',
      '${row.assists}',
      '${row.steals}',
      '${row.blocks}',
      '${row.turnovers}',
      '${row.fouls}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: row.onCourt
          ? DarColors.accentRed.withValues(alpha: 0.04)
          : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 168,
            child: Row(
              children: [
                GameStatsPlayerAvatar(player: player, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (player.jerseyNumber != null)
                            Text(
                              '#${player.jerseyNumber}',
                              style: TextStyle(
                                color: DarColors.muted.withValues(alpha: 0.75),
                                fontSize: 9,
                              ),
                            ),
                          if (row.onCourt) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: DarColors.accentRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ON',
                                style: TextStyle(
                                  color: DarColors.accentRed,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < columns.length; i++)
            SizedBox(
              width: columns[i].width,
              child: Text(
                values[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i == 0 ? Colors.white : DarColors.muted.withValues(alpha: 0.92),
                  fontSize: 10,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: i <= 2 ? 'monospace' : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
