import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/screens/create_training_session_screen.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';

/// Full training session view — premium Dar City red/black with entrance motion.
class CoachTrainingSessionDetailScreen extends StatefulWidget {
  const CoachTrainingSessionDetailScreen({
    super.key,
    required this.session,
    this.canEdit = true,
  });

  final TrainingSession session;
  final bool canEdit;

  @override
  State<CoachTrainingSessionDetailScreen> createState() =>
      _CoachTrainingSessionDetailScreenState();
}

class _CoachTrainingSessionDetailScreenState
    extends State<CoachTrainingSessionDetailScreen> with TickerProviderStateMixin {
  late AnimationController _entrance;
  late AnimationController _ambient;
  late AnimationController _orbit;

  TrainingSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _orbit.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _openEdit() async {
    final saved = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) =>
            CreateTrainingSessionScreen(sessionToEdit: s),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = !s.isPast;

    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (widget.canEdit && upcoming)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: DarColors.accentRed),
                  onPressed: _openEdit,
                  tooltip: 'Edit session',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _heroFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DarColors.accentRed.withValues(alpha: 0.42),
                          Colors.black.withValues(alpha: 0.55),
                          DarColors.background,
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) =>
                        CoachFloatingParticles(t: _ambient.value),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: CoachEntrance(
                      animation: _interval(0, 0.35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusChip(upcoming),
                          const SizedBox(height: 10),
                          Text(
                            s.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (s.location.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: DarColors.accentRed.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.location,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: DarLayoutMetrics.of(context).scrollPadding(top: 8, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachEntrance(
                    animation: _interval(0.1, 0.36),
                    slideFrom: const Offset(0, 0.06),
                    child: _metaRow(),
                  ),
                  const SizedBox(height: 20),
                  CoachEntrance(
                    animation: _interval(0.18, 0.44),
                    child: _statsGrid(),
                  ),
                  if (s.focus != null && s.focus!.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    CoachEntrance(
                      animation: _interval(0.24, 0.5),
                      child: _sectionLabel('SESSION FOCUS'),
                    ),
                    const SizedBox(height: 10),
                    CoachEntrance(
                      animation: _interval(0.28, 0.54),
                      child: AnimatedBuilder(
                        animation: _orbit,
                        builder: (context, child) => CoachSweepBorder(
                          t: _orbit.value,
                          radius: 18,
                          child: child!,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DarColors.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            s.focus!.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.65,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (s.description != null && s.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    CoachEntrance(
                      animation: _interval(0.34, 0.58),
                      child: _sectionLabel('SESSION PLAN'),
                    ),
                    const SizedBox(height: 10),
                    CoachEntrance(
                      animation: _interval(0.38, 0.62),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DarColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          s.description!.trim(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (widget.canEdit && upcoming)
                    CoachEntrance(
                      animation: _interval(0.48, 0.72),
                      child: _editButton(),
                    ),
                  const SizedBox(height: 16),
                  CoachEntrance(
                    animation: _interval(0.54, 0.78),
                    child: _footerBadge(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _heroFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/ground.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: DarColors.surface),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.accentRed.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool upcoming) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final pulse = 0.5 + math.sin(_ambient.value * math.pi * 2) * 0.5;
        final color = upcoming ? DarColors.accentRed : DarColors.muted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12 + pulse * 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4 + pulse * 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (upcoming)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: DarColors.accentRed.withValues(alpha: 0.6 + pulse * 0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DarColors.accentRed.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                )
              else
                Icon(Icons.check_circle_rounded, size: 14, color: DarColors.muted),
              const SizedBox(width: 6),
              Text(
                upcoming ? 'UPCOMING SESSION' : 'COMPLETED SESSION',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
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

  Widget _metaRow() {
    final dateLabel = _formatSchedule();
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
          ),
          child: Icon(_typeIcon(s.type), color: DarColors.accentRed, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.type != null && s.type!.isNotEmpty
                    ? _capitalize(s.type!)
                    : 'Training Session',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel.toUpperCase(),
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        ),
        if (s.intensity != null && s.intensity!.isNotEmpty)
          _intensityBadge(s.intensity!),
      ],
    );
  }

  Widget _statsGrid() {
    final items = <({IconData icon, String label, String value})>[
      if (s.durationMinutes != null)
        (
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: '${s.durationMinutes} min',
        ),
      if (s.numberOfDays != null && s.numberOfDays! > 0)
        (
          icon: Icons.date_range_rounded,
          label: 'Days',
          value: '${s.numberOfDays}',
        ),
      if (s.startDate != null && s.startDate!.isNotEmpty)
        (
          icon: Icons.calendar_today_rounded,
          label: 'Start',
          value: s.startDate!,
        ),
      if (s.endDate != null && s.endDate!.isNotEmpty)
        (
          icon: Icons.event_available_rounded,
          label: 'End',
          value: s.endDate!,
        ),
      if (s.teamName != null && s.teamName!.isNotEmpty)
        (
          icon: Icons.groups_rounded,
          label: 'Team',
          value: s.teamName!,
        ),
      if (s.coachName != null && s.coachName!.isNotEmpty)
        (
          icon: Icons.person_rounded,
          label: 'Coach',
          value: s.coachName!,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              width: (MediaQuery.sizeOf(context).width - 50) / 2,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DarColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, color: DarColors.accentRed, size: 18),
                  const SizedBox(height: 8),
                  Text(
                    item.label.toUpperCase(),
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: DarColors.accentRed.withValues(alpha: 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _intensityBadge(String intensity) {
    final color = switch (intensity.toLowerCase()) {
      'high' => DarColors.accentRed,
      'medium' => const Color(0xFFFFAA44),
      _ => const Color(0xFF66BB6A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        intensity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _editButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEdit,
        borderRadius: BorderRadius.circular(16),
        splashColor: DarColors.accentRed.withValues(alpha: 0.2),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.accentRed.withValues(alpha: 0.85),
                DarColors.accentRed.withValues(alpha: 0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'EDIT SESSION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerBadge() {
    return Center(
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, math.sin(_ambient.value * math.pi * 2) * 2),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.accentRed.withValues(alpha: 0.2),
                DarColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 16),
              SizedBox(width: 8),
              Text(
                'DAR CITY · TRAINING',
                style: TextStyle(
                  color: DarColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSchedule() {
    if (s.scheduledAt != null && s.scheduledAt!.length >= 16) {
      return s.scheduledAt!.substring(0, 16).replaceFirst('T', ' · ');
    }
    if (s.startDate != null) return s.startDate!;
    return '';
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

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
