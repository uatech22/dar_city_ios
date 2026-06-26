import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Future<List<News>> fetchNews() async {
    final response = await http.get(Uri.parse('$_baseUrl/news'));

    if (response.statusCode == 200) {
      final dynamic decodedData = json.decode(response.body);

      // --- DEBUGGING STEP --- 
      if (kDebugMode) {
        print('--- NEWS API RESPONSE ---');
        print('Response Type: ${decodedData.runtimeType}');
        print('Response Body: $decodedData');
        print('--- END NEWS API RESPONSE ---');
      }
      // --- END DEBUGGING STEP ---


      final Map<String, dynamic> responseData = decodedData;
      final List<dynamic> newsList = responseData['data'];
      return newsList.map((json) => News.fromJson(json)).toList();

    } else {
      throw Exception('Failed to load news');
    }
  }

  static Future<News> getNewsDetails(String newsId) async {
    final response = await http.get(Uri.parse('$_baseUrl/news/$newsId'));

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      return News.fromJson(data);
    } else {
      throw Exception('Failed to load news details. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Records a unique view when a fan opens an article. No-op if endpoint missing.
  static Future<int?> recordView(String newsId) async {
    await SessionManager().loadToken();
    final token = SessionManager().getToken();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/news/$newsId/view'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      final decoded = json.decode(response.body);
      final data = decoded is Map<String, dynamic>
          ? (decoded['data'] as Map<String, dynamic>? ?? decoded)
          : null;
      if (data == null) return null;
      return int.tryParse(
        data['views_count']?.toString() ??
            data['view_count']?.toString() ??
            data['views']?.toString() ??
            '',
      );
    } catch (e) {
      if (kDebugMode) print('NewsService.recordView: $e');
      return null;
    }
  }
}
