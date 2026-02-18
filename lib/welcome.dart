import 'package:dar_city_app/fanSignup.dart';
import 'package:flutter/material.dart';
import 'loginScreen.dart';
import 'fanMainDashboard.dart';
import 'RootScreenNavigation.dart';



class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? selectedRole;
  bool showAuthButtons = false;

  void _onRoleSelected(String role) {
    setState(() {
      selectedRole = role;
    });

    if (role == 'Fan') {
      //  DIRECT TO HOME PAGE AND REMOVE PREVIOUS SCREENS
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  RootScreen()),
        (Route<dynamic> route) => false, // This removes all routes below the new one
      );
    } else {
      //  Show Sign In / Sign Up
      setState(() {
        showAuthButtons = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              /// LOGO
              Image.asset(
                'assets/images/dar-city-logo.png',
                height: 180,
              ),

              const SizedBox(height: 30),

              const Text(
                'Welcome to Dar City\nBasketball',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Choose your role to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 40),

              _roleButton('Fan'),
              const SizedBox(height: 14),
              _roleButton('Player'),
              const SizedBox(height: 14),
              _roleButton('Sponsor'),
              const SizedBox(height: 14),
              _roleButton('Internal Team'),

              const SizedBox(height: 40),

              ///  SHOW ONLY IF NOT FAN
              if (showAuthButtons)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>  LoginScreen()),

                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF3A3A3A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>  SignUpScreen()),

                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role) {
    final bool isSelected = selectedRole == role;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _onRoleSelected(role),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red : const Color(0xFF2A2A2A),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: Text(
          role,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

///  SAMPLE HOME PAGE

