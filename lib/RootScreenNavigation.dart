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

  final List<Widget> _screens = [
     HomeScreen(),
     ScheduleScreen(),
    TeamScreen(),
    BuyScreen(),
    MoreMenuScreen(),


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[selectedBottomIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', 0),
            _buildBottomNavItem(Icons.calendar_today, 'Schedule', 1),
            _buildBottomNavItem(Icons.group, 'Team', 2),
            _buildBottomNavItem(Icons.shopping_bag, 'Buy', 3),
            _buildBottomNavItem(Icons.menu, 'Menu', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedBottomIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottomIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFFF4444) : const Color(0xFFB0B0B0), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF4444) : const Color(0xFFB0B0B0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
