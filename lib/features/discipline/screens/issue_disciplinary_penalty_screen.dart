import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/widgets/dar_player_select_field.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/services/discipline_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/services/team_service.dart';

class _InfractionOption {
  const _InfractionOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class IssueDisciplinaryPenaltyScreen extends StatefulWidget {
  const IssueDisciplinaryPenaltyScreen({super.key});

  @override
  State<IssueDisciplinaryPenaltyScreen> createState() =>
      _IssueDisciplinaryPenaltyScreenState();
}

class _IssueDisciplinaryPenaltyScreenState
    extends State<IssueDisciplinaryPenaltyScreen> with AutoRefreshStateMixin {
  late Future<List<Person>> _playersFuture;
  int? _selectedPlayerId;
  int _selectedInfraction = 0;
  int _tokens = 15;
  final _notesController = TextEditingController();
  bool _submitting = false;

  static const _infractions = [
    _InfractionOption('Late Arrival', Icons.schedule_rounded),
    _InfractionOption('Unexcused Absence', Icons.event_busy_rounded),
    _InfractionOption('Poor Conduct', Icons.sentiment_dissatisfied_rounded),
    _InfractionOption('Equipment Violation', Icons.sports_basketball_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _playersFuture = TeamService.fetchPlayers();
    startAutoRefresh(_reloadPlayers);
  }

  Future<void> _reloadPlayers() async {
    final future = TeamService.fetchPlayers();
    setState(() => _playersFuture = future);
    await future;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPlayerId == null) {
      showFeatureSnackBar(context, 'Select a player', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await DisciplineService.issuePenalty(
        IssuePenaltyPayload(
          playerId: _selectedPlayerId!,
          infraction: _infractions[_selectedInfraction].label,
          tokens: _tokens,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      final balanceMsg = result.newTokenBalance != null
          ? ' New balance: ${result.newTokenBalance}'
          : '';
      final deductedMsg = result.tokensDeducted != null
          ? ' (-${result.tokensDeducted} tokens)'
          : '';
      showFeatureSnackBar(context, '${result.message}$deductedMsg$balanceMsg');
      Navigator.of(context).pop();
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Issue Penalty',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: darResponsiveBody(
        SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: layout.scrollPadding(top: 8, bottom: 8),
                children: [
                  FeatureAsyncBody<List<Person>>(
                    future: _playersFuture,
                    onRetry: () => setState(() {
                      _playersFuture = TeamService.fetchPlayers();
                    }),
                    builder: (_, players) {
                      return DarPlayerSelectField(
                        label: 'Player',
                        players: players,
                        selectedId: _selectedPlayerId,
                        onChanged: (id) => setState(() => _selectedPlayerId = id),
                        placeholder: 'Search or pick from squad',
                        searchHint: 'Name, jersey #, position',
                        emptyMessage: 'No players match',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _compactSection(
                    title: 'Infraction',
                    child: GridView.count(
                      crossAxisCount: layout.isTablet ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.35,
                      children: _infractions.asMap().entries.map((e) {
                        final selected = _selectedInfraction == e.key;
                        final item = e.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedInfraction = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? DarColors.accentRed.withValues(alpha: 0.14)
                                  : DarColors.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? DarColors.accentRed
                                    : DarColors.muted.withValues(alpha: 0.2),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: selected ? DarColors.accentRed : DarColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected ? Colors.white : DarColors.muted,
                                      fontSize: 11.5,
                                      fontWeight:
                                          selected ? FontWeight.w700 : FontWeight.w500,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _compactSection(
                    title: 'Token deduction',
                    child: Row(
                      children: [
                        Text(
                          '-$_tokens',
                          style: const TextStyle(
                            color: DarColors.accentRed,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'tokens',
                          style: TextStyle(color: DarColors.muted, fontSize: 13),
                        ),
                        const Spacer(),
                        _stepBtn(Icons.remove, () {
                          if (_tokens > 5) setState(() => _tokens -= 5);
                        }),
                        const SizedBox(width: 8),
                        _stepBtn(Icons.add, () {
                          if (_tokens < 50) setState(() => _tokens += 5);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _compactSection(
                    title: 'Notes (optional)',
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      minLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                      decoration: InputDecoration(
                        hintText: 'Brief context — time, warnings given…',
                        hintStyle: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: DarColors.inputBrown,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 0, layout.horizontalPadding, 12),
              child: DarPrimaryButton(
                label: _submitting ? 'Submitting…' : 'Confirm Penalty',
                color: DarColors.accentRed,
                textColor: Colors.white,
                icon: Icons.gavel_rounded,
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _compactSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: DarColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: DarColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
