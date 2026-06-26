import 'package:dar_city_app/core/widgets/dar_adaptive_shell.dart';
import 'package:dar_city_app/features/player/player_home_screen.dart';
import 'package:dar_city_app/features/player/player_more_screen.dart';
import 'package:dar_city_app/features/player/screens/player_chart_view_screen.dart';
import 'package:dar_city_app/features/player/screens/player_view_assigned_drills_screen.dart';
import 'package:flutter/material.dart';

/// Player shell — separate from fan and coach roots.
class PlayerRootScreen extends StatefulWidget {
  const PlayerRootScreen({super.key});

  @override
  State<PlayerRootScreen> createState() => _PlayerRootScreenState();
}

class _PlayerRootScreenState extends State<PlayerRootScreen> {
  int _selectedIndex = 0;
  int _coachChatRefreshToken = 0;

  static const _destinations = <DarShellDestination>[
    DarShellDestination(icon: Icons.home_outlined, label: 'Home'),
    DarShellDestination(icon: Icons.calendar_today, label: 'Drills'),
    DarShellDestination(icon: Icons.chat_bubble_outline, label: 'Chats'),
    DarShellDestination(icon: Icons.menu, label: 'More'),
  ];

  List<Widget> get _tabs => [
        const PlayerHomeScreen(),
        const PlayerViewAssignedDrillsScreen(embedded: true),
        PlayerChartViewScreen(
          embedded: true,
          refreshToken: _coachChatRefreshToken,
        ),
        const PlayerMoreScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return DarAdaptiveShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() {
        _selectedIndex = index;
        if (index == 2) _coachChatRefreshToken++;
      }),
      destinations: _destinations,
      children: _tabs,
    );
  }
}
