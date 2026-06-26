import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/models/coach_dashboard.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcement_detail_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcements_list_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_dashboard_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/recent_chats_dashboard_section.dart';
import 'package:dar_city_app/models/profile.dart';
import 'package:dar_city_app/services/profile_service.dart';
import 'package:dar_city_app/services/session_manager.dart';

class CoachTrainingDashboardScreen extends StatefulWidget {
  const CoachTrainingDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CoachTrainingDashboardScreen> createState() =>
      _CoachTrainingDashboardScreenState();
}

class _CoachTrainingDashboardScreenState extends State<CoachTrainingDashboardScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  CoachDashboard? _dashboard;
  Profile? _profile;
  bool _entrancePlayed = false;
  late AnimationController _entrance;
  late AnimationController _ambient;
  late AnimationController _pulse;
  late AnimationController _orbit;
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _pulse.dispose();
    _orbit.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CoachDashboardService.fetchDashboard(),
        ProfileService().getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as CoachDashboard;
        _profile = results[1] as Profile;
      });
      if (_profile?.id != null) {
        await SessionManager().saveUserId(_profile!.id);
      }
      if (!_entrancePlayed) {
        _entrance.forward();
        _entrancePlayed = true;
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Animation<double> _interval(double begin, double end, {Curve curve = Curves.easeOutCubic}) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: curve),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final prefix = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = _profile?.name.trim();
    if (name != null && name.isNotEmpty) {
      final first = name.split(RegExp(r'\s+')).first;
      return '$prefix, $first';
    }
    return '$prefix, Coach';
  }

  String get _userSubtitle {
    final name = _profile?.name.trim();
    final role = _profile?.displayRoleLabel;
    if (name != null && name.isNotEmpty && role != null && role.isNotEmpty) {
      return '$name · $role';
    }
    if (name != null && name.isNotEmpty) return name;
    return 'Training Command Center';
  }

  void _openAnnouncement(RecentAnnouncement recent) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => CoachAnnouncementDetailLoader(
          announcementId: recent.id,
          fallback: recent.toFallbackAnnouncement(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openAllAnnouncements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CoachAnnouncementsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Dashboard',
      actions: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _entrance, curve: Curves.easeInOut),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ),
      ],
      body: RefreshIndicator(
        color: DarColors.accentRed,
        backgroundColor: DarColors.surface,
        onRefresh: () async {
          await _load();
        },
        child: _dashboard == null
            ? const Center(child: CircularProgressIndicator(color: DarColors.accentRed))
            : _buildDashboardContent(_dashboard!),
      ),
    );
  }

  Widget _buildDashboardContent(CoachDashboard data) {
    final layout = DarLayoutMetrics.of(context);
    return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: layout.scrollPadding(top: 8),
          children: [
              CoachEntrance(
                animation: _interval(0, 0.2, curve: Curves.easeOutBack),
                tilt: 0.06,
                child: _heroHeader(),
              ),
              const SizedBox(height: 24),
              CoachEntrance(
                animation: _interval(0.12, 0.34, curve: Curves.easeOutBack),
                slideFrom: const Offset(0.08, 0.06),
                child: const RecentChatsDashboardSection(
                  role: DirectChatRole.coach,
                ),
              ),
              const SizedBox(height: 24),
              CoachEntrance(
                animation: _interval(0.08, 0.28, curve: Curves.elasticOut),
                slideFrom: const Offset(-0.08, 0.06),
                child: CoachSectionHeaderAnimated(
                  label: 'UPCOMING TRAINING',
                  icon: Icons.event_note_rounded,
                  animation: _interval(0.08, 0.32),
                ),
              ),
              const SizedBox(height: 10),
              CoachEntrance(
                animation: _interval(0.14, 0.36, curve: Curves.easeOutBack),
                slideFrom: const Offset(0.1, 0.08),
                tilt: 0.05,
                child: _upcomingTrainingCard(data.upcomingTraining),
              ),
              const SizedBox(height: 28),
              CoachEntrance(
                animation: _interval(0.24, 0.44, curve: Curves.elasticOut),
                slideFrom: const Offset(-0.06, 0.05),
                child: CoachSectionHeaderAnimated(
                  label: 'QUICK STATS',
                  icon: Icons.insights_rounded,
                  animation: _interval(0.24, 0.46),
                ),
              ),
              const SizedBox(height: 10),
              CoachEntrance(
                animation: _interval(0.3, 0.52, curve: Curves.easeOutBack),
                child: _quickStatsRow(data.quickStats),
              ),
              const SizedBox(height: 28),
              CoachEntrance(
                animation: _interval(0.4, 0.58, curve: Curves.elasticOut),
                child: Row(
                  children: [
                    Expanded(
                      child: CoachSectionHeaderAnimated(
                        label: 'RECENT ANNOUNCEMENTS',
                        icon: Icons.campaign_outlined,
                        animation: _interval(0.4, 0.6),
                      ),
                    ),
                    if (data.recentAnnouncements.isNotEmpty)
                      CoachEntrance(
                        animation: _interval(0.42, 0.62),
                        slideFrom: const Offset(0.08, 0),
                        child: _viewAllAnnouncementsButton(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (data.recentAnnouncements.isEmpty)
                CoachEntrance(
                  animation: _interval(0.46, 0.66),
                  child: _emptyAnnouncements(),
                )
              else
                ...List.generate(data.recentAnnouncements.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _announcementTile(data.recentAnnouncements[i], i),
                  );
                }),
            ],
          );
  }

  Widget _heroHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _ambient]),
      builder: (context, child) {
        final glow = 0.15 + (_pulse.value * 0.25);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DarColors.accentRed.withValues(alpha: 0.38 + (_pulse.value * 0.12)),
                DarColors.surface,
                DarColors.background,
              ],
            ),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.35 + (_pulse.value * 0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: glow),
                blurRadius: 36,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CoachFloatingParticles(
                  t: _ambient.value,
                  pulse: _pulse.value,
                ),
              ),
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
                  _redBadge('DAR CITY', Icons.sports_basketball_rounded),
                  const SizedBox(width: 8),
                  _livePulseChip(),
                  const Spacer(),
                  if (_profile != null) ...[
                    DarPlayerAvatar(
                      name: _profile!.name,
                      imageUrl: _profile!.passportImageUrl,
                      size: 44,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Transform.rotate(
                    angle: math.sin(_ambient.value * math.pi * 2) * 0.08,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DarColors.accentRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AnimatedGreeting(
                text: _greeting,
                animation: _interval(0.05, 0.25),
              ),
              const SizedBox(height: 6),
              _AnimatedTitle(
                text: _userSubtitle,
                animation: _interval(0.1, 0.35),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 4,
                      width: 80 * Curves.easeOutExpo.transform(_entrance.value.clamp(0, 0.35) / 0.35),
                      decoration: BoxDecoration(
                        color: DarColors.accentRed,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: DarColors.accentRed.withValues(alpha: 0.65),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  Widget _viewAllAnnouncementsButton() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAllAnnouncements,
            borderRadius: BorderRadius.circular(20),
            splashColor: DarColors.accentRed.withValues(alpha: 0.2),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarColors.accentRed.withValues(
                    alpha: 0.35 + (_shimmer.value * 0.25),
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                    DarColors.accentRed.withValues(alpha: 0.08 + _shimmer.value * 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VIEW ALL',
                    style: TextStyle(
                      color: DarColors.accentRed.withValues(alpha: 0.85 + _shimmer.value * 0.15),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: DarColors.accentRed.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _livePulseChip() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
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

  Widget _redBadge(String label, IconData icon) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_pulse.value * 0.03),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: DarColors.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.5)),
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
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingTrainingCard(UpcomingTraining training) {
    return AnimatedBuilder(
      animation: _orbit,
      builder: (context, child) {
        return CoachSweepBorder(
          t: _orbit.value,
          radius: 18,
          child: child!,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: DarColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _interval(0.14, 0.4),
          builder: (context, child) {
            final barT = _interval(0.14, 0.4).value;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 5,
                      height: (120 * barT).clamp(0.0, 120.0),
                      color: DarColors.accentRed,
                    ),
                  ),
                  Expanded(child: child!),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        training.scheduledAt.toUpperCase(),
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        training.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        training.focus.isNotEmpty
                            ? 'Focus: ${training.focus}'
                            : 'No focus set',
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.95),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _redBadge('NEXT SESSION', Icons.play_circle_outline),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _trainingImage(training.imageUrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainingImage(String? url) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _ambient]),
      builder: (context, child) {
        final zoom = 1.08 + (_ambient.value * 0.04);
        final reveal = _interval(0.18, 0.42).value;
        return Transform.scale(
          scale: lerpDouble(1.25, 1.0, reveal)! * zoom,
          child: Opacity(opacity: reveal.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        width: 110,
        height: 76,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DarColors.accentRed.withValues(alpha: 0.45),
          ),
        ),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _trainingImageFallback(showLoader: true),
                errorWidget: (_, __, ___) => _trainingImageFallback(),
              )
            : _trainingImageFallback(),
      ),
    );
  }

  Widget _trainingImageFallback({bool showLoader = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/ground.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: DarColors.cardDark),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                DarColors.accentRed.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Center(
          child: showLoader
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DarColors.accentRed,
                  ),
                )
              : RotationTransition(
                  turns: _ambient,
                  child: const Icon(
                    Icons.sports_basketball_rounded,
                    color: DarColors.accentRed,
                    size: 30,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _quickStatsRow(List<QuickStat> stats) {
    if (stats.isEmpty) {
      return Text(
        'No stats available yet',
        style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9)),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _quickStatCard(stats[i], index: i)),
        ],
      ],
    );
  }

  double _statProgress(String value) {
    final n = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (n == null) return 0.72;
    if (value.contains('%')) return (n / 100).clamp(0.0, 1.0);
    return (n / 100).clamp(0.3, 0.95);
  }

  Widget _quickStatCard(QuickStat stat, {required int index}) {
    final blobColor = stat.trendUp ? DarColors.green : DarColors.accentRed;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shimmer, _ambient]),
      builder: (context, child) {
        return Container(
          height: 178,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [DarColors.cardDark, DarColors.surface, DarColors.cardDark],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: blobColor.withValues(
                alpha: 0.22 + (_pulse.value * 0.2),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: blobColor.withValues(alpha: 0.1 + _pulse.value * 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CoachCardBlobs(
                  t: _ambient.value,
                  pulse: _pulse.value,
                  index: index,
                  color: blobColor,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                CoachStatRing(
                  progress: _statProgress(stat.value),
                  pulse: _pulse.value,
                  up: stat.trendUp,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + index * 200),
                  curve: Curves.elasticOut,
                  builder: (context, bounce, _) {
                    return Transform.translate(
                      offset: Offset(0, 8 * (1 - bounce)),
                      child: Icon(
                        stat.trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color: stat.trendUp ? DarColors.green : DarColors.accentRed,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  stat.trend,
                  style: TextStyle(
                    color: stat.trendUp ? DarColors.green : DarColors.accentRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAnnouncements() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_ambient.value * math.pi * 2) * 3),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DarColors.accentRed.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                color: DarColors.muted.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 10),
            Text(
              'No announcements yet',
              style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementTile(RecentAnnouncement announcement, int index) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(math.sin(_pulse.value * math.pi * 2) * 2, 0),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: DarColors.accentRed.withValues(alpha: 0.18),
          highlightColor: DarColors.accentRed.withValues(alpha: 0.1),
          onTap: () => _openAnnouncement(announcement),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DarColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: index == 0
                    ? DarColors.accentRed.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + index * 120),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) {
                    return Transform.scale(scale: t, child: child);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DarColors.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DarColors.accentRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: DarColors.accentRed,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
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
                        announcement.authorName,
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.95),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(math.sin(_ambient.value * math.pi * 4) * 3, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: DarColors.accentRed.withValues(alpha: 0.85),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGreeting extends StatelessWidget {
  const _AnimatedGreeting({required this.text, required this.animation});

  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: Text(
              text,
              style: TextStyle(
                color: DarColors.muted.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({required this.text, required this.animation});

  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Wrap(
          children: List.generate(words.length, (i) {
            final wordStart = i / words.length;
            final wordEnd = ((i + 1) / words.length).clamp(0.0, 1.0);
            final raw = ((animation.value - wordStart) / (wordEnd - wordStart))
                .clamp(0.0, 1.0);
            final t = Curves.easeOutCubic.transform(raw);
            return Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - t)),
                child: Opacity(
                  opacity: t,
                  child: Text(
                    words[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
