import 'package:dar_city_app/core/widgets/dar_adaptive_shell.dart';
import 'package:dar_city_app/features/coach/coach_attendance_hub_screen.dart';
import 'package:dar_city_app/features/coach/coach_drills_hub_screen.dart';
import 'package:dar_city_app/features/coach/coach_more_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_chart_hub_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_training_dashboard_screen.dart';
import 'package:dar_city_app/features/coach/screens/manage_training_session_screen.dart';
import 'package:flutter/material.dart';

/// Coach shell — separate from fan [RootScreen], adaptive nav on wide screens.
class CoachRootScreen extends StatefulWidget {
  const CoachRootScreen({super.key});

  @override
  State<CoachRootScreen> createState() => _CoachRootScreenState();
}

class _CoachRootScreenState extends State<CoachRootScreen> {
  int _selectedIndex = 0;

  static const _destinations = <DarShellDestination>[
    DarShellDestination(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    DarShellDestination(icon: Icons.calendar_today, label: 'Session'),
    DarShellDestination(icon: Icons.sports_basketball, label: 'Drills'),
    DarShellDestination(icon: Icons.how_to_reg_outlined, label: 'Attendance'),
    DarShellDestination(icon: Icons.chat_bubble_outline, label: 'Team Chat'),
    DarShellDestination(icon: Icons.menu, label: 'More'),
  ];

  static const _tabs = <Widget>[
    CoachTrainingDashboardScreen(embedded: true),
    ManageTrainingSessionScreen(embedded: true),
    CoachDrillsHubScreen(),
    CoachAttendanceHubScreen(),
    CoachChartHubScreen(embedded: true),
    CoachMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DarAdaptiveShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: _destinations,
      children: _tabs,
    );
  }
}
