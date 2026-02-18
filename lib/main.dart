import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'welcome.dart';
import 'RootScreenNavigation.dart';

// main function  await the session check.
Future<void> main() async {
  // Ensures that Flutter bindings are initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Load the stored token from secure storage.
  await SessionManager().loadToken();
  final String? token = SessionManager().getToken();

  // Load the cart from shared preferences.
  await CartManager().loadCart();

  // Determine the correct initial screen based on whether a token exists.
  runApp(DarCityBasketballApp(
    initialScreen: token != null ? RootScreen() : const WelcomeScreen(),
  ));
}

class DarCityBasketballApp extends StatelessWidget {
  final Widget initialScreen;

  // The app constructor accepts the initialScreen to be displayed.
  const DarCityBasketballApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dar City Basketball',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
      // Use the determined initial screen as the home page.
      home: initialScreen,
    );
  }
}
