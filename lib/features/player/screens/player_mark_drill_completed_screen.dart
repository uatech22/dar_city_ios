import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/player/services/player_drill_service.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class PlayerMarkDrillCompletedScreen extends StatefulWidget {
  const PlayerMarkDrillCompletedScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlayerMarkDrillCompletedScreen> createState() =>
      _PlayerMarkDrillCompletedScreenState();
}

class _PlayerMarkDrillCompletedScreenState
    extends State<PlayerMarkDrillCompletedScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<List<DrillCompletionItem>> _itemsFuture;
  late PlayerMotion _motion;
  final Set<String> _selectedIds = {};
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = PlayerDrillService.fetchCompletionItems();
    setState(() => _itemsFuture = future);
    await future;
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) {
      showFeatureSnackBar(context, 'Select at least one drill', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await PlayerDrillService.markComplete(
        MarkDrillCompletePayload(
          assignmentIds: _selectedIds.toList(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      final message = result['message']?.toString() ?? 'Drills marked complete';
      showFeatureSnackBar(context, message);
      _selectedIds.clear();
      _notesController.clear();
      _load();
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Mark Drill Complete',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: DarColors.accentRed,
              onRefresh: () async {
                _load();
                await _itemsFuture;
              },
              child: FeatureAsyncBody<List<DrillCompletionItem>>(
                future: _itemsFuture,
                onRetry: _load,
                builder: (context, items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
                      children: [
                        PlayerHeroCard(
                          motion: _motion,
                          badge: 'COMPLETION',
                          title: 'Mark Drills Done',
                          subtitle: 'Select drills you finished and submit',
                          chips: [PlayerLiveChip(motion: _motion)],
                        ),
                        const SizedBox(height: 24),
                        const PlayerEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          message: 'No drills to complete',
                        ),
                      ],
                    );
                  }

                  final pending = items.where((item) => !item.isCompleted).length;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: DarLayoutMetrics.of(context).scrollPadding(top: 8, bottom: 16),
                    children: [
                      PlayerHeroCard(
                        motion: _motion,
                        badge: 'COMPLETION',
                        title: 'Mark Drills Done',
                        subtitle: '$pending drill${pending == 1 ? '' : 's'} remaining',
                        chips: [PlayerLiveChip(motion: _motion)],
                      ),
                      const SizedBox(height: 20),
                      const PlayerSectionHeader(
                        label: 'Select completed drills',
                        icon: Icons.checklist_rounded,
                      ),
                      const SizedBox(height: 10),
                      ...items.map(_itemRow),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DarLayoutMetrics.of(context).horizontalPadding,
              0,
              DarLayoutMetrics.of(context).horizontalPadding,
              8,
            ),
            child: PlayerNotesBox(
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  hintStyle: TextStyle(color: DarColors.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),
          PlayerSubmitBar(
            child: DarPrimaryButton(
              label: _submitting ? 'Saving...' : 'Mark Selected Complete',
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(DrillCompletionItem item) {
    final checked =
        item.isCompleted || _selectedIds.contains(item.assignmentId);
    final color = item.isCompleted ? DarColors.green : DarColors.accentRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlayerPremiumTile(
        accentColor: color,
        highlight: checked && !item.isCompleted,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(
                item.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.sports_basketball_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isCompleted ? DarColors.muted : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    item.category,
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                  ),
                  if (item.isCompleted)
                    Text(
                      'Already completed',
                      style: TextStyle(
                        color: DarColors.greenBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: item.isCompleted
                  ? null
                  : (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(item.assignmentId);
                        } else {
                          _selectedIds.remove(item.assignmentId);
                        }
                      });
                    },
              activeColor: DarColors.accentRed,
              side: BorderSide(color: DarColors.muted.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
