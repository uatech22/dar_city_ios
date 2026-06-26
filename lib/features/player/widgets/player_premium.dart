import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';

/// Standard player sub-screen shell (black app bar, red accent).
class PlayerScreenScaffold extends StatelessWidget {
  const PlayerScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.maxBodyWidth,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final double? maxBodyWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: actions,
      ),
      body: darResponsiveBody(body, maxWidth: maxBodyWidth),
    );
  }
}

/// Notes / optional text area styling for player forms.
class PlayerNotesBox extends StatelessWidget {
  const PlayerNotesBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

/// Pinned bottom action bar for player forms.
class PlayerSubmitBar extends StatelessWidget {
  const PlayerSubmitBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = DarLayoutMetrics.of(context).horizontalPadding;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(h, 12, h, 16),
        decoration: BoxDecoration(
          color: DarColors.background,
          border: Border(top: BorderSide(color: DarColors.muted.withValues(alpha: 0.12))),
        ),
        child: child,
      ),
    );
  }
}

/// Ambient motion for player screens — blobs & pulsing borders only (no list entrances).
class PlayerMotion {
  PlayerMotion(TickerProvider vsync) {
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

class PlayerHeroCard extends StatelessWidget {
  const PlayerHeroCard({
    super.key,
    required this.motion,
    required this.badge,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.chips = const [],
  });

  final PlayerMotion motion;
  final String badge;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> chips;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(badge),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DarColors.muted.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
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
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DarColors.accentRed,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class PlayerSectionHeader extends StatelessWidget {
  const PlayerSectionHeader({
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

class PlayerStatCard extends StatelessWidget {
  const PlayerStatCard({
    super.key,
    required this.motion,
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final PlayerMotion motion;
  final int index;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        child: AnimatedBuilder(
          animation: Listenable.merge([motion.pulse, motion.ambient]),
          builder: (context, child) {
            return Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [DarColors.cardDark, DarColors.surface, DarColors.cardDark],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.22 + motion.pulse.value * 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08 + motion.pulse.value * 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CoachCardBlobs(
                      t: motion.ambient.value,
                      pulse: motion.pulse.value,
                      index: index,
                      color: color,
                    ),
                  ),
                  child!,
                ],
              ),
            );
          },
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: DarColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

class PlayerPremiumTile extends StatelessWidget {
  const PlayerPremiumTile({
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

class PlayerEmptyState extends StatelessWidget {
  const PlayerEmptyState({
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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: DarColors.muted.withValues(alpha: 0.55), size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class PlayerHubHeader extends StatelessWidget {
  const PlayerHubHeader({
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

class PlayerFilterChip extends StatelessWidget {
  const PlayerFilterChip({
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? DarColors.accentRed : DarColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? DarColors.accentRed
                    : Colors.white.withValues(alpha: 0.1),
              ),
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

/// Premium status filter rail for assigned drills — icons, counts, glow selection.
class PlayerDrillStatusFilterRail extends StatefulWidget {
  const PlayerDrillStatusFilterRail({
    super.key,
    required this.motion,
    required this.summary,
    required this.selectedStatus,
    required this.onSelected,
  });

  final PlayerMotion motion;
  final PlayerDrillSummary summary;
  final String? selectedStatus;
  final ValueChanged<String?> onSelected;

  @override
  State<PlayerDrillStatusFilterRail> createState() =>
      _PlayerDrillStatusFilterRailState();
}

class _PlayerDrillStatusFilterRailState extends State<PlayerDrillStatusFilterRail> {
  static const _filters = <_DrillFilterSpec>[
    _DrillFilterSpec(status: null, label: 'All', icon: Icons.grid_view_rounded),
    _DrillFilterSpec(
      status: 'pending',
      label: 'Pending',
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFF9E9E9E),
    ),
    _DrillFilterSpec(
      status: 'in_progress',
      label: 'In progress',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB020),
    ),
    _DrillFilterSpec(
      status: 'completed',
      label: 'Completed',
      icon: Icons.verified_rounded,
      color: DarColors.greenBright,
    ),
    _DrillFilterSpec(
      status: 'overdue',
      label: 'Overdue',
      icon: Icons.local_fire_department_rounded,
      color: DarColors.accentRed,
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _maxScrollExtent = 0;
  double _viewportDimension = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollMetrics);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollMetrics());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncScrollMetrics);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncScrollMetrics() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nextOffset = position.pixels;
    final nextMax = position.maxScrollExtent;
    final nextViewport = position.viewportDimension;
    if (nextOffset == _scrollOffset &&
        nextMax == _maxScrollExtent &&
        nextViewport == _viewportDimension) {
      return;
    }
    setState(() {
      _scrollOffset = nextOffset;
      _maxScrollExtent = nextMax;
      _viewportDimension = nextViewport;
    });
  }

  int _countFor(String? status) {
    if (status == null) return widget.summary.total;
    return switch (status) {
      'pending' => widget.summary.pending,
      'in_progress' => widget.summary.inProgress,
      'completed' => widget.summary.completed,
      'overdue' => widget.summary.overdue,
      _ => 0,
    };
  }

  bool get _isScrollable => _maxScrollExtent > 4;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.motion.pulse,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                DarColors.accentRed.withValues(
                  alpha: 0.22 + widget.motion.pulse.value * 0.06,
                ),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(
                  alpha: 0.08 + widget.motion.pulse.value * 0.06,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.2),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: DarColors.accentRed.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FILTER BY STATUS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.summary.total} drills',
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 88,
                  child: Stack(
                    children: [
                      ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final spec = _filters[index];
                          final selected = widget.selectedStatus == spec.status;
                          final count = _countFor(spec.status);
                          final accent = spec.color ?? DarColors.accentRed;

                          return _DrillFilterPill(
                            spec: spec,
                            count: count,
                            selected: selected,
                            accent: accent,
                            pulse: widget.motion.pulse.value,
                            onTap: () => widget.onSelected(spec.status),
                          );
                        },
                      ),
                      if (_isScrollable && _scrollOffset > 6)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 28,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    const Color(0xFF0D0D0F),
                                    const Color(0xFF0D0D0F).withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isScrollable &&
                          _scrollOffset < _maxScrollExtent - 6)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 36,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    const Color(0xFF0D0D0F),
                                    const Color(0xFF0D0D0F).withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _HorizontalScrollHintBar(
                  scrollOffset: _scrollOffset,
                  maxScrollExtent: _maxScrollExtent,
                  viewportDimension: _viewportDimension,
                  pulse: widget.motion.pulse.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Track + thumb under horizontal filters — shows swipe affordance.
class _HorizontalScrollHintBar extends StatelessWidget {
  const _HorizontalScrollHintBar({
    required this.scrollOffset,
    required this.maxScrollExtent,
    required this.viewportDimension,
    required this.pulse,
  });

  final double scrollOffset;
  final double maxScrollExtent;
  final double viewportDimension;
  final double pulse;

  bool get _isScrollable => maxScrollExtent > 4;

  @override
  Widget build(BuildContext context) {
    if (!_isScrollable) {
      return const SizedBox(height: 10);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_left_alt_rounded,
                size: 15,
                color: DarColors.muted.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Text(
                'Swipe horizontally for more filters',
                style: TextStyle(
                  color: DarColors.muted.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.swipe_right_alt_rounded,
                size: 15,
                color: DarColors.muted.withValues(alpha: 0.75),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final contentWidth = maxScrollExtent + viewportDimension;
              final thumbWidth =
                  (trackWidth * (viewportDimension / contentWidth)).clamp(52.0, trackWidth);
              final travel = trackWidth - thumbWidth;
              final thumbLeft =
                  maxScrollExtent > 0 ? (scrollOffset / maxScrollExtent) * travel : 0.0;

              return SizedBox(
                height: 5,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      left: thumbLeft,
                      width: thumbWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              DarColors.accentRed.withValues(alpha: 0.95),
                              DarColors.accentRed.withValues(alpha: 0.55 + pulse * 0.15),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DarColors.accentRed.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrillFilterSpec {
  const _DrillFilterSpec({
    required this.status,
    required this.label,
    required this.icon,
    this.color,
  });

  final String? status;
  final String label;
  final IconData icon;
  final Color? color;
}

class _DrillFilterPill extends StatelessWidget {
  const _DrillFilterPill({
    required this.spec,
    required this.count,
    required this.selected,
    required this.accent,
    required this.pulse,
    required this.onTap,
  });

  final _DrillFilterSpec spec;
  final int count;
  final bool selected;
  final Color accent;
  final double pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = selected ? 0.28 + pulse * 0.18 : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.2),
        highlightColor: accent.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 108,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.95),
                      accent.withValues(alpha: 0.55),
                      accent.withValues(alpha: 0.35),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: glow),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    spec.icon,
                    size: 16,
                    color: selected ? Colors.white : accent.withValues(alpha: 0.9),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.35)
                            : accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? Colors.white : accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 5),
                Container(
                  height: 2,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        blurRadius: 6,
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

class PlayerLiveChip extends StatelessWidget {
  const PlayerLiveChip({super.key, required this.motion});

  final PlayerMotion motion;

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
}

/// Pulsing accent card — training progress, salary impact, etc.
class PlayerAccentCard extends StatelessWidget {
  const PlayerAccentCard({
    super.key,
    required this.motion,
    required this.child,
    this.onTap,
  });

  final PlayerMotion motion;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: DarColors.accentRed.withValues(alpha: 0.15),
        child: AnimatedBuilder(
          animation: Listenable.merge([motion.pulse, motion.ambient]),
          builder: (context, child) {
            return Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DarColors.cardDark,
                    DarColors.accentRed.withValues(alpha: 0.14 + motion.pulse.value * 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DarColors.accentRed.withValues(alpha: 0.22 + motion.pulse.value * 0.15),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -10 + math.sin(motion.ambient.value * math.pi * 2) * 6,
                    child: Transform.scale(
                      scale: 0.9 + motion.pulse.value * 0.12,
                      child: Container(
                        width: 80,
                        height: 80,
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
        ),
      ),
    );
  }
}
