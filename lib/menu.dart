import 'package:dar_city_app/about_screen.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/help_support_screen.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/team_page.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'settings.dart';
import 'cart_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  static Future<void> _logout(BuildContext context) async {
    await SessionManager().clearToken();
    CartManager().clearCart();
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
                          'FAN ZONE',
                          style: TextStyle(
                            color: DarColors.accentRed.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Profile, shop & club info',
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
                  title: 'Club',
                  items: [
                    _MenuItem(
                      icon: Icons.groups_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Team',
                      subtitle: 'Full squad & staff directory',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeamPage()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.lightBlueAccent,
                      title: 'About App',
                      subtitle: 'Dar City Basketball fan app',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                      icon: Icons.person_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Fan Profile',
                      subtitle: 'Your fan account details',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      iconColor: DarColors.muted,
                      title: 'Settings',
                      subtitle: 'Preferences & notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Shop & Support',
                  items: [
                    _MenuItem(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: Colors.amber,
                      title: 'My Cart',
                      subtitle: 'View items & checkout',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.tealAccent,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact us',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuSection(
                  title: 'Session',
                  items: [
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: DarColors.accentRed,
                      title: 'Logout',
                      subtitle: 'Sign out of your fan account',
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
              Icon(Icons.chevron_right_rounded, color: DarColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
