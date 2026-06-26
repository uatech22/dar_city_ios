import 'package:flutter/material.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/screens/coach_training_session_detail_screen.dart';
import 'package:dar_city_app/features/coach/screens/create_training_session_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';

class ManageTrainingSessionScreen extends StatefulWidget {
  const ManageTrainingSessionScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ManageTrainingSessionScreen> createState() =>
      _ManageTrainingSessionScreenState();
}

class _ManageTrainingSessionScreenState extends State<ManageTrainingSessionScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  List<TrainingSession> _upcoming = [];
  List<TrainingSession> _past = [];
  bool _loading = true;
  bool _loadedOnce = false;

  int _tabIndex = 0;

  late AnimationController _ambient;
  late AnimationController _pulse;
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CoachTrainingSessionService.fetchSessions(status: 'upcoming'),
        CoachTrainingSessionService.fetchSessions(status: 'past'),
      ]);
      if (!mounted) return;
      setState(() {
        _upcoming = results[0];
        _past = results[1];
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

  Future<void> _openCreateScreen() async {
    final saved = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const CreateTrainingSessionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _openSessionDetail(TrainingSession session, {required bool canEdit}) async {
    final saved = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => CoachTrainingSessionDetailScreen(
          session: session,
          canEdit: canEdit,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (saved == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Training Sessions',
      backgroundColor: DarColors.background,
      floatingActionButton: _animatedFab(),
      body: RefreshIndicator(
        color: DarColors.accentRed,
        backgroundColor: DarColors.surface,
        onRefresh: () async {
          await _load();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _heroHeader(),
            const SizedBox(height: 20),
            _tabSwitcher(),
            const SizedBox(height: 20),
            IndexedStack(
              index: _tabIndex,
              sizing: StackFit.loose,
              children: [
                _sessionListPanel(
                  label: 'UPCOMING',
                  icon: Icons.upcoming_rounded,
                  sessions: _upcoming,
                  canEdit: true,
                  emptyIcon: Icons.event_available_rounded,
                  emptyTitle: 'No upcoming sessions',
                  emptySubtitle: 'Tap + to schedule your next training block',
                ),
                _sessionListPanel(
                  label: 'PAST SESSIONS',
                  icon: Icons.history_rounded,
                  sessions: _past,
                  canEdit: false,
                  emptyIcon: Icons.history_toggle_off_rounded,
                  emptyTitle: 'No past sessions',
                  emptySubtitle: 'Completed sessions will appear here',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionListPanel({
    required String label,
    required IconData icon,
    required List<TrainingSession> sessions,
    required bool canEdit,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(label, icon),
        const SizedBox(height: 10),
        if (!_loadedOnce && _loading && sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: DarColors.accentRed),
            ),
          )
        else if (sessions.isEmpty)
          _emptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          )
        else
          ...List.generate(sessions.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _sessionTile(sessions[i], canEdit: canEdit, index: i),
            );
          }),
      ],
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DarColors.accentRed, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _animatedFab() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_pulse.value * 0.06),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DarColors.accentRed.withValues(alpha: 0.35 + _pulse.value * 0.2),
                  blurRadius: 20 + _pulse.value * 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        heroTag: 'fab_coach_training_sessions',
        onPressed: _openCreateScreen,
        backgroundColor: DarColors.accentRed,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _heroHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _ambient]),
      builder: (context, child) {
        final glow = 0.12 + (_pulse.value * 0.22);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DarColors.accentRed.withValues(alpha: 0.35 + (_pulse.value * 0.1)),
                DarColors.surface,
                DarColors.background,
              ],
            ),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.32 + (_pulse.value * 0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: glow),
                blurRadius: 32,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CoachFloatingParticles(t: _ambient.value)),
              child!,
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge('SESSION HUB', Icons.event_note_rounded),
              const SizedBox(width: 8),
              _liveChip(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage Training',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Plan, review & run every session',
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.95),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statPill('${_upcoming.length}', 'UPCOMING'),
              const SizedBox(width: 10),
              _statPill('${_past.length}', 'COMPLETED'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DarColors.accentRed, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: DarColors.accentRed,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveChip() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.4 + _pulse.value * 0.6;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12 + _pulse.value * 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: glow),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DarColors.accentRed.withValues(alpha: glow),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: DarColors.muted.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSwitcher() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.15 + _shimmer.value * 0.1),
            ),
          ),
          child: Row(
            children: [
              _tabChip('Upcoming', 0, Icons.upcoming_rounded),
              _tabChip('Past', 1, Icons.history_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _tabChip(String label, int index, IconData icon) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? DarColors.accentRed.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: DarColors.accentRed.withValues(alpha: 0.45))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? DarColors.accentRed : DarColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : DarColors.muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: DarColors.muted.withValues(alpha: 0.45), size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sessionTile(TrainingSession session, {required bool canEdit, required int index}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSessionDetail(session, canEdit: canEdit),
        borderRadius: BorderRadius.circular(16),
        splashColor: DarColors.accentRed.withValues(alpha: 0.18),
        highlightColor: DarColors.accentRed.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canEdit && index == 0
                  ? DarColors.accentRed.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DarColors.accentRed.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  _typeIcon(session.type),
                  color: DarColors.accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DarColors.muted.withValues(alpha: 0.95),
                        fontSize: 12,
                      ),
                    ),
                    if (session.focus != null && session.focus!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DarColors.accentRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.focus!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DarColors.accentRed.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: DarColors.accentRed.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String? type) {
    return switch (type?.toLowerCase()) {
      'fitness' => Icons.fitness_center_rounded,
      'shooting' => Icons.sports_basketball_rounded,
      'tactics' => Icons.grid_view_rounded,
      'scrimmage' => Icons.groups_rounded,
      'recovery' => Icons.spa_rounded,
      _ => Icons.event_note_rounded,
    };
  }
}
