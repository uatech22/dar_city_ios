import 'dart:convert';
import 'dart:io';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/models/profile.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<Profile> getProfile() async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      print('PROFILE RESPONSE: ${response.body}');
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('user') && responseData['user'] is Map<String, dynamic>) {
        return Profile.fromJson(responseData['user']);
      } else {
        return Profile.fromJson(responseData);
      }
    } else {
      throw Exception('Failed to load profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> uploadPassportPhoto(File image) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/profile/passport'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(await http.MultipartFile.fromPath(
      'passport',
      image.path,
    ));

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
        final respStr = await response.stream.bytesToString();
        throw Exception('Failed to upload image. Status: ${response.statusCode}, Body: $respStr');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/profile/password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to change password.');
    }
  }
}
