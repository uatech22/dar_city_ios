import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  static const String _baseUrl = 'https://darcitybasketball.com/api';

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
}
