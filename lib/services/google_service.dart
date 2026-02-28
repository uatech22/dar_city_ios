import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static const String baseUrl = ApiConfig.baseUrl;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return {'success': false, 'message': 'Google Sign-In canceled.'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return {'success': false, 'message': 'Failed to retrieve Google ID token.'};
      }

      // Send the token to your backend for verification and user creation/login
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': googleAuth.idToken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['token'] is String) {
          SessionManager().saveToken(responseData['token']);
        }
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Backend authentication failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during Google Sign-In: $e',
      };
    }
  }
  }
