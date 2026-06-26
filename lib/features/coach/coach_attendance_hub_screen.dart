import 'package:flutter/material.dart';

import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/attendance/screens/attendance_analytics_screen.dart';
import 'package:dar_city_app/features/attendance/screens/take_session_attendance_screen.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_attendance_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';

/// Attendance tab — premium hub matching Drills / Session style.
class CoachAttendanceHubScreen extends StatefulWidget {
  const CoachAttendanceHubScreen({super.key});

  @override
  State<CoachAttendanceHubScreen> createState() => _CoachAttendanceHubScreenState();
}

class _CoachAttendanceHubScreenState extends State<CoachAttendanceHubScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachAttendanceMotion _motion;
  List<TrainingSession> _sessions = [];
  bool _loading = true;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _motion = CoachAttendanceMotion(this);
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
        CoachTrainingSessionService.fetchSessions(status: 'upcoming'),
        CoachTrainingSessionService.fetchSessions(status: 'past'),
      ]);
      final byId = <String, TrainingSession>{};
      for (final session in [...results[0], ...results[1]]) {
        byId[session.id] = session;
      }
      if (!mounted) return;
      setState(() {
        _sessions = byId.values.toList();
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

  @override
  Widget build(BuildContext context) {
    final upcoming = _sessions.where((s) => !s.isPast).length;

    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Attendance'),
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
            CoachAttendanceHero(
              motion: _motion,
              badge: 'ATTENDANCE HUB',
              title: 'Squad Roll Call',
              subtitle: 'Track presence, lateness & absences',
              stats: [
                (value: '${_sessions.length}', label: 'SESSIONS'),
                (value: '$upcoming', label: 'ACTIVE'),
              ],
            ),
            if (!_loadedOnce && _loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ],
            const SizedBox(height: 22),
            const CoachAttendanceStaticHeader(
              label: 'ACTIONS',
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 10),
            CoachAttendanceActionTile(
              motion: _motion,
              index: 0,
              icon: Icons.fact_check_outlined,
              title: 'Take Session Attendance',
              subtitle: 'Mark present, late, or absent for today',
              onTap: () => Navigator.push(
                context,
                coachAttendancePageRoute(const TakeSessionAttendanceScreen()),
              ),
            ),
            CoachAttendanceActionTile(
              motion: _motion,
              index: 1,
              icon: Icons.analytics_outlined,
              title: 'Attendance Analytics',
              subtitle: 'Charts, trends and squad insights',
              onTap: () => Navigator.push(
                context,
                coachAttendancePageRoute(const AttendanceAnalyticsScreen()),
              ),
            ),
            if (_sessions.isEmpty && _loadedOnce && !_loading) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DarColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      color: DarColors.muted.withValues(alpha: 0.5),
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No sessions yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a training session first, then mark attendance here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
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
