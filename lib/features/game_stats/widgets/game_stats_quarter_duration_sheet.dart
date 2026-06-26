import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_period_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Pick regulation quarter length (e.g. 10 min TZ, 12 min US).
class GameStatsQuarterDurationSheet extends StatefulWidget {
  const GameStatsQuarterDurationSheet({
    super.key,
    required this.initial,
    this.title = 'Quarter length',
    this.subtitle = 'Used for Q1–Q4. Overtime is always 5:00.',
  });

  final Duration initial;
  final String title;
  final String subtitle;

  static Future<Duration?> show(
    BuildContext context, {
    required Duration initial,
    String title = 'Quarter length',
    String subtitle = 'Used for Q1–Q4. Overtime is always 5:00.',
  }) {
    return showDialog<Duration>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: GameStatsQuarterDurationSheet(
          initial: initial,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  State<GameStatsQuarterDurationSheet> createState() =>
      _GameStatsQuarterDurationSheetState();
}

class _GameStatsQuarterDurationSheetState extends State<GameStatsQuarterDurationSheet> {
  late Duration _draft;
  int _pickerKey = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _setPreset(Duration value) {
    setState(() {
      _draft = value;
      _pickerKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: DarColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: DarColors.accentRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: DarColors.muted.withValues(alpha: 0.9)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final preset in GameStatsPeriodConfig.regulationPresets)
                  _PresetChip(
                    label: GameStatsPeriodConfig.formatDurationLabel(preset),
                    selected: _draft == preset,
                    onTap: () => _setPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoTimerPicker(
                  key: ValueKey(_pickerKey),
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: _draft,
                  onTimerDurationChanged: (value) => _draft = value,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: DarColors.muted.withValues(alpha: 0.35)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _draft),
                    style: FilledButton.styleFrom(
                      backgroundColor: DarColors.accentRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Use ${GameStatsPeriodConfig.formatDurationLabel(_draft)}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? DarColors.accentRed.withValues(alpha: 0.18)
                : DarColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? DarColors.accentRed.withValues(alpha: 0.75)
                  : DarColors.muted.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : DarColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
