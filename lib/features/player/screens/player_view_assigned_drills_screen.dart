import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/player/services/player_drill_service.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class PlayerViewAssignedDrillsScreen extends StatefulWidget {
  const PlayerViewAssignedDrillsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlayerViewAssignedDrillsScreen> createState() =>
      _PlayerViewAssignedDrillsScreenState();
}

class _PlayerViewAssignedDrillsScreenState extends State<PlayerViewAssignedDrillsScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<List<AssignedDrill>> _drillsFuture;
  late PlayerMotion _motion;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = PlayerDrillService.fetchAssignedDrills();
    setState(() => _drillsFuture = future);
    await future;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return DarColors.greenBright;
      case 'overdue':
        return DarColors.accentRed;
      case 'in_progress':
        return DarColors.eliteGold;
      default:
        return DarColors.muted;
    }
  }

  List<AssignedDrill> _filtered(List<AssignedDrill> drills) {
    if (_statusFilter == null) return drills;
    return drills.where((d) => d.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Assigned Drills',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      body: RefreshIndicator(
        color: DarColors.accentRed,
        onRefresh: () async {
          _load();
          await _drillsFuture;
        },
        child: FeatureAsyncBody<List<AssignedDrill>>(
          future: _drillsFuture,
          onRetry: _load,
          builder: (context, drills) {
            final filtered = _filtered(drills);
            if (drills.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
                children: [
                  PlayerHeroCard(
                    motion: _motion,
                    badge: 'TRAINING',
                    title: 'Your Drills',
                    subtitle: 'Assigned by your coach',
                  ),
                  const SizedBox(height: 24),
                  const PlayerEmptyState(
                    icon: Icons.sports_basketball_outlined,
                    message: 'No assigned drills yet',
                  ),
                ],
              );
            }

            final summary = PlayerDrillSummary.fromDrills(drills);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: DarLayoutMetrics.of(context).scrollPadding(top: 8),
              children: [
                PlayerHeroCard(
                  motion: _motion,
                  badge: 'TRAINING',
                  title: 'Your Drills',
                  subtitle: '${summary.completed} of ${summary.total} completed',
                  chips: [
                    PlayerLiveChip(motion: _motion),
                    _summaryChip('${summary.overdue} overdue', DarColors.accentRed),
                    if (summary.pending > 0)
                      _summaryChip('${summary.pending} pending', DarColors.eliteGold),
                  ],
                ),
                const SizedBox(height: 20),
                PlayerDrillStatusFilterRail(
                  motion: _motion,
                  summary: summary,
                  selectedStatus: _statusFilter,
                  onSelected: (status) => setState(() => _statusFilter = status),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const PlayerEmptyState(
                    icon: Icons.filter_list_off_rounded,
                    message: 'No drills in this filter',
                  )
                else
                  ...filtered.map(_drillTile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _drillTile(AssignedDrill d) {
    final color = _statusColor(d.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlayerPremiumTile(
        accentColor: color,
        highlight: d.status == 'overdue',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.sports_basketball_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.drillName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due ${d.dueDate}',
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                  ),
                  Text(
                    '${d.reps} reps · ${d.sets} sets · ${d.timeMinutes} min',
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      d.statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
