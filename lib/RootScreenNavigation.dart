import 'package:dar_city_app/core/widgets/dar_adaptive_shell.dart';
import 'package:flutter/material.dart';
import 'fanMainDashboard.dart';
import 'fanSchedules.dart';
import 'teamMemberView.dart';
import 'buyPage.dart';
import 'menu.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int selectedBottomIndex = 0;

  static const _destinations = <DarShellDestination>[
    DarShellDestination(icon: Icons.home_outlined, label: 'Home'),
    DarShellDestination(icon: Icons.calendar_today_outlined, label: 'Schedule'),
    DarShellDestination(icon: Icons.groups_outlined, label: 'Team'),
    DarShellDestination(icon: Icons.shopping_bag_outlined, label: 'Shop'),
    DarShellDestination(icon: Icons.menu_rounded, label: 'Menu'),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    TeamScreen(),
    BuyScreen(),
    MoreMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DarAdaptiveShell(
      selectedIndex: selectedBottomIndex,
      onDestinationSelected: (index) => setState(() => selectedBottomIndex = index),
      destinations: _destinations,
      children: _screens,
    );
  }
}
