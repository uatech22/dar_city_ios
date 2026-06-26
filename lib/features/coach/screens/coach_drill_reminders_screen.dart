import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/screens/coach_send_drill_reminders_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class CoachDrillRemindersScreen extends StatefulWidget {
  const CoachDrillRemindersScreen({super.key, this.initialTrainingId});

  final String? initialTrainingId;

  @override
  State<CoachDrillRemindersScreen> createState() =>
      _CoachDrillRemindersScreenState();
}

class _CoachDrillRemindersScreenState extends State<CoachDrillRemindersScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachDrillsMotion _motion;
  List<DrillReminderOverviewItem> _items = [];
  bool _loading = true;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await CoachDrillService.fetchReminderOverview(
        trainingId: widget.initialTrainingId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _loadedOnce = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadedOnce = true;
        });
      }
    }
  }

  Future<void> _openSendForm() async {
    final sent = await Navigator.push<bool>(
      context,
      coachDrillsPageRoute(
        CoachSendDrillRemindersScreen(initialTrainingId: widget.initialTrainingId),
      ),
    );
    if (!mounted) return;
    if (sent == true) {
      await _load();
      if (!context.mounted) return;
      showFeatureSnackBar(context, 'Reminders sent');
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('complete')) return DarColors.greenBright;
    if (s.contains('progress')) return const Color(0xFFFFAA44);
    return DarColors.muted;
  }

  int _pendingCount(List<DrillReminderOverviewItem> items) =>
      items.where((i) => !i.status.toLowerCase().contains('complete')).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Drill Reminders'),
        centerTitle: true,
      ),
      floatingActionButton: CoachDrillsAnimatedFab(
        motion: _motion,
        heroTag: 'fab_coach_drill_reminders',
        onPressed: _openSendForm,
        icon: Icons.send_rounded,
      ),
      body: darResponsiveBody(
        RefreshIndicator(
        color: DarColors.accentRed,
        backgroundColor: DarColors.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: DarLayoutMetrics.of(context).scrollPadding(top: 8),
          children: [
            CoachDrillsHero(
              motion: _motion,
              badge: 'REMINDERS',
              title: 'Drill Reminders',
              subtitle: 'Follow up on incomplete drill work',
              stats: [
                (value: '${_items.length}', label: 'PLAYERS'),
                (value: '${_pendingCount(_items)}', label: 'PENDING'),
              ],
            ),
            if (!_loadedOnce && _loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ],
            const SizedBox(height: 20),
            if (_loadedOnce && _items.isEmpty)
              CoachDrillsEmptyState(
                icon: Icons.notifications_active_outlined,
                title: 'No pending reminders',
                subtitle: widget.initialTrainingId == null
                    ? 'Tap send to remind players about assigned drills'
                    : 'No incomplete drills in this session — send anyway',
                actionLabel: 'Send Reminder',
                onAction: _openSendForm,
              )
            else
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final statusColor = _statusColor(item.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoachDrillsStaticTile(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: DarColors.accentRed.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: DarColors.accentRed.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: DarColors.accentRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.drillName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.playerName,
                                style: TextStyle(color: DarColors.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            item.statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      ),
    );
  }
}
