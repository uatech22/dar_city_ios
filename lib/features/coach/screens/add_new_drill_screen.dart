import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/coach/widgets/training_session_picker.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class AddNewDrillScreen extends StatefulWidget {
  const AddNewDrillScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AddNewDrillScreen> createState() => _AddNewDrillScreenState();
}

class _AddNewDrillScreenState extends State<AddNewDrillScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _setupController = TextEditingController();
  final _executionController = TextEditingController();
  String _priority = 'Medium';
  String? _trainingId;
  bool _submitting = false;
  late CoachDrillsMotion _motion;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
  }

  @override
  void dispose() {
    _motion.dispose();
    _nameController.dispose();
    _objectiveController.dispose();
    _equipmentController.dispose();
    _setupController.dispose();
    _executionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_trainingId == null) {
      showFeatureSnackBar(context, 'Select a training session', isError: true);
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      showFeatureSnackBar(context, 'Enter a drill name', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await CoachDrillService.createDrill(
        CreateDrillPayload(
          name: _nameController.text.trim(),
          objective: _objectiveController.text.trim(),
          equipment: _equipmentController.text.trim(),
          setupInstructions: _setupController.text.trim(),
          executionSteps: _executionController.text.trim(),
          priority: _priority,
          trainingId: _trainingId!,
        ),
      );
      if (!mounted) return;
      showFeatureSnackBar(context, 'Drill saved');
      Navigator.of(context).pop();
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: DarColors.muted.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: coachDrillsFieldDecoration('', icon: icon),
        ),
      ],
    );
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
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/ground.jpg', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: DarColors.surface)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DarColors.accentRed.withValues(alpha: 0.42),
                          Colors.black.withValues(alpha: 0.6),
                          DarColors.background,
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _motion.ambient,
                    builder: (_, __) => CoachFloatingParticles(t: _motion.ambient.value),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CREATE MODE',
                          style: TextStyle(
                            color: DarColors.accentRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'New Drill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Add to your drill library',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CoachDrillsSectionCard(
                  label: 'Session',
                  child: TrainingSessionPicker(
                    required: true,
                    label: 'Training Session',
                    hint: 'Select a training session',
                    selectedTrainingId: _trainingId,
                    onChanged: (id) => setState(() => _trainingId = id),
                  ),
                ),
                const SizedBox(height: 16),
                CoachDrillsSectionCard(
                  label: 'Drill Info',
                  child: Column(
                    children: [
                      _field('Drill Name', _nameController, icon: Icons.title_rounded),
                      const SizedBox(height: 14),
                      _field('Objective / Purpose', _objectiveController,
                          maxLines: 3, icon: Icons.flag_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CoachDrillsSectionCard(
                  label: 'Priority',
                  child: Row(
                    children: ['Low', 'Medium', 'High'].map((level) {
                      final selected = _priority == level;
                      final color = switch (level) {
                        'High' => DarColors.accentRed,
                        'Low' => const Color(0xFF66BB6A),
                        _ => const Color(0xFFFFAA44),
                      };
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: level != 'High' ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? color.withValues(alpha: 0.55)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                level.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected ? color : DarColors.muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                CoachDrillsSectionCard(
                  label: 'Drill Plan',
                  child: Column(
                    children: [
                      _field('Equipment', _equipmentController,
                          maxLines: 3, icon: Icons.inventory_2_outlined),
                      const SizedBox(height: 14),
                      _field('Setup Instructions', _setupController,
                          maxLines: 3, icon: Icons.build_outlined),
                      const SizedBox(height: 14),
                      _field('Step-by-Step Execution', _executionController,
                          maxLines: 4, icon: Icons.list_alt_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CoachDrillsSubmitButton(
                  motion: _motion,
                  label: 'SAVE DRILL',
                  loadingLabel: 'SAVING...',
                  loading: _submitting,
                  onPressed: _save,
                  icon: Icons.save_rounded,
                ),
                const SizedBox(height: 16),
                CoachDrillsFooterBadge(motion: _motion, text: 'DAR CITY · DRILL BUILDER'),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
