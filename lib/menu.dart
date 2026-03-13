import 'package:dar_city_app/about_screen.dart';
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
  MoreMenuScreen({Key? key}) : super(key: key);

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.group, title: 'Team'),
    MenuItem(icon: Icons.settings, title: 'Settings'),
    MenuItem(icon: Icons.person, title: 'Fan Profile'),
    // MenuItem(icon: Icons.volunteer_activism, title: 'Donation Campaigns'), // Removed for App Store compliance
    MenuItem(icon: Icons.shopping_cart, title: 'My Carts'),
    MenuItem(icon: Icons.help, title: 'Help & Support'),
    MenuItem(icon: Icons.info, title: 'About App'),
    MenuItem(icon: Icons.logout, title: 'Logout'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return _buildMenuItem(context, menuItems[index]);
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: Colors.white),
      title: Text(item.title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: () async { // Make the onTap callback async
        if (item.title == 'Team') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeamPage()),
          );
        }
        if (item.title == 'Fan Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
        if (item.title == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsScreen()),
          );
        }
        if (item.title == 'About App') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          );
        }
        if (item.title == 'Help & Support') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          );
        }
        // Removed for App Store compliance
        // if (item.title == 'Donation Campaigns') {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (_) => const DonationCampaignsScreen()),
        //   );
        // }
        if (item.title == 'My Carts') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        }
        if (item.title == 'Logout') {
          // Await the async token removal.
          await SessionManager().clearToken();
          // clearCart is synchronous, so no await is needed.
          CartManager().clearCart();

          // Check if the widget is still in the tree after async operations.
          if (!context.mounted) return;

          // Navigate to Login Screen and remove all previous routes.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}
