import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/widgets/coach_attendance_premium.dart';
import 'package:dar_city_app/features/attendance/screens/attendance_analytics_screen.dart';
import 'package:dar_city_app/features/attendance/screens/take_session_attendance_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_team_announcement_screen.dart';
import 'package:dar_city_app/features/discipline/screens/coach_squad_discipline_screen.dart';
import 'package:dar_city_app/features/discipline/screens/issue_disciplinary_penalty_screen.dart';
import 'package:dar_city_app/features/discipline/screens/performance_salary_alert_screen.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_match_select_screen.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';

/// Coach "More" tab — secondary actions and sign-out.
class CoachMoreScreen extends StatelessWidget {
  const CoachMoreScreen({super.key});

  static Future<void> _logout(BuildContext context) async {
    await SessionManager().clearToken();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 132,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DarColors.accentRed.withValues(alpha: 0.45),
                      Colors.black,
                      DarColors.background,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 12, layout.horizontalPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COACH HUB',
                          style: TextStyle(
                            color: DarColors.accentRed.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'More',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage squad ops, attendance & discipline',
                          style: TextStyle(color: DarColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: layout.scrollPadding(top: 8, bottom: 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MenuSection(
                  title: 'Communication',
                  items: [
                    _MenuItem(
                      icon: Icons.campaign_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Team Announcement',
                      subtitle: 'Publish updates to the squad',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoachTeamAnnouncementScreen(),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Team Alerts',
                      subtitle: 'Performance & system notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PerformanceSalaryAlertScreen(forCoach: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Game Stats',
                  items: [
                    _MenuItem(
                      icon: Icons.sports_score_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Game Stats',
                      subtitle: 'Track live scoring, subs & play-by-play',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameStatsMatchSelectScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Attendance',
                  items: [
                    _MenuItem(
                      icon: Icons.fact_check_rounded,
                      iconColor: DarColors.green,
                      title: 'Take Session Attendance',
                      subtitle: 'Mark present, late, or absent',
                      onTap: () => Navigator.push(
                        context,
                        coachAttendancePageRoute(
                          const TakeSessionAttendanceScreen(),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.analytics_rounded,
                      iconColor: Colors.lightBlueAccent,
                      title: 'Attendance Analytics',
                      subtitle: 'Trends, rates & squad insights',
                      onTap: () => Navigator.push(
                        context,
                        coachAttendancePageRoute(
                          const AttendanceAnalyticsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Discipline',
                  items: [
                    _MenuItem(
                      icon: Icons.visibility_rounded,
                      iconColor: Colors.amber,
                      title: 'Squad Penalties',
                      subtitle: 'Dashboard — view team infractions & tokens',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoachSquadDisciplineScreen(),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.gavel_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Issue Penalty',
                      subtitle: 'Assign infraction to a player',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IssueDisciplinaryPenaltyScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      iconColor: DarColors.muted,
                      title: 'Settings',
                      subtitle: 'Coming soon',
                      onTap: () {},
                      showChevron: false,
                    ),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Logout',
                      subtitle: 'Sign out of your coach account',
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: DarColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DarColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: DarColors.muted.withValues(alpha: 0.12),
                  ),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: DarColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded, color: DarColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
