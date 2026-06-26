import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';

/// Ambient motion for fan screens — drifting blobs, no list entrances.
class FanMotion {
  FanMotion(TickerProvider vsync) {
    ambient = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    pulse = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  late final AnimationController ambient;
  late final AnimationController pulse;

  void dispose() {
    ambient.dispose();
    pulse.dispose();
  }
}

class FanHeroCard extends StatelessWidget {
  const FanHeroCard({
    super.key,
    required this.motion,
    required this.badge,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.chips = const [],
    this.compact = false,
    this.minimal = false,
  });

  final FanMotion motion;
  final String badge;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> chips;
  final bool compact;
  /// Slim top strip — keeps blobs but frees vertical space on phones.
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([motion.pulse, motion.ambient]),
      builder: (context, child) {
        final glow = minimal
            ? 0.08 + motion.pulse.value * 0.1
            : 0.12 + motion.pulse.value * 0.22;
        return Container(
          padding: minimal
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : EdgeInsets.fromLTRB(20, compact ? 16 : 22, 20, compact ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(minimal ? 14 : 20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DarColors.accentRed.withValues(
                  alpha: (minimal ? 0.22 : 0.38) + motion.pulse.value * 0.1,
                ),
                DarColors.surface,
                DarColors.background,
              ],
            ),
            border: Border.all(
              color: DarColors.accentRed.withValues(
                alpha: (minimal ? 0.2 : 0.32) + motion.pulse.value * 0.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: glow),
                blurRadius: minimal ? 16 : 32,
                spreadRadius: -6,
                offset: Offset(0, minimal ? 4 : 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CoachFloatingParticles(
                  t: motion.ambient.value,
                  pulse: motion.pulse.value,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: minimal ? _minimalContent() : _fullContent(),
    );
  }

  Widget _minimalContent() {
    return Row(
      children: [
        _badge(badge, tiny: true),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          SizedBox(width: 28, height: 28, child: trailing),
        ],
      ],
    );
  }

  Widget _fullContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _badge(badge),
              SizedBox(height: compact ? 10 : 14),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  height: 1.05,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.95),
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 6, children: chips),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }

  Widget _badge(String label, {bool tiny = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? 8 : 12,
        vertical: tiny ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DarColors.accentRed,
          fontSize: tiny ? 8 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: tiny ? 1.0 : 1.5,
        ),
      ),
    );
  }
}

class FanLiveChip extends StatelessWidget {
  const FanLiveChip({super.key, required this.motion, this.label = 'LIVE'});

  final FanMotion motion;
  final String label;

  @override
  Widget build(BuildContext context) {
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
              Text(
                label,
                style: const TextStyle(
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
}

class FanSectionHeader extends StatelessWidget {
  const FanSectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: DarColors.accentRed, size: 16),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: DarColors.accentRed,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: DarColors.accentRed,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.6),
            ),
          ),
      ],
    );
  }
}

class FanPremiumTile extends StatelessWidget {
  const FanPremiumTile({
    super.key,
    this.onTap,
    required this.child,
    this.highlight = false,
    this.accentColor = DarColors.accentRed,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool highlight;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? accentColor.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FanFilterChip extends StatelessWidget {
  const FanFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? DarColors.accentRed : DarColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? DarColors.accentRed
                    : Colors.white.withValues(alpha: 0.1),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: DarColors.accentRed.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : DarColors.muted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FanEmptyState extends StatelessWidget {
  const FanEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: DarColors.muted.withValues(alpha: 0.55), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class FanHubHeader extends StatelessWidget {
  const FanHubHeader({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.accentRed.withValues(alpha: 0.45),
            Colors.black,
            DarColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge,
                style: TextStyle(
                  color: DarColors.accentRed.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: DarColors.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class FanSearchField extends StatelessWidget {
  const FanSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DarColors.muted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: DarColors.muted.withValues(alpha: 0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Pulsing accent panel for shop hero / promos.
class FanAccentPanel extends StatelessWidget {
  const FanAccentPanel({
    super.key,
    required this.motion,
    required this.child,
    this.compact = false,
  });

  final FanMotion motion;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([motion.pulse, motion.ambient]),
      builder: (context, child) {
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(compact ? 10 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.cardDark,
                DarColors.accentRed.withValues(alpha: 0.14 + motion.pulse.value * 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.22 + motion.pulse.value * 0.15),
            ),
          ),
          child: Stack(
            children: [
              if (!compact)
                Positioned(
                  right: -16,
                  top: -8 + math.sin(motion.ambient.value * math.pi * 2) * 6,
                  child: Transform.scale(
                    scale: 0.9 + motion.pulse.value * 0.1,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DarColors.accentRed.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: child,
    );
  }
}
