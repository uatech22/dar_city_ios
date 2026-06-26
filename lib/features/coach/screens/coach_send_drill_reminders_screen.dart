import 'package:flutter/material.dart';

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

class CoachSendDrillRemindersScreen extends StatefulWidget {
  const CoachSendDrillRemindersScreen({super.key, this.initialTrainingId});

  final String? initialTrainingId;

  @override
  State<CoachSendDrillRemindersScreen> createState() =>
      _CoachSendDrillRemindersScreenState();
}

class _CoachSendDrillRemindersScreenState extends State<CoachSendDrillRemindersScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<List<Drill>> _drillsFuture;
  late CoachDrillsMotion _motion;
  String? _trainingId;
  String? _selectedDrillId;
  Future<List<DrillReminderPlayer>>? _targetsFuture;
  final _messageController = TextEditingController();
  Set<int> _selectedPlayerIds = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _motion = CoachDrillsMotion(this);
    _trainingId = widget.initialTrainingId;
    _loadDrills();
    startAutoRefresh(_loadDrills);
  }

  @override
  void dispose() {
    _motion.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadDrills() async {
    final future = CoachDrillService.fetchDrills();
    setState(() => _drillsFuture = future);
    await future;
  }

  List<Drill> _drillsForSession(List<Drill> all) =>
      sortDrillsNewestFirst(filterDrillsBySession(all, _trainingId));

  void _onTrainingSessionChanged(String? id) {
    setState(() {
      _trainingId = id;
      _selectedDrillId = null;
      _selectedPlayerIds = {};
      _targetsFuture = null;
    });
  }

  void _selectDrill(String drillId) {
    setState(() {
      _selectedDrillId = drillId;
      _selectedPlayerIds = {};
      _targetsFuture = CoachDrillService.fetchReminderTargets(drillId);
    });
  }

  void _ensureDrillSelected(List<Drill> sessionDrills) {
    if (sessionDrills.isEmpty) return;
    final valid = _selectedDrillId != null &&
        sessionDrills.any((d) => d.id == _selectedDrillId);
    if (!valid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectDrill(sessionDrills.first.id);
      });
    }
  }

  List<MultiSelectOption<int>> _playerOptions(List<DrillReminderPlayer> players) =>
      players
          .map(
            (p) => MultiSelectOption(
              id: p.playerId,
              title: p.playerName,
              subtitle: p.status,
              leading: DarPlayerAvatar(name: p.playerName, size: 40),
            ),
          )
          .toList();

  Future<void> _send() async {
    if (_selectedDrillId == null || _selectedPlayerIds.isEmpty) {
      showFeatureSnackBar(context, 'Select a drill and at least one player', isError: true);
      return;
    }
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      showFeatureSnackBar(context, 'Enter a reminder message', isError: true);
      return;
    }

    setState(() => _sending = true);
    try {
      await CoachDrillService.sendReminders(
        drillId: _selectedDrillId!,
        message: message,
        playerIds: _selectedPlayerIds.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        FeatureAsyncBody<List<Drill>>(
        future: _drillsFuture,
        onRetry: _loadDrills,
        builder: (context, drills) {
          final sessionDrills = _drillsForSession(drills);
          _ensureDrillSelected(sessionDrills);
          final hasDrills = sessionDrills.isNotEmpty;
          Drill? selectedDrill;
          if (_selectedDrillId != null) {
            for (final drill in sessionDrills) {
              if (drill.id == _selectedDrillId) {
                selectedDrill = drill;
                break;
              }
            }
          }

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
                            Text('REMIND MODE', style: TextStyle(color: DarColors.accentRed, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            SizedBox(height: 8),
                            Text('Send Reminder', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            Text('Push players to finish their drills', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                        hint: 'All sessions',
                        selectedTrainingId: _trainingId,
                        onChanged: _onTrainingSessionChanged,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsSectionCard(
                      label: 'Drill',
                      child: hasDrills
                          ? DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedDrill?.id,
                              dropdownColor: DarColors.surface,
                              decoration: coachDrillsFieldDecoration('Select drill', icon: Icons.sports_basketball),
                              items: sessionDrills
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text(d.name, style: const TextStyle(color: Colors.white)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                if (id != null) _selectDrill(id);
                              },
                            )
                          : Text(
                              'Create or link drills to this session first.',
                              style: TextStyle(color: DarColors.muted, fontSize: 13),
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedDrillId != null && _targetsFuture != null)
                      FeatureAsyncBody<List<DrillReminderPlayer>>(
                        future: _targetsFuture!,
                        onRetry: () => _selectDrill(_selectedDrillId!),
                        builder: (context, players) {
                          if (players.isEmpty) {
                            return CoachDrillsSectionCard(
                              label: 'Players',
                              child: Text(
                                'No assigned players for this drill yet.',
                                style: TextStyle(color: DarColors.muted, fontSize: 13),
                              ),
                            );
                          }
                          return CoachDrillsSectionCard(
                            label: 'Players',
                            child: DarMultiSelectField<int>(
                              label: 'Select Players',
                              placeholder: 'Tap to choose players',
                              searchHint: 'Search by name or status',
                              emptyMessage: 'No players match your search',
                              options: _playerOptions(players),
                              selectedIds: _selectedPlayerIds,
                              onChanged: (ids) => setState(() => _selectedPlayerIds = ids),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    CoachDrillsSectionCard(
                      label: 'Message',
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: coachDrillsFieldDecoration(
                          'e.g. Complete this drill before Friday practice',
                          icon: Icons.message_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CoachDrillsSubmitButton(
                      motion: _motion,
                      label: 'SEND REMINDERS',
                      loadingLabel: 'SENDING...',
                      loading: _sending,
                      onPressed: _sending || !hasDrills ? null : _send,
                      icon: Icons.send_rounded,
                    ),
                    const SizedBox(height: 16),
                    CoachDrillsFooterBadge(motion: _motion, text: 'DAR CITY · SQUAD NUDGE'),
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
