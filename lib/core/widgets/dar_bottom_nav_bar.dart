import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:flutter/material.dart';

/// Bottom tab bar shell — keeps icons above the system gesture / nav bar.
class DarBottomNavBar extends StatelessWidget {
  const DarBottomNavBar({super.key, required this.child});

  final Widget child;

  static const barHeight = 64.0;

  /// Tab bar height plus the system home-indicator / gesture inset.
  static double totalHeight(BuildContext context) {
    return barHeight + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DarColors.navBar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: child,
        ),
      ),
    );
  }
}
