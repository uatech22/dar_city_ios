import 'dart:async';
import 'dart:convert';

import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;

/// Shared HTTP client for v2 feature services (coach / player / attendance / discipline).
class FeatureApiClient {
  FeatureApiClient._();

  static const baseUrl = ApiConfig.baseUrl;
  static const timeout = Duration(seconds: 15);

  static Map<String, String> headers({bool auth = true}) {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = SessionManager().getToken();
      if (token != null && token.isNotEmpty) {
        map['Authorization'] = 'Bearer $token';
      }
    }
    return map;
  }

  static Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _get(path);
    return _parseObject(response);
  }

  static Future<List<dynamic>> getJsonList(String path) async {
    final response = await _get(path);
    return _parseList(response);
  }

  static Future<http.Response> _get(String path) async {
    try {
      return await http
          .get(Uri.parse('$baseUrl$path'), headers: headers())
          .timeout(timeout);
    } on TimeoutException {
      throw FeatureApiException(
        408,
        'Request timed out. Check that the server at $baseUrl is running and reachable.',
      );
    }
  }

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _parseObject(response);
  }

  static Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _parseObject(response);
  }

  static Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _parseObject(response);
  }

  static Map<String, dynamic> _parseObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
      }
      throw FeatureApiException(response.statusCode, 'Expected JSON object');
    }
    throw FeatureApiException(
      response.statusCode,
      decoded is Map ? (decoded['message'] ?? response.body) : response.body,
    );
  }

  static List<dynamic> _parseList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      if (decoded is List) return decoded;
      throw FeatureApiException(response.statusCode, 'Expected JSON list');
    }
    throw FeatureApiException(
      response.statusCode,
      decoded is Map ? (decoded['message'] ?? response.body) : response.body,
    );
  }
}

class FeatureApiException implements Exception {
  FeatureApiException(this.statusCode, this.message);

  final int statusCode;
  final dynamic message;

  @override
  String toString() => 'FeatureApiException($statusCode): $message';
}
