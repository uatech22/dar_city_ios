import 'package:dar_city_app/about_screen.dart';
import 'package:dar_city_app/help_support_screen.dart';
import 'package:dar_city_app/news_list.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/team_page.dart';
import 'package:dar_city_app/welcome.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'donate_screen.dart';
import 'settings.dart';
import 'seat_selection.dart';
import 'wishlist.dart';
import 'cart_screen.dart';
import 'match_tickets.dart';

class MoreMenuScreen extends StatelessWidget {
  MoreMenuScreen({Key? key}) : super(key: key);

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.group, title: 'Team'),
    MenuItem(icon: Icons.settings, title: 'Settings'),
    MenuItem(icon: Icons.person, title: 'Fan Profile'),
    // MenuItem(icon: Icons.money, title: 'Donate'),
    // MenuItem(icon: Icons.favorite, title: 'Wishlist'),
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
      onTap: () {
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
        // if (item.title == 'Wishlist') {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (_) => WishlistScreen()),
        //   );
        // }
        if (item.title == 'My Carts') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        }
        if (item.title == 'Logout') {
          // Clear user session and cart
          SessionManager().clearToken();
          CartManager().clearCart();

          // Navigate to Welcome Screen and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
