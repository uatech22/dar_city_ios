import 'package:dar_city_app/RootScreenNavigation.dart';
import 'package:dar_city_app/navigation/role_navigation.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/welcome.dart';
import 'package:flutter/material.dart';

/// Chooses Welcome vs role-specific home after session restore.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolveInitialScreen();
  }

  Future<void> _resolveInitialScreen() async {
    final token = SessionManager().getToken();
    if (token != null && token.isNotEmpty) {
      final home = await RoleNavigation.resolveAuthenticatedHome();
      if (!mounted) return;
      setState(() => _screen = home);
      return;
    }

    final onboardingDone = await WelcomeScreen.hasCompletedOnboarding();
    if (!mounted) return;
    setState(
      () => _screen = onboardingDone
          ? const RootScreen()
          : const WelcomeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }
    return _screen!;
  }
}
