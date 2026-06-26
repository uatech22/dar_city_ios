import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/screens/coach_drill_detail_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';

class CoachAllDrillsScreen extends StatefulWidget {
  const CoachAllDrillsScreen({super.key, this.initialSessionId});

  final String? initialSessionId;

  @override
  State<CoachAllDrillsScreen> createState() => _CoachAllDrillsScreenState();
}

class _CoachAllDrillsScreenState extends State<CoachAllDrillsScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachDrillsMotion _motion;
  String? _sessionFilterId;
  List<Drill> _drills = [];
  List<TrainingSession> _sessions = [];
  bool _loading = true;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
    _sessionFilterId = widget.initialSessionId;
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

  @override
  Widget build(BuildContext context) {
    final filtered = sortDrillsNewestFirst(
      filterDrillsBySession(_drills, _sessionFilterId),
    );
    final highPriority = countHighPriorityDrills(filtered);

    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('All Drills'),
        centerTitle: true,
      ),
      body: darResponsiveBody(
        RefreshIndicator(
        color: DarColors.accentRed,
        backgroundColor: DarColors.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: DarLayoutMetrics.of(context).scrollPadding(top: 8, bottom: 32),
          children: [
            CoachDrillsHero(
              motion: _motion,
              badge: 'DRILL LIBRARY',
              title: 'All Drills',
              subtitle: 'Browse your full drill collection',
              stats: [
                (value: '${filtered.length}', label: 'SHOWING'),
                (value: '$highPriority', label: 'HIGH PRIORITY'),
              ],
            ),
            if (!_loadedOnce && _loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ],
            const SizedBox(height: 16),
            _sessionFilter(_sessions),
            const SizedBox(height: 20),
            if (_loadedOnce && filtered.isEmpty)
              CoachDrillsEmptyState(
                icon: Icons.sports_basketball_outlined,
                title: _sessionFilterId == null ? 'No drills yet' : 'No drills for this session',
                subtitle: 'Create drills from the Drills tab',
              )
            else
              ...List.generate(filtered.length, (i) {
                final drill = filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoachDrillsStaticTile(
                    highlight: i == 0,
                    onTap: () => Navigator.push(
                      context,
                      coachDrillsPageRoute(CoachDrillDetailScreen(drill: drill)),
                    ),
                    child: Row(
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
                            Icons.sports_basketball,
                            color: DarColors.accentRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            drill.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (drill.priority != null && drill.priority!.isNotEmpty)
                          CoachDrillsPriorityChip(priority: drill.priority!),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: DarColors.accentRed.withValues(alpha: 0.85),
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
}
