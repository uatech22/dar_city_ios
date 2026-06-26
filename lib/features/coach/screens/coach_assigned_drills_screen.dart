import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/screens/assign_drills_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class CoachAssignedDrillsScreen extends StatefulWidget {
  const CoachAssignedDrillsScreen({super.key, this.initialTrainingId});

  final String? initialTrainingId;

  @override
  State<CoachAssignedDrillsScreen> createState() =>
      _CoachAssignedDrillsScreenState();
}

class _CoachAssignedDrillsScreenState extends State<CoachAssignedDrillsScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachDrillsMotion _motion;
  List<CoachDrillAssignment> _assignments = [];
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
      final assignments = await CoachDrillService.fetchAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
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

  Future<void> _openAssignForm() async {
    final created = await Navigator.push<bool>(
      context,
      coachDrillsPageRoute(
        AssignDrillsScreen(initialTrainingId: widget.initialTrainingId),
      ),
    );
    if (!mounted) return;
    if (created == true) {
      await _load();
      if (!context.mounted) return;
      showFeatureSnackBar(context, 'Drills assigned successfully');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return DarColors.greenBright;
      case 'overdue':
        return DarColors.accentRed;
      case 'in_progress':
        return const Color(0xFFFFAA44);
      default:
        return DarColors.muted;
    }
  }

  int _countByStatus(List<CoachDrillAssignment> list, String status) =>
      list.where((a) => a.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Assigned Drills'),
        centerTitle: true,
      ),
      floatingActionButton: CoachDrillsAnimatedFab(
        motion: _motion,
        heroTag: 'fab_coach_assigned_drills',
        onPressed: _openAssignForm,
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
              badge: 'ASSIGNMENTS',
              title: 'Assigned Drills',
              subtitle: 'Track squad workload & completion',
              stats: [
                (value: '${_assignments.length}', label: 'TOTAL'),
                (value: '${_countByStatus(_assignments, 'pending')}', label: 'PENDING'),
              ],
            ),
            if (!_loadedOnce && _loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ],
            const SizedBox(height: 20),
            if (_loadedOnce && _assignments.isEmpty)
              CoachDrillsEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No assigned drills yet',
                subtitle: 'Tap + to assign drills to your squad',
                actionLabel: 'New Assignment',
                onAction: _openAssignForm,
              )
            else
              ...List.generate(_assignments.length, (i) {
                final a = _assignments[i];
                final statusColor = _statusColor(a.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoachDrillsStaticTile(
                    highlight: a.status == 'overdue',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 56,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.drillName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.playerName,
                                style: TextStyle(color: DarColors.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Due ${a.dueDate} · ${a.sets} sets × ${a.reps} reps · ${a.timeMinutes} min',
                                style: TextStyle(
                                  color: DarColors.muted.withValues(alpha: 0.85),
                                  fontSize: 11,
                                ),
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
                            a.statusLabel.toUpperCase(),
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
