import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_content.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/services/attendance_service.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/screens/discipline_token_penalty_screen.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class DailyAttendanceTokenScreen extends StatefulWidget {
  const DailyAttendanceTokenScreen({super.key});

  @override
  State<DailyAttendanceTokenScreen> createState() =>
      _DailyAttendanceTokenScreenState();
}

class _DailyAttendanceTokenScreenState extends State<DailyAttendanceTokenScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late Future<PlayerAttendanceDashboard> _dashboardFuture;
  late PlayerMotion _motion;

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
    final future = AttendanceService.fetchPlayerDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Player' : parts.first;
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_rounded;
      case 'late':
        return Icons.access_time_rounded;
      case 'absent':
      case 'noshow':
        return Icons.close_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  IconData _historyIcon(String key) {
    switch (key) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      case 'calendar_today':
        return Icons.calendar_today_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlayerScreenScaffold(
      title: 'Daily Attendance',
      body: FeatureAsyncBody<PlayerAttendanceDashboard>(
        future: _dashboardFuture,
        onRetry: _load,
        builder: (context, data) => RefreshIndicator(
          color: DarColors.accentRed,
          onRefresh: () async {
            _load();
            await _dashboardFuture;
          },
          child: ResponsiveContent(
            maxWidth: DarLayoutMetrics.of(context).formMaxWidth,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
              children: [
                      PlayerHeroCard(
                        motion: _motion,
                        badge: data.dateLabel.toUpperCase(),
                        title: 'Hey, ${_firstName(data.playerName)}',
                        subtitle: 'Your attendance and token snapshot',
                        chips: [
                          PlayerLiveChip(motion: _motion),
                          _statusChip(data),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _statusCard(data),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _tokenCard(data)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PlayerStatCard(
                              motion: _motion,
                              index: 1,
                              icon: Icons.gavel_rounded,
                              label: 'Penalties',
                              value: '${data.penaltyCount}',
                              color: DarColors.accentRed,
                            ),
                          ),
                        ],
                      ),
                      if (data.streakDays > 0) ...[
                        const SizedBox(height: 12),
                        _streakCard(data.streakDays),
                      ],
                      if (data.salaryImpactValue != null) ...[
                        const SizedBox(height: 12),
                        _salaryCard(data),
                      ],
                      if (data.upcomingDrill != null &&
                          data.upcomingDrill!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoBanner(
                          icon: Icons.sports_basketball_rounded,
                          title: 'Upcoming drill',
                          body: data.upcomingDrill!,
                          color: DarColors.accentRed,
                        ),
                      ],
                      if (data.coachNote != null &&
                          data.coachNote!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoBanner(
                          icon: Icons.format_quote_rounded,
                          title: "Coach's note",
                          body: data.coachNote!,
                          color: DarColors.cardBrown,
                        ),
                      ],
                      if (!data.isMarked) ...[
                        const SizedBox(height: 12),
                        _coachMarkedNote(),
                      ],
                      if (data.recentHistory.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const PlayerSectionHeader(
                          label: 'Recent activity',
                          icon: Icons.history_rounded,
                        ),
                        const SizedBox(height: 10),
                        ...data.recentHistory.map(_historyTile),
                      ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(PlayerAttendanceDashboard data) {
    final color = attendanceStatusColor(data.attendanceStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        attendanceStatusLabel(data.attendanceStatus),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _statusCard(PlayerAttendanceDashboard data) {
    final color = attendanceStatusColor(data.attendanceStatus);
    final label = attendanceStatusLabel(data.attendanceStatus);

    return PlayerPremiumTile(
      accentColor: color,
      highlight: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(data.attendanceStatus), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S ATTENDANCE',
                  style: TextStyle(
                    color: DarColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenCard(PlayerAttendanceDashboard data) {
    final subtitle = data.tokenBalance == 0 && data.recentHistory.isEmpty
        ? 'No merit points yet'
        : 'Club discipline score';

    return PlayerStatCard(
      motion: _motion,
      index: 0,
      icon: Icons.toll_rounded,
      label: 'Merit tokens',
      value: '${data.tokenBalance}',
      subtitle: subtitle,
      color: DarColors.eliteGold,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DisciplineTokenPenaltyScreen()),
      ),
    );
  }

  Widget _streakCard(int days) {
    return PlayerPremiumTile(
      accentColor: DarColors.accentRed,
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            '$days day streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _salaryCard(PlayerAttendanceDashboard data) {
    return PlayerAccentCard(
      motion: _motion,
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: DarColors.greenBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.salaryImpactLabel ?? 'Salary impact',
                  style: TextStyle(color: DarColors.muted, fontSize: 11),
                ),
                Text(
                  data.salaryImpactValue ?? '—',
                  style: const TextStyle(
                    color: DarColors.greenBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return PlayerPremiumTile(
      accentColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachMarkedNote() {
    return PlayerPremiumTile(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: DarColors.mutedPink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Attendance is marked by your coach during sessions. '
              'Your status will update here once recorded.',
              style: TextStyle(color: DarColors.mutedPink, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(DisciplineHistoryItem item) {
    final color = item.isPenalty ? DarColors.accentRedBright : DarColors.greenBright;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlayerPremiumTile(
        accentColor: color,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_historyIcon(item.iconKey), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            item.tokenChange,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
