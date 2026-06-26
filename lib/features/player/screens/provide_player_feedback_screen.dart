import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/player/models/player_feedback.dart';
import 'package:dar_city_app/features/player/services/player_feedback_service.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/models/person.dart';

const _maxFeedbackLength = 2000;
const _minFeedbackLength = 10;

const _categoryIcons = <String, IconData>{
  'Training Session': Icons.sports_basketball_rounded,
  'Drill Assignment': Icons.fitness_center_rounded,
  'Team Communication': Icons.forum_rounded,
  'Facilities': Icons.location_city_rounded,
  'Recovery & Rest': Icons.spa_rounded,
  'Other': Icons.more_horiz_rounded,
};

class ProvidePlayerFeedbackScreen extends StatefulWidget {
  const ProvidePlayerFeedbackScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProvidePlayerFeedbackScreen> createState() =>
      _ProvidePlayerFeedbackScreenState();
}

class _ProvidePlayerFeedbackScreenState extends State<ProvidePlayerFeedbackScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _feedbackFocus = FocusNode();
  late PlayerMotion _motion;

  String _category = playerFeedbackCategories.first;
  int? _coachId;
  bool _submitting = false;
  late Future<List<Person>> _coachesFuture;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _coachesFuture = _loadCoaches();
    startAutoRefresh(_reloadCoaches);
    _feedbackFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocus.dispose();
    _motion.dispose();
    super.dispose();
  }

  Future<List<Person>> _loadCoaches() async {
    final coaches = await PlayerFeedbackService.fetchCoaches();
    if (coaches.isNotEmpty && mounted) {
      setState(() => _coachId = coaches.first.id);
      return coaches;
    }

    final fallbackId = await PlayerFeedbackService.resolveCoachId();
    if (fallbackId != null && mounted) {
      setState(() => _coachId = fallbackId);
    }
    return coaches;
  }

  Future<void> _reloadCoaches() async {
    final future = _loadCoaches();
    setState(() => _coachesFuture = future);
    await future;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await PlayerFeedbackService.submit(
        PlayerFeedbackPayload(
          category: _category,
          feedback: _feedbackController.text.trim(),
          coachId: _coachId,
        ),
      );
      if (!mounted) return;
      showFeatureSnackBar(context, 'Feedback sent — thank you!');
      _feedbackController.clear();
      Navigator.of(context).pop();
    } on FeatureApiException catch (e) {
      if (mounted) {
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } catch (e) {
      if (mounted) {
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Provide Feedback',
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: FeatureAsyncBody<List<Person>>(
          future: _coachesFuture,
          onRetry: () => setState(() => _coachesFuture = _loadCoaches()),
          builder: (context, coaches) {
            Person? selectedCoach;
            if (_coachId != null) {
              for (final coach in coaches) {
                if (coach.id == _coachId) {
                  selectedCoach = coach;
                  break;
                }
              }
            }
            selectedCoach ??= coaches.isNotEmpty ? coaches.first : null;

            return LayoutBuilder(
              builder: (context, constraints) {
                final layout = DarLayoutMetrics.of(context);
                final contentWidth = layout.contentWidthFor(
                  constraints.maxWidth,
                  cap: layout.formMaxWidth,
                );

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: layout.scrollPadding(top: 12, bottom: 16 + bottomInset),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _heroCard(selectedCoach),
                                  const SizedBox(height: 24),
                                  PlayerSectionHeader(
                                    label: 'Category',
                                    icon: Icons.category_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _categoryGrid(),
                                  if (coaches.length > 1) ...[
                                    const SizedBox(height: 24),
                                    PlayerSectionHeader(
                                      label: 'Send to',
                                      icon: Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    _coachPicker(coaches),
                                  ],
                                  const SizedBox(height: 24),
                                  PlayerSectionHeader(
                                    label: 'Your message',
                                    icon: Icons.edit_note_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _feedbackField(),
                                  const SizedBox(height: 8),
                                  _privacyNote(),
                                ],
                              ),
                            ),
                          ),
                          _submitBar(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _heroCard(Person? coach) {
    final coachName = coach?.fullName.trim();
    final subtitle = coachName != null && coachName.isNotEmpty
        ? 'Private message to $coachName'
        : 'Share thoughts with your coaching staff';

    return PlayerHeroCard(
      motion: _motion,
      badge: 'FEEDBACK',
      title: 'Your voice matters',
      subtitle: subtitle,
      trailing: coach != null
          ? DarPlayerAvatar(
              name: coach.fullName,
              size: 52,
              imageUrl: coach.image,
            )
          : null,
      chips: [PlayerLiveChip(motion: _motion)],
    );
  }

  Widget _categoryGrid() {
    final layout = DarLayoutMetrics.of(context);
    final crossAxisCount = layout.isWide ? 3 : (layout.isTablet ? 2 : 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: crossAxisCount >= 2 ? 2.8 : 4.2,
      ),
          itemCount: playerFeedbackCategories.length,
          itemBuilder: (_, i) {
            final category = playerFeedbackCategories[i];
            final selected = _category == category;
            final icon = _categoryIcons[category] ?? Icons.label_outline;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _category = category),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? DarColors.accentRed.withValues(alpha: 0.18)
                        : DarColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? DarColors.accentRed
                          : Colors.white.withValues(alpha: 0.08),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected ? DarColors.accentRedBright : DarColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: selected ? Colors.white : DarColors.mutedPink,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: DarColors.accentRedBright,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  Widget _coachPicker(List<Person> coaches) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coaches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final coach = coaches[i];
          final selected = _coachId == coach.id;
          return GestureDetector(
            onTap: () => setState(() => _coachId = coach.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? DarColors.accentRed.withValues(alpha: 0.15)
                    : DarColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? DarColors.accentRed : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  DarPlayerAvatar(
                    name: coach.fullName,
                    size: 36,
                    imageUrl: coach.image,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coach.fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _feedbackField() {
    return PlayerNotesBox(
      child: TextFormField(
        controller: _feedbackController,
        focusNode: _feedbackFocus,
        maxLines: null,
        minLines: 6,
        maxLength: _maxFeedbackLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 14),
        decoration: InputDecoration(
          hintText:
              'What went well? What could improve? Be specific so your coach can help.',
          hintStyle: TextStyle(color: DarColors.muted, height: 1.4, fontSize: 13),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.5)),
          ),
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(color: DarColors.muted, fontSize: 11),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Please enter your feedback';
          if (text.length < _minFeedbackLength) {
            return 'At least $_minFeedbackLength characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _privacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 16, color: DarColors.muted.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sent directly to your coach. Only share what you are comfortable discussing.',
            style: TextStyle(color: DarColors.muted, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _submitBar() {
    return PlayerSubmitBar(
      child: DarPrimaryButton(
        label: _submitting ? 'Sending…' : 'Submit Feedback',
        icon: _submitting ? null : Icons.send_rounded,
        onPressed: _submitting ? null : _submit,
      ),
    );
  }
}
