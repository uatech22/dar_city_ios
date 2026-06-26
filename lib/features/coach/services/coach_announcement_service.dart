import 'dart:convert';
import 'dart:io';

import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;

/// Screen #3 — Coach Team Announcement
class CoachAnnouncementService {
  /// POST /coach/announcements
  /// Auth: coach
  static Future<Announcement> publish(AnnouncementPayload payload) async {
    final json = await FeatureApiClient.postJson(
      '/coach/announcements',
      payload.toJson(),
    );
    return Announcement.fromJson(json);
  }

  /// GET /coach/announcements
  /// Auth: coach
  static Future<List<Announcement>> fetchAll() async {
    final list = await FeatureApiClient.getJsonList('/coach/announcements');
    return list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Resolve a single announcement by id (loads list — no dedicated endpoint yet).
  static Future<Announcement?> findById(String id) async {
    final all = await fetchAll();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// POST /coach/announcements/upload — multipart `file` + `type` (`image` | `video`)
  static Future<String> uploadMedia(File file, {required String type}) async {
    final token = SessionManager().getToken();
    if (token == null || token.isEmpty) {
      throw FeatureApiException(401, 'Not authenticated');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${FeatureApiClient.baseUrl}/coach/announcements/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['type'] = type;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send().timeout(FeatureApiClient.timeout);
    final body = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(body);
      final data = decoded is Map && decoded['data'] is Map
          ? decoded['data'] as Map<String, dynamic>
          : decoded is Map<String, dynamic>
              ? decoded
              : null;
      final url = data?['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
      throw FeatureApiException(response.statusCode, 'Upload succeeded but no URL returned');
    }

    final message = () {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          final raw = decoded['message']?.toString() ?? body;
          if (response.statusCode == 404 && raw.contains('could not be found')) {
            return 'Media upload is not set up on the server yet. '
                'Your backend dev needs to add POST /coach/announcements/upload.';
          }
          return raw;
        }
      } catch (_) {}
      return body;
    }();
    throw FeatureApiException(response.statusCode, message);
  }
}
