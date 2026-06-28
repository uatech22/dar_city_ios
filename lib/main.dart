import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/push_notification_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'navigation/app_bootstrap.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const DarCityBasketballApp());

  _initializeAppServices();
}

Future<void> _initializeAppServices() async {
  try {
    await PushNotificationService.instance
        .init(navigatorKey: rootNavigatorKey)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Push init failed: $e');
  }

  try {
    await SessionManager()
        .loadSession()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Session load failed: $e');
  }

  try {
    await CartManager()
        .loadCart()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Cart load failed: $e');
  }

  try {
    await PushNotificationService.instance
        .syncDeviceTokenIfLoggedIn()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Token sync failed: $e');
  }
}

class DarCityBasketballApp extends StatelessWidget {
  const DarCityBasketballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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
      home: const AppBootstrap(),
    );
  }
}
