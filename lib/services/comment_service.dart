import 'dart:convert';
import 'package:dar_city_app/models/comment.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;

class CommentService {
  static const String _baseUrl = 'http://192.168.1.3:8000/api';

  Future<List<Comment>> getComments(String newsId) async {
    final token = await SessionManager().getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse('$_baseUrl/news/$newsId/comments'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> postComment(String newsId, String content) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/news/$newsId/comments'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'comment': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post comment. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> postReply(int commentId, String content) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/comments/$commentId/reply'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'comment': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post reply. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete comment. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> toggleNewsLike(String newsId) async {
    final token = await SessionManager().getToken();
    if (token == null) throw Exception('User not authenticated.');

    final response = await http.post(
      Uri.parse('$_baseUrl/news/$newsId/like'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle like on news. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> toggleCommentLike(int commentId) async {
    final token = await SessionManager().getToken();
    if (token == null) throw Exception('User not authenticated.');

    final response = await http.post(
      Uri.parse('$_baseUrl/comments/$commentId/like'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
       return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle like on comment. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
