import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/screens/daily_attendance_token_screen.dart';
import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcement_detail_screen.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/screens/discipline_token_penalty_screen.dart';
import 'package:dar_city_app/features/discipline/screens/performance_salary_alert_screen.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/player/player_dashboard_filter.dart';
import 'package:dar_city_app/features/player/services/player_dashboard_service.dart';
import 'package:dar_city_app/features/player/screens/player_view_assigned_drills_screen.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/features/shared/widgets/recent_chats_dashboard_section.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<PlayerDashboardData> _dashboardFuture;
  late PlayerMotion _motion;
  PlayerDashboardRange _range = PlayerDashboardRange.today;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = PlayerDashboardService.fetchDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        FeatureAsyncBody<PlayerDashboardData>(
        future: _dashboardFuture,
        onRetry: _load,
        builder: (context, data) {
          final filtered = PlayerDashboardFilteredView.from(data, _range);
          final layout = DarLayoutMetrics.of(context);
          return RefreshIndicator(
            color: DarColors.accentRed,
            onRefresh: () async {
              _load();
              await _dashboardFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: layout.scrollPadding(top: 12),
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                      onPressed: _load,
                    ),
                  ],
                ),
                _hero(data),
                const SizedBox(height: 20),
                _rangeChips(),
                const SizedBox(height: 8),
                _rangeSummary(filtered.rangeLabel),
                if (data.upcomingDrill != null &&
                    data.upcomingDrill!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _upcomingBanner(data.upcomingDrill!),
                ],
                const SizedBox(height: 16),
                _statsGrid(data, filtered),
                const SizedBox(height: 24),
                RecentChatsDashboardSection(role: DirectChatRole.player),
                const SizedBox(height: 20),
                _drillProgressCard(filtered),
                if (filtered.drillsInRange.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  PlayerSectionHeader(
                    label: 'Drills · ${_range.label}',
                    icon: Icons.fitness_center_rounded,
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerViewAssignedDrillsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filtered.drillsInRange.take(5).map(_drillTile),
                ],
                const SizedBox(height: 24),
                PlayerSectionHeader(
                  label: 'Team Announcements · ${_range.label}',
                  icon: Icons.campaign_rounded,
                ),
                const SizedBox(height: 10),
                if (filtered.announcements.isEmpty)
                  PlayerEmptyState(
                    icon: Icons.campaign_outlined,
                    message: 'No announcements for ${filtered.range.periodHint}',
                  )
                else
                  ...filtered.announcements.map(_announcementCard),
                const SizedBox(height: 24),
                PlayerSectionHeader(
                  label: 'Alerts · ${_range.label}',
                  icon: Icons.notifications_active_rounded,
                  actionLabel: filtered.alerts.isNotEmpty ? 'View all' : null,
                  onAction: filtered.alerts.isNotEmpty
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerformanceSalaryAlertScreen(),
                            ),
                          )
                      : null,
                ),
                const SizedBox(height: 10),
                if (filtered.alerts.isEmpty)
                  PlayerEmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'No alerts for ${filtered.range.periodHint}',
                  )
                else
                  ...filtered.alerts.map(_alertCard),
                const SizedBox(height: 24),
                _salaryImpactCard(data),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _hero(PlayerDashboardData data) {
    final status = data.attendanceStatus;
    final statusColor = attendanceStatusColor(status);

    return PlayerHeroCard(
      motion: _motion,
      badge: 'PLAYER HQ',
      title: 'Hey, ${data.profile.name.trim()}',
      subtitle: data.profile.displayRoleLabel ??
          'Your performance command center',
      trailing: _profileAvatar(data),
      chips: [
        PlayerLiveChip(motion: _motion),
        _statusChip(statusColor, attendanceStatusLabel(status)),
        _metaChip(Icons.calendar_today_rounded, data.dateLabel),
      ],
    );
  }

  Widget _statusChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DarColors.muted),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: DarColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _profileAvatar(PlayerDashboardData data) {
    final url = data.profile.passportImageUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: DarColors.cardDark,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }
    return DarPlayerAvatar(name: data.profile.name, size: 60, imageUrl: url);
  }

  Widget _rangeChips() {
    return Row(
      children: PlayerDashboardRange.values.map((range) {
        final selected = _range == range;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: range != PlayerDashboardRange.year ? 6 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _range = range),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? DarColors.accentRed : DarColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? DarColors.accentRed
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    range.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : DarColors.muted,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _rangeSummary(String label) {
    return Text(
      'Showing $label',
      style: TextStyle(
        color: DarColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _upcomingBanner(String text) {
    return PlayerPremiumTile(
      highlight: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_rounded, color: DarColors.accentRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UP',
                  style: TextStyle(
                    color: DarColors.accentRed.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(PlayerDashboardData data, PlayerDashboardFilteredView filtered) {
    final drillValue = filtered.drillsDueInRange == 0
        ? '0'
        : '${filtered.drillsCompletedInRange}/${filtered.drillsDueInRange}';
    final drillSubtitle = filtered.drillsDueInRange == 0
        ? 'none due'
        : filtered.range.periodHint;

    return Row(
      children: [
        Expanded(
          child: PlayerStatCard(
            motion: _motion,
            index: 0,
            icon: Icons.toll_rounded,
            label: 'Tokens',
            value: '${data.tokenBalance}',
            subtitle: filtered.tokenPeriodLabel,
            color: DarColors.eliteGold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DisciplineTokenPenaltyScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PlayerStatCard(
            motion: _motion,
            index: 1,
            icon: Icons.fitness_center_rounded,
            label: 'Drills',
            value: drillValue,
            subtitle: drillSubtitle,
            color: DarColors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PlayerViewAssignedDrillsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PlayerStatCard(
            motion: _motion,
            index: 2,
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${data.streakDays}d',
            subtitle: _range == PlayerDashboardRange.today
                ? 'attendance'
                : '${filtered.drillsDueInRange} due',
            color: DarColors.accentRed,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DailyAttendanceTokenScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _drillProgressCard(PlayerDashboardFilteredView filtered) {
    final progress = filtered.drillsDueInRange == 0
        ? 0.0
        : filtered.drillsCompletedInRange / filtered.drillsDueInRange;

    return PlayerAccentCard(
      motion: _motion,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PlayerViewAssignedDrillsScreen(),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: DarColors.surface,
                  color: DarColors.accentRed,
                ),
                Text(
                  '${filtered.drillCompletionPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training · ${filtered.range.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  filtered.drillsDueInRange == 0
                      ? 'No drills due ${filtered.range.periodHint}'
                      : '${filtered.drillsCompletedInRange} of ${filtered.drillsDueInRange} completed ${filtered.range.periodHint}',
                  style: TextStyle(color: DarColors.muted, fontSize: 12),
                ),
                if (filtered.drillsInRange.any((d) => d.status == 'overdue')) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${filtered.drillsInRange.where((d) => d.status == 'overdue').length} overdue in this period',
                    style: const TextStyle(
                      color: DarColors.accentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DarColors.accentRed.withValues(alpha: 0.85)),
        ],
      ),
    );
  }

  Widget _drillTile(AssignedDrill drill) {
    final statusColor = switch (drill.status) {
      'overdue' => DarColors.accentRed,
      'in_progress' => DarColors.eliteGold,
      'completed' => DarColors.green,
      _ => DarColors.muted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlayerPremiumTile(
        accentColor: statusColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.sports_basketball_rounded, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.drillName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${drill.dueDate} · ${drill.statusLabel}',
                    style: TextStyle(color: DarColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(Announcement item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlayerPremiumTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachAnnouncementDetailScreen(announcement: item),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DarColors.accentRed.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: DarColors.accentRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (item.authorName != null && item.authorName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.authorName!,
                            style: TextStyle(color: DarColors.muted, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: DarColors.accentRed.withValues(alpha: 0.85)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.bodyPreview,
              style: TextStyle(color: DarColors.muted, fontSize: 12, height: 1.35),
            ),
            if (item.hasMedia) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.perm_media_outlined, size: 14, color: DarColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'Includes attachment',
                    style: TextStyle(color: DarColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _alertCard(PerformanceAlert alert) {
    final accent = _alertAccent(alert.accentKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlayerPremiumTile(
        accentColor: accent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(_alertIcon(alert.iconKey), color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: DarColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.timestamp,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryImpactCard(PlayerDashboardData data) {
    return PlayerAccentCard(
      motion: _motion,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DisciplineTokenPenaltyScreen(),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.salaryImpactLabel.toUpperCase(),
                  style: TextStyle(
                    color: DarColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.salaryImpactValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  Color _alertAccent(String key) {
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

  IconData _alertIcon(String key) {
    switch (key) {
      case 'calendar_today':
        return Icons.calendar_today_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
