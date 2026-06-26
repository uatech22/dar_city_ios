import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';

/// Shared motion controllers for coach drill screens.
class CoachDrillsMotion {
  CoachDrillsMotion(TickerProvider vsync) {
    entrance = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1800),
    );
    ambient = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    pulse = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    orbit = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    shimmer = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  late final AnimationController entrance;
  late final AnimationController ambient;
  late final AnimationController pulse;
  late final AnimationController orbit;
  late final AnimationController shimmer;

  void dispose() {
    entrance.dispose();
    ambient.dispose();
    pulse.dispose();
    orbit.dispose();
    shimmer.dispose();
  }

  Animation<double> interval(double begin, double end, {Curve curve = Curves.easeOutCubic}) {
    return CurvedAnimation(
      parent: entrance,
      curve: Interval(begin, end, curve: curve),
    );
  }

  void replayEntrance() => entrance.forward(from: 0);
}

class CoachDrillsHero extends StatelessWidget {
  const CoachDrillsHero({
    super.key,
    required this.motion,
    required this.badge,
    required this.title,
    required this.subtitle,
    this.stats = const [],
  });

  final CoachDrillsMotion motion;
  final String badge;
  final String title;
  final String subtitle;
  final List<({String value, String label})> stats;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([motion.pulse, motion.ambient]),
      builder: (context, child) {
        final glow = 0.12 + motion.pulse.value * 0.22;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DarColors.accentRed.withValues(alpha: 0.35 + motion.pulse.value * 0.1),
                DarColors.surface,
                DarColors.background,
              ],
            ),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.32 + motion.pulse.value * 0.1),
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
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([motion.pulse, motion.ambient]),
                  builder: (context, _) {
                    return CoachFloatingParticles(
                      t: motion.ambient.value,
                      pulse: motion.pulse.value,
                    );
                  },
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
              _chip(badge, Icons.sports_basketball_rounded),
              const SizedBox(width: 8),
              _liveChip(motion),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.95),
              fontSize: 14,
            ),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _statPill(motion, stats[i].value, stats[i].label),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
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

  Widget _liveChip(CoachDrillsMotion motion) {
    return AnimatedBuilder(
      animation: motion.pulse,
      builder: (context, _) {
        final glow = 0.4 + motion.pulse.value * 0.6;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12 + motion.pulse.value * 0.08),
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

  Widget _statPill(CoachDrillsMotion motion, String value, String label) {
    return Container(
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
    );
  }
}

class CoachDrillsStaticHeader extends StatelessWidget {
  const CoachDrillsStaticHeader({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
}

class CoachDrillsAnimatedFab extends StatelessWidget {
  const CoachDrillsAnimatedFab({
    super.key,
    required this.motion,
    required this.onPressed,
    required this.heroTag,
    this.icon = Icons.add_rounded,
  });

  final CoachDrillsMotion motion;
  final VoidCallback onPressed;
  final Object heroTag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion.pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + motion.pulse.value * 0.06,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DarColors.accentRed.withValues(
                    alpha: 0.35 + motion.pulse.value * 0.2,
                  ),
                  blurRadius: 20 + motion.pulse.value * 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: DarColors.accentRed,
        elevation: 0,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Static list card — no entrance or sweep animations.
class CoachDrillsStaticTile extends StatelessWidget {
  const CoachDrillsStaticTile({
    super.key,
    this.onTap,
    required this.child,
    this.highlight = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: DarColors.accentRed.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? DarColors.accentRed.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class CoachDrillsSweepTile extends StatelessWidget {
  const CoachDrillsSweepTile({
    super.key,
    required this.motion,
    required this.index,
    this.onTap,
    required this.child,
    this.highlight = false,
  });

  final CoachDrillsMotion motion;
  final int index;
  final VoidCallback? onTap;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: DarColors.accentRed.withValues(alpha: 0.18),
        child: AnimatedBuilder(
          animation: motion.orbit,
          builder: (context, tileChild) {
            return CoachSweepBorder(
              t: motion.orbit.value + index * 0.12,
              radius: 16,
              child: tileChild!,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DarColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlight
                    ? DarColors.accentRed.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CoachDrillsActionTile extends StatelessWidget {
  const CoachDrillsActionTile({
    super.key,
    required this.motion,
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final CoachDrillsMotion motion;
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                  child: Icon(icon, color: DarColors.accentRed, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.95),
                          fontSize: 12,
                        ),
                      ),
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
      ),
    );
  }
}

class CoachDrillsEmptyState extends StatelessWidget {
  const CoachDrillsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: DarColors.accentRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CoachDrillsPriorityChip extends StatelessWidget {
  const CoachDrillsPriorityChip({super.key, required this.priority});

  final String priority;

  Color get _color {
    switch (priority.toLowerCase()) {
      case 'high':
        return DarColors.accentRed;
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFFFFAA44);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class CoachDrillsViewAllButton extends StatelessWidget {
  const CoachDrillsViewAllButton({
    super.key,
    required this.motion,
    required this.label,
    required this.onTap,
  });

  final CoachDrillsMotion motion;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion.shimmer,
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarColors.accentRed.withValues(
                    alpha: 0.35 + motion.shimmer.value * 0.25,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: DarColors.accentRed.withValues(
                    alpha: 0.85 + motion.shimmer.value * 0.15,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

InputDecoration coachDrillsFieldDecoration(String hint, {IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: DarColors.muted.withValues(alpha: 0.7)),
    prefixIcon: icon != null
        ? Icon(icon, color: DarColors.accentRed.withValues(alpha: 0.85), size: 20)
        : null,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.65)),
    ),
  );
}

class CoachDrillsSectionCard extends StatelessWidget {
  const CoachDrillsSectionCard({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: DarColors.accentRed.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class CoachDrillsSubmitButton extends StatelessWidget {
  const CoachDrillsSubmitButton({
    super.key,
    required this.motion,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.check_rounded,
  });

  final CoachDrillsMotion motion;
  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion.pulse,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DarColors.accentRed.withValues(alpha: 0.85 + motion.pulse.value * 0.1),
                    DarColors.accentRed.withValues(alpha: 0.6 + motion.pulse.value * 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DarColors.accentRed.withValues(
                      alpha: 0.3 + motion.pulse.value * 0.15,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            loading ? loadingLabel : label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class CoachDrillsFooterBadge extends StatelessWidget {
  const CoachDrillsFooterBadge({super.key, required this.motion, required this.text});

  final CoachDrillsMotion motion;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: motion.ambient,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, math.sin(motion.ambient.value * math.pi * 2) * 2),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 16),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: DarColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder<T> coachDrillsPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
