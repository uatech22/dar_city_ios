import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> sendResetLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'), 
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'An unknown error occurred.',
        };
      }
    } catch (e) {
      // Catches network errors and provides a more helpful message
      return {'success': false, 'message': 'Network error. Please check your connection and try again.'};
    }
  }
}
