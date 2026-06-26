import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';

class DarScaffold extends StatelessWidget {
  const DarScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBack = true,
    this.showBottomNav = true,
    this.leading,
    this.actions,
    this.bottomNavIndex = 0,
    this.bottomNavType = DarBottomNavType.coach,
    this.floatingActionButton,
    this.backgroundColor = DarColors.background,
    this.responsiveBody = true,
    this.maxBodyWidth,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final bool showBack;
  final bool showBottomNav;
  final Widget? leading;
  final List<Widget>? actions;
  final int bottomNavIndex;
  final DarBottomNavType bottomNavType;
  final Widget? floatingActionButton;
  final Color backgroundColor;
  final bool responsiveBody;
  final double? maxBodyWidth;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final backButton = showBack && canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          )
        : leading;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: backButton,
              title: Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              actions: actions,
            ),
      body: responsiveBody
          ? darResponsiveBody(body, maxWidth: maxBodyWidth)
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? DarBottomNav(
              selectedIndex: bottomNavIndex,
              type: bottomNavType,
            )
          : bottomBar,
    );
  }
}

enum DarBottomNavType { coach, drills, elite }

class DarBottomNav extends StatelessWidget {
  const DarBottomNav({
    super.key,
    required this.selectedIndex,
    this.type = DarBottomNavType.coach,
  });

  final int selectedIndex;
  final DarBottomNavType type;

  @override
  Widget build(BuildContext context) {
    final items = switch (type) {
      DarBottomNavType.coach => const [
          _NavItem(Icons.home_outlined, 'Dashboard'),
          _NavItem(Icons.calendar_month_outlined, 'Schedule'),
          _NavItem(Icons.chat_bubble_outline, 'Team Chat'),
          _NavItem(Icons.analytics_outlined, 'Analytics'),
          _NavItem(Icons.menu, 'More'),
        ],
      DarBottomNavType.drills => const [
          _NavItem(Icons.home_outlined, 'Home'),
          _NavItem(Icons.sports_basketball, 'Drills'),
          _NavItem(Icons.people_outline, 'Players'),
          _NavItem(Icons.settings_outlined, 'Settings'),
        ],
      DarBottomNavType.elite => const [
          _NavItem(Icons.home_outlined, 'Home'),
          _NavItem(Icons.calendar_month_outlined, 'Schedule'),
          _NavItem(Icons.groups_outlined, 'Team'),
          _NavItem(Icons.shopping_cart_outlined, 'Buy'),
          _NavItem(Icons.menu, 'Menu'),
        ],
    };

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: DarColors.navBar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == selectedIndex;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isActive ? DarColors.accentRed : DarColors.muted,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? DarColors.accentRed : DarColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class DarSectionTitle extends StatelessWidget {
  const DarSectionTitle(this.text, {super.key, this.color = Colors.white});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DarFormLabel extends StatelessWidget {
  const DarFormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DarTextField extends StatelessWidget {
  const DarTextField({
    super.key,
    this.hint,
    this.maxLines = 1,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String? hint;
  final int maxLines;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: DarColors.inputBrown,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class DarPrimaryButton extends StatelessWidget {
  const DarPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = DarColors.accentRed,
    this.textColor = Colors.white,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

class DarPlayerAvatar extends StatelessWidget {
  const DarPlayerAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.color = DarColors.accentRed,
    this.imageUrl,
  });

  final String name;
  final double size;
  final Color color;
  final String? imageUrl;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _initialAvatar();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _initialAvatar(loading: true),
        errorWidget: (_, __, ___) => _initialAvatar(),
      ),
    );
  }

  Widget _initialAvatar({bool loading = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color.withValues(alpha: 0.85),
              ),
            )
          : Text(
              _initial,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.35,
              ),
            ),
    );
  }
}

class DarCityHeader extends StatelessWidget {
  const DarCityHeader({
    super.key,
    this.showProfile = true,
  });

  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    final h = DarLayoutMetrics.of(context).horizontalPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(h, 8, h, 16),
      child: Row(
        children: [
          const Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 20),
          const SizedBox(width: 8),
          const Text(
            'DAR CITY',
            style: TextStyle(
              color: DarColors.accentRed,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: DarColors.accentRed),
          if (showProfile) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 16,
              backgroundColor: DarColors.cardDark,
              child: Icon(Icons.person, size: 18, color: DarColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

typedef EliteHoopsHeader = DarCityHeader;

class DarStatCard extends StatelessWidget {
  const DarStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.trendUp,
    this.accentColor,
    this.borderColor,
    this.leftAccent = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? trend;
  final bool? trendUp;
  final Color? accentColor;
  final Color? borderColor;
  final bool leftAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        children: [
          if (leftAccent)
            Container(
              width: 4,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: accentColor ?? DarColors.accentRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor ?? Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: accentColor ?? Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: DarColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (trend != null)
                  Text(
                    trend!,
                    style: TextStyle(
                      color: trendUp == true
                          ? DarColors.green
                          : trendUp == false
                              ? DarColors.accentRed
                              : DarColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
