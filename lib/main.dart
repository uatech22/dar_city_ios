import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/push_notification_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'navigation/app_bootstrap.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotificationService.instance.init(navigatorKey: rootNavigatorKey);
  await SessionManager().loadSession();
  await CartManager().loadCart();
  await PushNotificationService.instance.syncDeviceTokenIfLoggedIn();

  runApp(const DarCityBasketballApp());
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
