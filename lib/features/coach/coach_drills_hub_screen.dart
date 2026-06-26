import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/screens/add_new_drill_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_all_drills_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_assigned_drills_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_drill_detail_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_drill_reminders_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';

class CoachDrillsHubScreen extends StatefulWidget {
  const CoachDrillsHubScreen({super.key});

  @override
  State<CoachDrillsHubScreen> createState() => _CoachDrillsHubScreenState();
}

class _CoachDrillsHubScreenState extends State<CoachDrillsHubScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachDrillsMotion _motion;
  String? _sessionFilterId;
  List<Drill> _drills = [];
  List<TrainingSession> _sessions = [];
  bool _loading = true;
  bool _loadedOnce = false;
  String? _error;

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
      final results = await Future.wait([
        CoachDrillService.fetchDrills(),
        _fetchAllSessions(),
      ]);
      if (!mounted) return;
      setState(() {
        _drills = sortDrillsNewestFirst(results[0] as List<Drill>);
        _sessions = results[1] as List<TrainingSession>;
        _loading = false;
        _loadedOnce = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadedOnce = true;
        _error = 'Could not load drills';
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<List<TrainingSession>> _fetchAllSessions() async {
    final results = await Future.wait([
      CoachTrainingSessionService.fetchSessions(status: 'upcoming'),
      CoachTrainingSessionService.fetchSessions(status: 'past'),
    ]);
    final byId = <String, TrainingSession>{};
    for (final session in [...results[0], ...results[1]]) {
      byId[session.id] = session;
    }
    return byId.values.toList();
  }

  Future<void> _openAddDrill() async {
    await Navigator.push(context, coachDrillsPageRoute(const AddNewDrillScreen()));
    await _load();
  }

  void _openDrillDetail(Drill drill) {
    Navigator.push(
      context,
      coachDrillsPageRoute(CoachDrillDetailScreen(drill: drill)),
    );
  }

  void _openViewAll() {
    Navigator.push(
      context,
      coachDrillsPageRoute(CoachAllDrillsScreen(initialSessionId: _sessionFilterId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = sortDrillsNewestFirst(
      filterDrillsBySession(_drills, _sessionFilterId),
    );
    final preview = filtered.take(5).toList();
    final highPriority = countHighPriorityDrills(filtered);

    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Drills'),
        centerTitle: true,
      ),
      floatingActionButton: CoachDrillsAnimatedFab(
        motion: _motion,
        heroTag: 'fab_coach_drills_hub',
        onPressed: _openAddDrill,
      ),
      body: darResponsiveBody(
        RefreshIndicator(
        color: DarColors.accentRed,
        backgroundColor: DarColors.surface,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: DarLayoutMetrics.of(context).scrollPadding(top: 8),
          children: [
            CoachDrillsHero(
              motion: _motion,
              badge: 'DRILL HUB',
              title: 'Drill Command',
              subtitle: 'Build, assign & track every drill',
              stats: [
                (value: '${filtered.length}', label: _sessionFilterId == null ? 'TOTAL' : 'IN SESSION'),
                (value: '$highPriority', label: 'HIGH PRIORITY'),
              ],
            ),
            if (!_loadedOnce && _loading && _drills.isEmpty) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: DarColors.accentRed)),
            ],
            const SizedBox(height: 16),
            _sessionFilter(_sessions),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: CoachDrillsStaticHeader(
                    label: 'RECENT DRILLS',
                    icon: Icons.sports_basketball_rounded,
                  ),
                ),
                if (filtered.isNotEmpty)
                  CoachDrillsViewAllButton(
                    motion: _motion,
                    label: 'VIEW ALL',
                    onTap: _openViewAll,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_loading && filtered.isEmpty)
              CoachDrillsEmptyState(
                icon: Icons.sports_basketball_outlined,
                title: 'No drills yet',
                subtitle: 'Tap + to create your first drill',
                actionLabel: 'Add New Drill',
                onAction: _openAddDrill,
              )
            else ...[
              ...List.generate(preview.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _drillTile(preview[i]),
                );
              }),
              if (filtered.length > 5)
                Center(
                  child: CoachDrillsViewAllButton(
                    motion: _motion,
                    label: 'VIEW ALL ${filtered.length} DRILLS',
                    onTap: _openViewAll,
                  ),
                ),
            ],
            const SizedBox(height: 24),
            const CoachDrillsStaticHeader(label: 'ACTIONS', icon: Icons.bolt_rounded),
            const SizedBox(height: 10),
            CoachDrillsActionTile(
              motion: _motion,
              index: 0,
              icon: Icons.assignment_outlined,
              title: 'Assigned Drills',
              subtitle: 'View and assign drills to players',
              onTap: () => Navigator.push(
                context,
                coachDrillsPageRoute(
                  CoachAssignedDrillsScreen(initialTrainingId: _sessionFilterId),
                ),
              ),
            ),
            CoachDrillsActionTile(
              motion: _motion,
              index: 1,
              icon: Icons.notifications_active_outlined,
              title: 'Drill Reminders',
              subtitle: 'Nudge players on pending drills',
              onTap: () => Navigator.push(
                context,
                coachDrillsPageRoute(
                  CoachDrillRemindersScreen(initialTrainingId: _sessionFilterId),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sessionFilter(List<TrainingSession> sessions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _sessionFilterId,
          dropdownColor: DarColors.surface,
          hint: Text('All sessions', style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9))),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All sessions', style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9))),
            ),
            ...sessions.map(
              (s) => DropdownMenuItem<String?>(
                value: s.id,
                child: Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          onChanged: (id) => setState(() => _sessionFilterId = id),
        ),
      ),
    );
  }

  Widget _drillTile(Drill drill) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDrillDetail(drill),
        borderRadius: BorderRadius.circular(16),
        splashColor: DarColors.accentRed.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  drill.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (drill.priority != null && drill.priority!.isNotEmpty) ...[
                const SizedBox(width: 8),
                CoachDrillsPriorityChip(priority: drill.priority!),
              ],
              Icon(Icons.chevron_right_rounded, color: DarColors.accentRed.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}
