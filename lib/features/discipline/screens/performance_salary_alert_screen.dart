import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/services/discipline_service.dart';
import 'package:dar_city_app/features/discipline/screens/discipline_token_penalty_screen.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class PerformanceSalaryAlertScreen extends StatefulWidget {
  const PerformanceSalaryAlertScreen({
    super.key,
    this.forCoach = false,
    this.previewLimit,
  });

  /// When true, loads team-wide alerts via `GET /coach/alerts`.
  final bool forCoach;

  /// Player preview from More menu — show at most N, then View all for full list.
  final int? previewLimit;

  @override
  State<PerformanceSalaryAlertScreen> createState() =>
      _PerformanceSalaryAlertScreenState();
}

class _PerformanceSalaryAlertScreenState extends State<PerformanceSalaryAlertScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<List<PerformanceAlert>> _alertsFuture;
  PlayerMotion? _motion;

  @override
  void initState() {
    super.initState();
    if (!widget.forCoach) _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = widget.forCoach
        ? DisciplineService.fetchCoachAlerts()
        : DisciplineService.fetchPlayerAlerts();
    setState(() => _alertsFuture = future);
    await future;
  }

  Color _accentColor(String key) {
    switch (key) {
      case 'gold':
        return DarColors.eliteGold;
      case 'blue':
        return DarColors.eliteBlue;
      case 'coral':
        return DarColors.eliteCoral;
      default:
        return DarColors.muted;
    }
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'calendar_today':
        return Icons.calendar_today;
      case 'star':
        return Icons.star;
      case 'trending_up':
        return Icons.trending_up;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forCoach) {
      return _coachScaffold(context);
    }
    return _playerScaffold(context);
  }

  Widget _playerScaffold(BuildContext context) {
    final motion = _motion!;
    final isPreview = !widget.forCoach && widget.previewLimit != null;

    return PlayerScreenScaffold(
      title: 'Performance Alerts',
      body: FeatureAsyncBody<List<PerformanceAlert>>(
        future: _alertsFuture,
        onRetry: _load,
        builder: (context, alerts) {
          final limit = widget.previewLimit;
          final shown = isPreview && limit != null
              ? alerts.take(limit).toList()
              : alerts;
          final hasMore = isPreview && limit != null && alerts.length > limit;

          return RefreshIndicator(
            color: DarColors.accentRed,
            onRefresh: () async {
              _load();
              await _alertsFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
              children: [
                PlayerHeroCard(
                  motion: motion,
                  badge: 'ALERTS',
                  title: 'Performance Alerts',
                  subtitle: isPreview
                      ? 'Latest rewards, discipline & salary updates'
                      : 'Real-time discipline and achievement tracking',
                  chips: [PlayerLiveChip(motion: motion)],
                ),
                const SizedBox(height: 20),
                if (alerts.isEmpty)
                  const PlayerEmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'No alerts yet',
                  )
                else ...[
                  if (isPreview)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Showing ${shown.length} of ${alerts.length}',
                        style: TextStyle(
                          color: DarColors.muted.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ...shown.map((a) {
                    final accent = _accentColor(a.accentKey);
                    if (a.category.contains('DISCIPLINARY')) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _playerDisciplinaryCard(a),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _playerAlertTile(a, accent),
                    );
                  }),
                  if (hasMore) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PerformanceSalaryAlertScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.unfold_more_rounded, size: 18),
                        label: Text(
                          'View all (${alerts.length})',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: DarColors.accentRed,
                        ),
                      ),
                    ),
                  ],
                ],
                if (!isPreview) ...[
                  const SizedBox(height: 16),
                  const PlayerSectionHeader(
                    label: 'Review all metrics',
                    icon: Icons.insights_rounded,
                  ),
                  const SizedBox(height: 12),
                  DarPrimaryButton(
                    label: 'OPEN DASHBOARD',
                    color: DarColors.accentRed,
                    textColor: Colors.white,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DisciplineTokenPenaltyScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _playerAlertTile(PerformanceAlert alert, Color accent) {
    return PlayerPremiumTile(
      accentColor: accent,
      highlight: alert.accentKey == 'gold',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.category.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Icon(_iconForKey(alert.iconKey), color: accent, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alert.message,
            style: TextStyle(color: DarColors.muted, fontSize: 12, height: 1.4),
          ),
          if (alert.showProgress == true) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: alert.progressValue ?? 0.75,
                backgroundColor: DarColors.surface,
                color: accent,
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(alert.timestamp, style: TextStyle(color: accent, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _playerDisciplinaryCard(PerformanceAlert alert) {
    return PlayerPremiumTile(
      accentColor: DarColors.accentRed,
      highlight: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: DarColors.accentRed, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            alert.category.toUpperCase(),
            style: TextStyle(
              color: DarColors.accentRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            alert.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DarColors.accentRed,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(alert.timestamp, style: TextStyle(color: DarColors.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _coachScaffold(BuildContext context) {
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
          'Team Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: darResponsiveBody(
        SafeArea(
        child: Column(
          children: [
            const EliteHoopsHeader(showProfile: false),
            Expanded(
              child: FeatureAsyncBody<List<PerformanceAlert>>(
                future: _alertsFuture,
                onRetry: _load,
                builder: (context, alerts) => RefreshIndicator(
                  color: DarColors.accentRed,
                  onRefresh: () async {
                    _load();
                    await _alertsFuture;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: DarLayoutMetrics.of(context).scrollPadding(top: 0, bottom: 32),
                    children: [
                      const Text('PERFORMANCE ALERTS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      Text(
                        'Team-wide discipline and system notifications.',
                        style: TextStyle(color: DarColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      if (alerts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No alerts yet',
                                style: TextStyle(color: DarColors.muted)),
                          ),
                        )
                      else
                        ...alerts.map((a) {
                          final accent = _accentColor(a.accentKey);
                          final isPenalty = a.category.contains('DISCIPLINARY');
                          if (isPenalty) {
                            return _disciplinaryCard(a);
                          }
                          return _alertCard(
                            a.category,
                            a.title,
                            a.message,
                            a.timestamp,
                            accent,
                            _iconForKey(a.iconKey),
                            leftBorder: a.accentKey == 'coral',
                            fullBorder: a.accentKey == 'gold',
                            topBorder: a.accentKey == 'blue',
                            showProgress: a.showProgress == true,
                            progress: a.progressValue ?? 0.75,
                          );
                        }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _alertCard(
    String tag,
    String title,
    String body,
    String footer,
    Color accent,
    IconData icon, {
    bool leftBorder = false,
    bool fullBorder = false,
    bool topBorder = false,
    bool showProgress = false,
    double progress = 0.75,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: fullBorder
            ? Border.all(color: accent)
            : leftBorder
                ? Border(left: BorderSide(color: accent, width: 3))
                : topBorder
                    ? Border(top: BorderSide(color: accent, width: 3))
                    : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tag,
                  style: TextStyle(
                      color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
              Icon(icon, color: accent, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: fullBorder ? accent : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(color: DarColors.muted, fontSize: 12, height: 1.4)),
          if (showProgress) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: DarColors.inputDark,
                color: accent,
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(footer, style: TextStyle(color: accent, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _disciplinaryCard(PerformanceAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarColors.accentRed),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber,
                color: DarColors.accentRed, size: 28),
          ),
          const SizedBox(height: 10),
          Text(alert.category,
              style: TextStyle(
                  color: DarColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          Text(alert.title,
              style: const TextStyle(
                  color: DarColors.accentRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            alert.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(alert.timestamp,
              style: TextStyle(color: DarColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}
