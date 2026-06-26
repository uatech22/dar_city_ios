import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:flutter/material.dart';

/// Curves like [Curves.easeOutBack] / [Curves.elasticOut] may overshoot; clamp
/// before passing to another [Curve.transform] (Flutter asserts t ∈ [0, 1]).
double coachMotionT(double value, [Curve curve = Curves.easeOutCubic]) {
  return curve.transform(value.clamp(0.0, 1.0));
}

/// Choreographed entrance: fade + slide + scale + subtle 3D tilt.
class CoachEntrance extends StatelessWidget {
  const CoachEntrance({
    super.key,
    required this.animation,
    required this.child,
    this.slideFrom = const Offset(0, 0.12),
    this.tilt = 0.04,
    this.fromScale = 0.88,
  });

  final Animation<double> animation;
  final Widget child;
  final Offset slideFrom;
  final double tilt;
  final double fromScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Caller may pass easeOutBack/elastic interval — clamp before re-curving.
        final t = coachMotionT(animation.value);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(lerpDouble(tilt, 0, t)!)
          ..rotateY(lerpDouble(-tilt * 0.6, 0, t)!);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              slideFrom.dx * MediaQuery.sizeOf(context).width * (1 - t),
              slideFrom.dy * MediaQuery.sizeOf(context).height * (1 - t),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Transform.scale(
                scale: lerpDouble(fromScale, 1, t)!,
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Slowly drifting blobs for premium card backgrounds — move + scale over time.
class CoachFloatingParticles extends StatelessWidget {
  const CoachFloatingParticles({
    super.key,
    required this.t,
    this.pulse = 0,
    this.color = DarColors.accentRed,
  });

  final double t;
  final double pulse;
  final Color color;

  static const _seeds = [
    (0.12, 0.18, 14.0, 0.0),
    (0.78, 0.22, 10.0, 1.2),
    (0.55, 0.65, 18.0, 2.4),
    (0.25, 0.72, 8.0, 0.8),
    (0.88, 0.58, 12.0, 3.1),
    (0.38, 0.38, 9.0, 1.7),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final seed in _seeds)
              _animatedBlob(
                left: seed.$1 * c.maxWidth +
                    math.sin(t * math.pi * 2 + seed.$4) * 18,
                top: seed.$2 * c.maxHeight +
                    math.cos(t * math.pi * 2 + seed.$4) * 14,
                baseSize: seed.$3,
                phase: seed.$4,
              ),
          ],
        );
      },
    );
  }

  Widget _animatedBlob({
    required double left,
    required double top,
    required double baseSize,
    required double phase,
  }) {
    final scale = 0.82 +
        (math.sin(t * math.pi * 2 + phase) * 0.12) +
        (pulse * 0.08);
    final size = baseSize * scale;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.07 + (baseSize / 36)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18 + pulse * 0.12),
              blurRadius: size * 1.4,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}

/// Corner blobs inside stat / feature cards — offset per [index] so cards feel unique.
class CoachCardBlobs extends StatelessWidget {
  const CoachCardBlobs({
    super.key,
    required this.t,
    required this.pulse,
    required this.index,
    this.color = DarColors.accentRed,
  });

  final double t;
  final double pulse;
  final int index;
  final Color color;

  static const _layouts = [
    [(0.72, -0.08, 52.0, 0.0), (-0.12, 0.62, 38.0, 1.4), (0.38, 0.88, 28.0, 2.1)],
    [(-0.1, -0.06, 46.0, 0.6), (0.82, 0.48, 34.0, 1.9), (0.22, 0.78, 24.0, 2.8)],
    [(0.68, 0.72, 44.0, 1.1), (0.05, -0.04, 36.0, 2.3), (0.92, 0.18, 22.0, 0.4)],
  ];

