import 'package:dar_city_app/config/api_config.dart';

/// Resolve team logo URL from match JSON (top-level or nested under team object).
String logoFromMatchJson(Map<String, dynamic> json, {required bool home}) {
  final prefix = home ? 'home' : 'away';

  final direct = json['${prefix}_team_logo'] ??
      json['${prefix}_logo'] ??
      json['${prefix}_logo_url'];
  if (direct != null && direct.toString().trim().isNotEmpty) {
    return normalizeLogoUrl(direct.toString());
  }

  final team = json['${prefix}_team'];
  if (team is Map<String, dynamic>) {
    for (final key in ['logo_url', 'logo', 'image', 'logo_path', 'emblem']) {
      final value = team[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return normalizeLogoUrl(value.toString());
      }
    }
  }

  return '';
}

String normalizeLogoUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  if (url.startsWith('/')) return '$base$url';
  return '$base/storage/$url';
}
