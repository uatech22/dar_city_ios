import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/widgets/dar_multi_select_field.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/models/drill.dart';
import 'package:dar_city_app/features/coach/services/coach_drill_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';
import 'package:dar_city_app/features/coach/widgets/coach_drills_premium.dart';
import 'package:dar_city_app/features/coach/widgets/training_session_picker.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/models/person.dart';

class AssignDrillsScreen extends StatefulWidget {
  const AssignDrillsScreen({
    super.key,
    this.embedded = false,
    this.initialTrainingId,
  });

  final bool embedded;
  final String? initialTrainingId;

  @override
  State<AssignDrillsScreen> createState() => _AssignDrillsScreenState();
}

class _AssignDrillsScreenState extends State<AssignDrillsScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<({List<Person> players, List<Drill> drills})> _dataFuture;
  late CoachDrillsMotion _motion;

  Set<int> _selectedPlayerIds = {};
  Set<String> _selectedDrillIds = {};
  DateTime _dueDate = DateTime.now();

  final _repsController = TextEditingController(text: '3');
  final _setsController = TextEditingController(text: '5');
  final _timeController = TextEditingController(text: '20');
  String? _trainingId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
    _trainingId = widget.initialTrainingId;
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = _fetchData();
    setState(() => _dataFuture = future);
    await future;
  }

  Future<({List<Person> players, List<Drill> drills})> _fetchData() async {
    final results = await Future.wait([
      CoachDrillService.fetchDrillRosterPlayers(),
      CoachDrillService.fetchDrills(),
    ]);
    return (
      players: results[0] as List<Person>,
      drills: sortDrillsNewestFirst(results[1] as List<Drill>),
    );
  }

  List<Drill> _drillsForSession(List<Drill> all) =>
      filterDrillsBySession(all, _trainingId);

  void _onTrainingSessionChanged(String? id, List<Drill> allDrills) {
    setState(() {
      _trainingId = id;
      if (id != null) {
        final allowed = _drillsForSession(allDrills).map((d) => d.id).toSet();
        _selectedDrillIds = _selectedDrillIds.intersection(allowed);
      }
    });
  }

  String get _dueDateIso => DateFormat('yyyy-MM-dd').format(_dueDate);

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _assign() async {
    if (_selectedPlayerIds.isEmpty || _selectedDrillIds.isEmpty) {
      showFeatureSnackBar(context, 'Select at least one player and one drill', isError: true);
      return;
    }
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;
    final sets = int.tryParse(_setsController.text.trim()) ?? 0;
    final time = int.tryParse(_timeController.text.trim()) ?? 0;
    if (reps <= 0 || sets <= 0 || time <= 0) {
      showFeatureSnackBar(context, 'Enter valid reps, sets, and time', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await CoachDrillService.assignDrills(
        AssignDrillsPayload(
          playerIds: _selectedPlayerIds.toList(),
          drillIds: _selectedDrillIds.toList(),
          reps: reps,
          sets: sets,
          timeMinutes: time,
          dueDate: _dueDateIso,
          trainingId: _trainingId,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<MultiSelectOption<int>> _playerOptions(List<Person> players) => players
      .map(
        (p) => MultiSelectOption(
          id: p.id,
          title: p.fullName.trim(),
          subtitle: '#${p.jerseyNumber ?? '—'} · ${p.position}',
          leading: DarPlayerAvatar(name: p.fullName, size: 40),
        ),
      )
      .toList();

  List<MultiSelectOption<String>> _drillOptions(List<Drill> drills) => drills
      .map(
        (d) => MultiSelectOption(
          id: d.id,
          title: d.name,
          subtitle: d.priority ?? 'Drill',
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 20),
          ),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        FeatureAsyncBody<({List<Person> players, List<Drill> drills})>(
        future: _dataFuture,
        onRetry: _load,
        builder: (context, data) {
          final sessionDrills = _drillsForSession(data.drills);
          final hasDrills = sessionDrills.isNotEmpty;
          final hasPlayers = data.players.isNotEmpty;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                expandedHeight: 170,
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
                            Text('ASSIGN MODE', style: TextStyle(color: DarColors.accentRed, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            SizedBox(height: 8),
                            Text('New Assignment', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            Text('Deploy drills to your squad', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    if (!hasPlayers) _banner('No players found for your team.', error: true),
                    if (!hasDrills)
                      _banner(
                        _trainingId == null
                            ? 'No drills yet — create drills first from the Drills tab.'
                            : 'No drills linked to this session.',
                        error: true,
                      ),
                    CoachDrillsSectionCard(
                      label: 'Session',
                      child: TrainingSessionPicker(
                        includeAllSessions: true,
                        label: 'Training Session',
                        hint: 'Select a training session',
                        selectedTrainingId: _trainingId,
                        onChanged: (id) => _onTrainingSessionChanged(id, data.drills),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsSectionCard(
                      label: 'Who',
                      child: DarMultiSelectField<int>(
                        label: 'Select Players',
                        placeholder: 'Tap to choose players',
                        searchHint: 'Search by name or position',
                        emptyMessage: 'No players match your search',
                        options: _playerOptions(data.players),
                        selectedIds: _selectedPlayerIds,
                        onChanged: (ids) => setState(() => _selectedPlayerIds = ids),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsSectionCard(
                      label: 'What',
                      child: DarMultiSelectField<String>(
                        label: 'Select Drills',
                        placeholder: 'Tap to choose drills',
                        searchHint: 'Search drills by name',
                        emptyMessage: 'No drills match your search',
                        options: _drillOptions(sessionDrills),
                        selectedIds: _selectedDrillIds,
                        onChanged: (ids) => setState(() => _selectedDrillIds = ids),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsSectionCard(
                      label: 'Parameters',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _numField('Reps', _repsController)),
                              const SizedBox(width: 10),
                              Expanded(child: _numField('Sets', _setsController)),
                              const SizedBox(width: 10),
                              Expanded(child: _numField('Minutes', _timeController)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: DarColors.accentRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: _pickDueDate,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: DarColors.accentRed, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateFormat('EEE, MMM d, yyyy').format(_dueDate),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: DarColors.muted.withValues(alpha: 0.8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CoachDrillsSubmitButton(
                      motion: _motion,
                      label: 'ASSIGN DRILLS',
                      loadingLabel: 'ASSIGNING...',
                      loading: _submitting,
                      onPressed: _submitting || !hasPlayers || !hasDrills ? null : _assign,
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsFooterBadge(motion: _motion, text: 'DAR CITY · SQUAD DEPLOY'),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: coachDrillsFieldDecoration(''),
        ),
      ],
    );
  }

  Widget _banner(String message, {bool error = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? DarColors.accentRed.withValues(alpha: 0.1) : DarColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: error ? 0.4 : 0.2)),
      ),
      child: Text(message, style: TextStyle(color: error ? DarColors.accentRed : DarColors.muted, fontSize: 13)),
    );
  }
}
