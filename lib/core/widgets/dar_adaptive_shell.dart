import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_bottom_nav_bar.dart';
import 'package:dar_city_app/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';

class DarShellDestination {
  const DarShellDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// Role root scaffold — bottom tabs on phones, side rail on wide tablets / desktop.
class DarAdaptiveShell extends StatelessWidget {
  const DarAdaptiveShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.children,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DarShellDestination> destinations;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final metrics = DarLayoutMetrics.of(context);

    if (metrics.useNavigationRail) {
      return Scaffold(
        backgroundColor: DarColors.background,
        body: Row(
          children: [
            _buildNavigationRail(context, metrics),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFF333333),
            ),
            Expanded(
              child: ResponsiveContent(
                child: IndexedStack(
                  index: selectedIndex,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: DarColors.background,
      resizeToAvoidBottomInset: true,
      body: ResponsiveContent(
        child: IndexedStack(
          index: selectedIndex,
          children: children,
        ),
      ),
      bottomNavigationBar: DarBottomNavBar(
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _BottomNavItem(
                  destination: destinations[i],
                  isSelected: selectedIndex == i,
                  compact: metrics.isCompact && destinations.length > 4,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, DarLayoutMetrics metrics) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: DarColors.navBar,
      indicatorColor: DarColors.accentRed.withValues(alpha: 0.22),
      selectedIconTheme: const IconThemeData(color: DarColors.accentRed, size: 26),
      unselectedIconTheme: const IconThemeData(color: DarColors.muted, size: 24),
      selectedLabelTextStyle: const TextStyle(
        color: DarColors.accentRed,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: DarColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      labelType: metrics.isDesktop
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      minWidth: metrics.isDesktop ? 88 : 72,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon ?? destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  final DarShellDestination destination;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? DarColors.accentRed : DarColors.muted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected
                ? (destination.selectedIcon ?? destination.icon)
                : destination.icon,
            color: color,
            size: compact ? 22 : 24,
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
