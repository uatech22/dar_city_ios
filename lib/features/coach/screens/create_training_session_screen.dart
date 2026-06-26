import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class CreateTrainingSessionScreen extends StatefulWidget {
  const CreateTrainingSessionScreen({super.key, this.sessionToEdit});

  final TrainingSession? sessionToEdit;

  bool get isEditing => sessionToEdit != null;

  @override
  State<CreateTrainingSessionScreen> createState() =>
      _CreateTrainingSessionScreenState();
}

class _CreateTrainingSessionScreenState extends State<CreateTrainingSessionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _focusController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _scheduledAt;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _type;
  String? _intensity;
  bool _submitting = false;

  late AnimationController _entrance;
  late AnimationController _ambient;
  late AnimationController _orbit;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    final session = widget.sessionToEdit;
    if (session != null) {
      _titleController.text = session.title;
      _locationController.text = session.location;
      _focusController.text = session.focus ?? '';
      _descriptionController.text = session.description ?? '';
      if (session.durationMinutes != null) {
        _durationController.text = session.durationMinutes.toString();
      }
      _scheduledAt = parseTrainingSessionDate(session.scheduledAt);
      _startDate = parseTrainingSessionDate(session.startDate);
      _endDate = parseTrainingSessionDate(session.endDate);
      _type = session.type;
      _intensity = session.intensity;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _orbit.dispose();
    _pulse.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _focusController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: DarColors.muted.withValues(alpha: 0.7)),
      prefixIcon: icon != null
          ? Icon(icon, color: DarColors.accentRed.withValues(alpha: 0.85), size: 20)
          : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      counterStyle: TextStyle(color: DarColors.muted.withValues(alpha: 0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.65)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DarColors.accentRed.withValues(alpha: 0.9)),
      ),
    );
  }

  Future<void> _pickScheduledDateTime() async {
    final initial = _scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) _endDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTimeLabel(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final minutes = int.tryParse(value.trim());
    if (minutes == null) return 'Enter a valid number';
    if (minutes < 10) return 'Minimum 10 minutes';
    return null;
  }

  CreateTrainingSessionPayload _buildPayload() {
    final durationText = _durationController.text.trim();
    final durationMinutes = durationText.isEmpty ? null : int.parse(durationText);

    return CreateTrainingSessionPayload(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      scheduledAt: _scheduledAt?.toUtc().toIso8601String(),
      focus: _emptyToNull(_focusController.text),
      description: _emptyToNull(_descriptionController.text),
      startDate: _startDate != null ? _formatDate(_startDate!) : null,
      endDate: _endDate != null ? _formatDate(_endDate!) : null,
      durationMinutes: durationMinutes,
      intensity: _intensity,
      type: _type,
      teamId: widget.sessionToEdit?.teamId,
      coachId: widget.sessionToEdit?.coachId,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate != null &&
        _startDate != null &&
        _endDate!.isBefore(_startDate!)) {
      showFeatureSnackBar(
        context,
        'End date must be on or after start date',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = _buildPayload();
      if (widget.isEditing) {
        await CoachTrainingSessionService.updateSession(
          widget.sessionToEdit!.id,
          payload,
        );
      } else {
        await CoachTrainingSessionService.createSession(payload);
      }
      if (!mounted) return;
      showFeatureSnackBar(
        context,
        widget.isEditing ? 'Session updated' : 'Session created',
      );
      Navigator.pop(context, true);
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        Form(
        key: _formKey,
        child: CustomScrollView(
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
                            Colors.black.withValues(alpha: 0.6),
                            DarColors.background,
                          ],
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _ambient,
                      builder: (_, __) =>
                          CoachFloatingParticles(t: _ambient.value),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: CoachEntrance(
                        animation: _interval(0, 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _heroChip(editing),
                            const SizedBox(height: 8),
                            Text(
                              editing ? 'Edit Session' : 'New Session',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              editing
                                  ? 'Update your training block'
                                  : 'Schedule the next training block',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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
                  if (editing && widget.sessionToEdit!.metaLine != null)
                    CoachEntrance(
                      animation: _interval(0.08, 0.28),
                      child: _infoBanner(widget.sessionToEdit!.metaLine!),
                    ),
                  if (editing && widget.sessionToEdit!.metaLine != null)
                    const SizedBox(height: 18),
                  CoachEntrance(
                    animation: _interval(0.1, 0.32),
                    child: _sectionHeader('BASICS', Icons.info_outline_rounded),
                  ),
                  const SizedBox(height: 12),
                  CoachEntrance(
                    animation: _interval(0.14, 0.36),
                    child: _fieldCard(
                      child: Column(
                        children: [
                          _labeledField(
                            'Title *',
                            TextFormField(
                              controller: _titleController,
                              maxLength: 200,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                'e.g. Morning Shooting Drill',
                                icon: Icons.title_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeledField(
                            'Location *',
                            TextFormField(
                              controller: _locationController,
                              maxLength: 200,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                'e.g. Court A',
                                icon: Icons.location_on_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Location is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  CoachEntrance(
                    animation: _interval(0.2, 0.42),
                    child: _sectionHeader('SESSION TYPE', Icons.category_outlined),
                  ),
                  const SizedBox(height: 12),
                  CoachEntrance(
                    animation: _interval(0.24, 0.46),
                    child: _chipGroup(
                      options: trainingSessionTypes,
                      selected: _type,
                      onSelected: (v) => setState(() => _type = v),
                    ),
                  ),
                  const SizedBox(height: 22),
                  CoachEntrance(
                    animation: _interval(0.28, 0.5),
                    child: _sectionHeader('INTENSITY', Icons.speed_rounded),
                  ),
                  const SizedBox(height: 12),
                  CoachEntrance(
                    animation: _interval(0.32, 0.54),
                    child: _intensityChips(),
                  ),
                  const SizedBox(height: 22),
                  CoachEntrance(
                    animation: _interval(0.36, 0.58),
                    child: _sectionHeader('SCHEDULE', Icons.schedule_rounded),
                  ),
                  const SizedBox(height: 12),
                  CoachEntrance(
                    animation: _interval(0.4, 0.62),
                    child: _fieldCard(
                      child: Column(
                        children: [
                          _DatePickerTile(
                            label: _scheduledAt == null
                                ? 'Pick date & time (optional)'
                                : _formatDateTimeLabel(_scheduledAt!),
                            icon: Icons.event_rounded,
                            filled: _scheduledAt != null,
                            onTap: _pickScheduledDateTime,
                            onClear: _scheduledAt == null
                                ? null
                                : () => setState(() => _scheduledAt = null),
                          ),
                          const SizedBox(height: 10),
                          _labeledField(
                            'Duration (minutes)',
                            TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                'e.g. 90 (min 10)',
                                icon: Icons.timer_outlined,
                              ),
                              validator: _validateDuration,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DatePickerTile(
                            label: _startDate == null
                                ? 'Start date (optional)'
                                : _formatDate(_startDate!),
                            icon: Icons.calendar_today_rounded,
                            filled: _startDate != null,
                            onTap: () => _pickDate(isStart: true),
                            onClear: _startDate == null
                                ? null
                                : () => setState(() => _startDate = null),
                          ),
                          const SizedBox(height: 10),
                          _DatePickerTile(
                            label: _endDate == null
                                ? 'End date (optional)'
                                : _formatDate(_endDate!),
                            icon: Icons.event_available_rounded,
                            filled: _endDate != null,
                            onTap: () => _pickDate(isStart: false),
                            onClear: _endDate == null
                                ? null
                                : () => setState(() => _endDate = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  CoachEntrance(
                    animation: _interval(0.46, 0.68),
                    child: _sectionHeader('SESSION PLAN', Icons.description_outlined),
                  ),
                  const SizedBox(height: 12),
                  CoachEntrance(
                    animation: _interval(0.5, 0.72),
                    child: AnimatedBuilder(
                      animation: _orbit,
                      builder: (context, child) => CoachSweepBorder(
                        t: _orbit.value,
                        radius: 18,
                        child: child!,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DarColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _labeledField(
                              'Focus',
                              TextFormField(
                                controller: _focusController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  'e.g. Pick and roll, transition defense',
                                  icon: Icons.center_focus_strong_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _labeledField(
                              'Description',
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  'Session plan, notes for players...',
                                  icon: Icons.notes_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  CoachEntrance(
                    animation: _interval(0.58, 0.82),
                    child: _submitButton(editing),
                  ),
                  const SizedBox(height: 16),
                  CoachEntrance(
                    animation: _interval(0.64, 0.88),
                    child: _footerBadge(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _heroChip(bool editing) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final pulse = 0.5 + math.sin(_ambient.value * math.pi * 2) * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.12 + pulse * 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.4 + pulse * 0.2),
            ),
          ),
          child: Text(
            editing ? 'EDIT MODE' : 'CREATE MODE',
            style: const TextStyle(
              color: DarColors.accentRed,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: DarColors.accentRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
    return CoachSectionHeaderAnimated(
      label: label,
      icon: icon,
      animation: _interval(0.1, 0.35),
    );
  }

  Widget _fieldCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _labeledField(String label, Widget field) {
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
        field,
      ],
    );
  }

  Widget _chipGroup({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? DarColors.accentRed.withValues(alpha: 0.18)
                  : DarColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? DarColors.accentRed.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              option[0].toUpperCase() + option.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.white : DarColors.muted,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _intensityChips() {
    const colors = {
      'low': Color(0xFF66BB6A),
      'medium': Color(0xFFFFAA44),
      'high': DarColors.accentRed,
    };
    return Row(
      children: trainingSessionIntensities.map((level) {
        final isSelected = _intensity == level;
        final color = colors[level] ?? DarColors.accentRed;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: level != trainingSessionIntensities.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _intensity = level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : DarColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      switch (level) {
                        'high' => Icons.local_fire_department_rounded,
                        'medium' => Icons.bolt_rounded,
                        _ => Icons.eco_rounded,
                      },
                      color: isSelected ? color : DarColors.muted,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? color : DarColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _submitButton(bool editing) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submitting ? null : _submit,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DarColors.accentRed.withValues(alpha: 0.85 + _pulse.value * 0.1),
                    DarColors.accentRed.withValues(alpha: 0.6 + _pulse.value * 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DarColors.accentRed.withValues(alpha: 0.3 + _pulse.value * 0.15),
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
          if (_submitting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(
              editing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          const SizedBox(width: 8),
          Text(
            _submitting
                ? (editing ? 'SAVING...' : 'CREATING...')
                : (editing ? 'SAVE CHANGES' : 'CREATE SESSION'),
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
                'DAR CITY · SESSION BUILDER',
                style: TextStyle(
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

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.onTap,
    required this.icon,
    this.onClear,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? DarColors.accentRed.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: DarColors.accentRed.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled
                  ? DarColors.accentRed.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: DarColors.accentRed, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: DarColors.muted.withValues(alpha: 0.8), size: 18),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
