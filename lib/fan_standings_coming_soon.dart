import 'dart:math' as math;

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/fan_schedule_theme.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:flutter/material.dart';

/// Polished placeholder until league standings API is live.
class FanStandingsComingSoon extends StatefulWidget {
  const FanStandingsComingSoon({super.key});

  @override
  State<FanStandingsComingSoon> createState() => _FanStandingsComingSoonState();
}

class _FanStandingsComingSoonState extends State<FanStandingsComingSoon>
    with TickerProviderStateMixin {
  late FanMotion _motion;
  late AnimationController _enterController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _motion = FanMotion(this);
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic));

    _enterController.forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    _enterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: layout.scrollPadding(top: 4, bottom: 28),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildFeatureRow(),
            const SizedBox(height: 22),
            const FanSectionHeader(
              label: 'Preview',
              icon: Icons.leaderboard_rounded,
            ),
            const SizedBox(height: 10),
            _buildGhostTable(),
            const SizedBox(height: 16),
            _buildFooterNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_motion.pulse, _motion.ambient]),
      builder: (context, _) {
        final glow = 0.14 + _motion.pulse.value * 0.2;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FanSchedulePalette.purpleMid.withValues(alpha: 0.55),
                DarColors.surface,
                DarColors.background,
              ],
            ),
            border: Border.all(
              color: FanSchedulePalette.gold.withValues(alpha: 0.28 + _motion.pulse.value * 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: FanSchedulePalette.purpleMid.withValues(alpha: glow),
                blurRadius: 36,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CoachFloatingParticles(
                  t: _motion.ambient.value,
                  pulse: _motion.pulse.value,
                ),
              ),
              Column(
                children: [
                  _buildTrophyBadge(),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        FanSchedulePalette.gold.withValues(alpha: 0.95),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Coming Soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Full league standings are on the way — win-loss records, '
                    'playoff race, and where Dar City sits in the table.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FanLiveChip(motion: _motion, label: 'IN DEVELOPMENT'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrophyBadge() {
    return AnimatedBuilder(
      animation: _motion.pulse,
      builder: (context, _) {
        final scale = 1.0 + _motion.pulse.value * 0.04;
        final glow = 0.35 + _motion.pulse.value * 0.45;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  FanSchedulePalette.gold.withValues(alpha: 0.35),
                  FanSchedulePalette.purpleMid.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: FanSchedulePalette.gold.withValues(alpha: glow),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: FanSchedulePalette.gold.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: FanSchedulePalette.gold.withValues(alpha: 0.92 + _motion.pulse.value * 0.08),
              size: 44,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow() {
    const items = [
      _FeatureItem(Icons.military_tech_rounded, 'Win–Loss', 'Team records'),
      _FeatureItem(Icons.timeline_rounded, 'Playoff race', 'Top spots'),
      _FeatureItem(Icons.sports_basketball_rounded, 'Dar City', 'Our rank'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildFeatureTile(items[i], index: i)),
        ],
      ],
    );
  }

  Widget _buildFeatureTile(_FeatureItem item, {required int index}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 650 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: DarColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(item.icon, color: DarColors.accentRed, size: 22),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: DarColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostTable() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const SizedBox(height: 10),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GhostStandingRow(
                shimmer: _shimmerController,
                index: i,
                highlight: i == 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    TextStyle labelStyle = TextStyle(
      color: DarColors.muted.withValues(alpha: 0.85),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );

    return Row(
      children: [
        SizedBox(width: 36, child: Text('#', style: labelStyle)),
        Expanded(child: Text('TEAM', style: labelStyle)),
        SizedBox(width: 28, child: Text('W', style: labelStyle, textAlign: TextAlign.center)),
        SizedBox(width: 28, child: Text('L', style: labelStyle, textAlign: TextAlign.center)),
        SizedBox(width: 32, child: Text('PTS', style: labelStyle, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DarColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, color: DarColors.accentRed.withValues(alpha: 0.85), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Standings will update automatically once the season table goes live.',
              style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _GhostStandingRow extends StatelessWidget {
  const _GhostStandingRow({
    required this.shimmer,
    required this.index,
    this.highlight = false,
  });

  final AnimationController shimmer;
  final int index;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, _) {
        final phase = (shimmer.value + index * 0.12) % 1.0;
        final shimmerPaint = _shimmerAlignment(phase);

        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: highlight
                ? DarColors.accentRed.withValues(alpha: 0.08)
                : DarColors.surface.withValues(alpha: 0.45),
            border: Border.all(
              color: highlight
                  ? DarColors.accentRed.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              _shimmerBox(width: 28, height: 28, radius: 14, alignment: shimmerPaint),
              const SizedBox(width: 10),
              Expanded(
                child: _shimmerBox(width: double.infinity, height: 12, radius: 6, alignment: shimmerPaint),
              ),
              const SizedBox(width: 10),
              _shimmerBox(width: 18, height: 12, radius: 4, alignment: shimmerPaint),
              const SizedBox(width: 10),
              _shimmerBox(width: 18, height: 12, radius: 4, alignment: shimmerPaint),
              const SizedBox(width: 10),
              _shimmerBox(width: 22, height: 12, radius: 4, alignment: shimmerPaint),
            ],
          ),
        );
      },
    );
  }

  Alignment _shimmerAlignment(double phase) {
    final x = math.cos(phase * math.pi * 2) * 0.8;
    return Alignment(x, 0);
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
    required Alignment alignment,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: alignment,
          end: -alignment,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }
}
