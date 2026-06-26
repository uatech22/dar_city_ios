import 'dart:convert';

import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/features/coach/screens/coach_team_announcement_screen.dart';
import 'package:dar_city_app/features/discipline/screens/performance_salary_alert_screen.dart';
import 'package:dar_city_app/models/news_model.dart';
import 'package:dar_city_app/navigation/role_navigation.dart';
import 'package:dar_city_app/news_article_details.dart';
import 'package:dar_city_app/profile_screen.dart';
import 'package:dar_city_app/services/news_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Background FCM handler — must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Registers FCM device tokens with Laravel and routes notification taps.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;
    if (!_isMobile) {
      debugPrint('Push notifications skipped — not Android/iOS');
      return;
    }
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    messaging.onTokenRefresh.listen((_) => syncDeviceTokenIfLoggedIn());

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMessageOpened(initial);
      });
    }

    _initialized = true;
    debugPrint('Push notifications initialized');
  }

  /// POST /api/push/device-token after login or on cold start.
  Future<void> syncDeviceTokenIfLoggedIn() async {
    if (!_isMobile) return;

    final authToken = SessionManager().getToken();
    if (authToken == null || authToken.isEmpty) return;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      debugPrint('FCM Token: $fcmToken');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/push/device-token'),
            headers: _authHeaders(authToken),
            body: jsonEncode({'token': fcmToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Device token registered with backend');
      } else {
        debugPrint(
          'Device token registration failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Device token registration error: $e');
    }
  }

  /// DELETE /api/push/device-token on logout.
  Future<void> unregisterDeviceToken() async {
    if (!_isMobile) return;

    final authToken = SessionManager().getToken();
    if (authToken == null || authToken.isEmpty) return;

    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/push/device-token'),
            headers: _authHeaders(authToken),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Device token removed from backend');
      } else {
        debugPrint(
          'Device token removal failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Device token removal error: $e');
    }
  }

  Map<String, String> _authHeaders(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  void _onMessageOpened(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;
    _openFromNotificationData(data);
  }

  Future<void> _openFromNotificationData(Map<String, dynamic> data) async {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final type = (data['type'] ?? '').toString().toLowerCase().trim();
    final role = SessionManager().getRole();
    final normalizedRole = _normalizeRole(role);

    switch (type) {
      case 'news':
      case 'article':
        await _openNews(navigator, data);
        return;
      case 'announcement':
      case 'team_announcement':
        if (normalizedRole == 'coach') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const CoachTeamAnnouncementScreen(),
            ),
          );
        }
        return;
      case 'alert':
      case 'team_alert':
      case 'performance_alert':
        navigator.push(
          MaterialPageRoute(
            builder: (_) => PerformanceSalaryAlertScreen(
              forCoach: normalizedRole == 'coach',
            ),
          ),
        );
        return;
      case 'profile':
        navigator.push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        return;
      case 'schedule':
      case 'match':
      case 'game':
      case 'live_match':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RoleNavigation.homeForRole(role)),
          (_) => false,
        );
        return;
      default:
        debugPrint('Unhandled push type: $type');
    }
  }

  Future<void> _openNews(
    NavigatorState navigator,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'] ?? data['news_id'];
    if (id == null) return;

    try {
      final news = await NewsService.getNewsDetails(id.toString());
      if (!navigator.mounted) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
      );
    } catch (e) {
      debugPrint('Failed to open news from push: $e');
      final fallback = News(
        id: id.toString(),
        title: data['title']?.toString() ?? 'News',
        content: data['body']?.toString() ?? '',
      );
      if (!navigator.mounted) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: fallback)),
      );
    }
  }

  String _normalizeRole(String? role) {
    if (RoleNavigation.usesCoachShell(role)) return 'coach';
    final value = role?.toLowerCase().trim() ?? '';
    if (value == 'player') return 'player';
    return 'fan';
  }
}
