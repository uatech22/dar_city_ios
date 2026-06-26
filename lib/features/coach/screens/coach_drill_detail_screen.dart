import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';

/// Full drill view — premium Dar City red/black, static content (no list entrance).
class CoachDrillDetailScreen extends StatefulWidget {
  const CoachDrillDetailScreen({super.key, required this.drill});

  final Drill drill;

  @override
  State<CoachDrillDetailScreen> createState() => _CoachDrillDetailScreenState();
}

class _CoachDrillDetailScreenState extends State<CoachDrillDetailScreen>
    with TickerProviderStateMixin {
  late CoachDrillsMotion _motion;

  Drill get d => widget.drill;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
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
                    animation: _motion.ambient,
                    builder: (_, __) =>
                        CoachFloatingParticles(t: _motion.ambient.value),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _priorityChip(),
                        const SizedBox(height: 10),
                        Text(
                          d.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
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
                  if (d.category != null && d.category!.isNotEmpty)
                    _metaChip(Icons.category_outlined, d.category!),
                  ..._textSection('OBJECTIVE', d.objective),
                  ..._textSection('EQUIPMENT', d.equipment),
                  ..._textSection('SETUP', d.setupInstructions),
                  ..._textSection('EXECUTION', d.executionSteps),
                  const SizedBox(height: 20),
                  CoachDrillsFooterBadge(
                    motion: _motion,
                    text: 'DAR CITY · DRILL LIBRARY',
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

  List<Widget> _textSection(String label, String? text) {
    if (text == null || text.trim().isEmpty) return [];
    return [
      const SizedBox(height: 22),
      Text(
        label,
        style: TextStyle(
          color: DarColors.accentRed.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 10),
      _bodyCard(text.trim()),
    ];
  }

  Widget _bodyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _priorityChip() {
    if (d.priority == null || d.priority!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DarColors.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'DRILL',
          style: TextStyle(
            color: DarColors.accentRed,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      );
    }
    return CoachDrillsPriorityChip(priority: d.priority!);
  }

  Widget _metaChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DarColors.accentRed, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
