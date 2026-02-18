import 'dart:convert';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://darcitybasketball.com/api/auth';

  static const Duration timeout = Duration(seconds: 15);

  /// ===============================
  /// STEP 1: REGISTER (EMAIL + PASSWORD)
  /// ===============================
  static Future<Map<String, dynamic>> registerStepOne(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register/step-one'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  /// ===============================
  /// STEP 2: VERIFY EMAIL (CODE)
  /// ===============================
  static Future<Map<String, dynamic>> verifyEmail({
    required String token,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: _headers(),
        body: jsonEncode({
          'token': token,
          'code': code,
        }),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return _networkError();
    }
  }


  /// ===============================
  /// RESEND VERIFICATION CODE
  /// ===============================
  static Future<Map<String, dynamic>> resendVerificationCode(String token) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: _headers(),
        body: jsonEncode({'token': token}),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  /// ===============================
  /// STEP 3: COMPLETE PROFILE + AUTO LOGIN
  /// ===============================
  static Future<Map<String, dynamic>> completeProfile({
    required String token,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register/step-two'),
        headers: _headers(),
        body: jsonEncode({
          'token': token,
          'name': fullName,
          'phone': phone,
          'role': role,
        }),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  /// ===============================
  /// LOGIN
  /// ===============================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(timeout);

      // Temporarily print the raw response for debugging
      if (kDebugMode) {
        print('LOGIN RESPONSE: ${response.body}');
      }

      return _handleResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  /// ===============================
  /// HELPERS
  /// ===============================
  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // When a request is successful, check for a token and save it.
        if (data['token'] is String) {
          SessionManager().saveToken(data['token']);
        }
        return data;
      }

      if (response.statusCode == 422 && data['errors'] != null) {
        return {
          'success': false,
          'message': data['message'] ?? 'Validation error',
          'errors': data['errors'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Something went wrong',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse server response. Status: ${response.statusCode}, Body: ${response.body}',
      };
    }
  }

  static Map<String, dynamic> _networkError() => {
    'success': false,
    'message': 'Network error. Please check your connection.',
  };
}