  @override
  Widget build(BuildContext context) {
    final blobs = _layouts[index % _layouts.length];
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final blob in blobs)
              Positioned(
                left: blob.$1 * c.maxWidth +
                    math.sin(t * math.pi * 2 + blob.$4 + index) * 10,
                top: blob.$2 * c.maxHeight +
                    math.cos(t * math.pi * 2 + blob.$4 + index * 0.7) * 8,
                child: Transform.scale(
                  scale: 0.78 +
                      math.sin(t * math.pi * 2 + blob.$4) * 0.14 +
                      pulse * 0.1,
                  child: Container(
                    width: blob.$3,
                    height: blob.$3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1 + pulse * 0.06),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22 + pulse * 0.15),
                          blurRadius: blob.$3 * 0.85,
                          spreadRadius: blob.$3 * 0.05,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Rotating red sweep on card border.
class CoachSweepBorder extends StatelessWidget {
  const CoachSweepBorder({
    super.key,
    required this.t,
    required this.radius,
    required this.child,
    this.strokeWidth = 1.5,
  });

  final double t;
  final double radius;
  final Widget child;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SweepBorderPainter(t: t, radius: radius, strokeWidth: strokeWidth),
      child: child,
    );
  }
}

class _SweepBorderPainter extends CustomPainter {
  _SweepBorderPainter({
    required this.t,
    required this.radius,
    required this.strokeWidth,
  });

  final double t;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= strokeWidth || size.height <= strokeWidth) return;
    final rect = Offset.zero & size;
    if (rect.width <= 0 || rect.height <= 0) return;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final deflated = rrect.deflate(strokeWidth / 2);
    if (deflated.width <= 0 || deflated.height <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: t * math.pi * 2,
        colors: [
          DarColors.accentRed.withValues(alpha: 0.05),
          DarColors.accentRed.withValues(alpha: 0.85),
          DarColors.accentRed.withValues(alpha: 0.05),
          DarColors.accentRed.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.15, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRRect(deflated, paint);
  }

  @override
  bool shouldRepaint(_SweepBorderPainter old) => old.t != t;
}

/// Animated stat value with optional count-up for numeric strings.
class CoachAnimatedStatValue extends StatelessWidget {
  const CoachAnimatedStatValue({
    super.key,
    required this.value,
    required this.reveal,
    required this.shimmerT,
  });

  final String value;
  final Animation<double> reveal;
  final double shimmerT;

  double? _numericTarget() {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _format(double n) {
    if (value.contains('%')) return '${n.round()}%';
    if (value.contains('.')) return n.toStringAsFixed(1);
    return n.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final target = _numericTarget();
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final rt = coachMotionT(reveal.value);
        final display = target != null ? _format(target * rt) : value;
        return Text(
          display,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white.withValues(alpha: rt),
          ),
        );
      },
    );
  }
}

/// Pulsing ring beside stat values.
class CoachStatRing extends StatelessWidget {
  const CoachStatRing({
    super.key,
    required this.progress,
    required this.pulse,
    required this.up,
  });

  final double progress;
  final double pulse;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(52, 52),
      painter: _StatRingPainter(
        progress: progress,
        pulse: pulse,
        color: up ? DarColors.green : DarColors.accentRed,
      ),
    );
  }
}

class _StatRingPainter extends CustomPainter {
  _StatRingPainter({
    required this.progress,
    required this.pulse,
    required this.color,
  });

  final double progress;
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.08);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5 + pulse * 0.5);
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_StatRingPainter old) =>
      old.progress != progress || old.pulse != pulse;
}

/// Section header icon spins in with elastic clip reveal.
class CoachSectionHeaderAnimated extends StatelessWidget {
  const CoachSectionHeaderAnimated({
    super.key,
    required this.label,
    required this.icon,
    required this.animation,
  });

  final String label;
  final IconData icon;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = coachMotionT(animation.value, Curves.elasticOut);
        return Row(
          children: [
            Transform.rotate(
              angle: (1 - t) * -0.8,
              child: Transform.scale(
                scale: 0.4 + (0.6 * t),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DarColors.accentRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DarColors.accentRed, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: t.clamp(0.0, 1.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DarColors.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
