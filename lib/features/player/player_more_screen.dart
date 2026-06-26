import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/attendance/screens/daily_attendance_token_screen.dart';
import 'package:dar_city_app/features/discipline/screens/discipline_token_penalty_screen.dart';
import 'package:dar_city_app/features/discipline/screens/performance_salary_alert_screen.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';

class PlayerMoreScreen extends StatelessWidget {
  const PlayerMoreScreen({super.key});

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
          SliverToBoxAdapter(
            child: PlayerHubHeader(
              badge: 'PLAYER HQ',
              title: 'More',
              subtitle: 'Attendance, discipline & account',
            ),
          ),
          SliverPadding(
            padding: layout.scrollPadding(top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MenuSection(
                  title: 'Attendance',
                  items: [
                    _MenuItem(
                      icon: Icons.token_rounded,
                      iconColor: DarColors.green,
                      title: 'Daily Attendance & Token',
                      subtitle: 'Check in and view your token status',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyAttendanceTokenScreen(),
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
                      icon: Icons.balance_rounded,
                      iconColor: DarColors.eliteGold,
                      title: 'Rewards & Penalties',
                      subtitle: 'Your merit score and history',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DisciplineTokenPenaltyScreen(),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Performance & Salary Alerts',
                      subtitle: 'Discipline and achievement alerts',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PerformanceSalaryAlertScreen(
                            previewLimit: 5,
                          ),
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
                      subtitle: 'Sign out of your player account',
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
