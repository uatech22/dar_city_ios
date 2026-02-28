import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import 'package:dar_city_app/models/game_results.dart';
import 'package:dar_city_app/models/live_matches.dart';

class MatchService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Game>> fetchUpcomingMatches() async {
    final url = Uri.parse('$baseUrl/upcoming-matches');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData.containsKey('data') && jsonData['data'] is List) {
        final List<dynamic> gamesData = jsonData['data'];
        return gamesData.map((json) => Game.fromJson(json)).toList();
      } else {
        throw Exception('API response does not contain a list of games under the "data" key. Response: ${response.body}');
      }
    } else {
      throw Exception('Failed to load upcoming matches. Status code: ${response.statusCode}');
    }
  }

  static Future<Game?> fetchNextGame() async {
    final upcomingGames = await fetchUpcomingMatches();
    if (upcomingGames.isNotEmpty) {
      //  list from the API is sorted by date, the first one is the next game.
      return upcomingGames.first;
    }
    return null;
  }

  static Future<List<Result>> fetchFinishedMatches() async {
    final res = await http.get(
      Uri.parse('$baseUrl/finished-matches'),
    );

    if (res.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(res.body);
      return jsonData.map((e) => Result.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load past results. Status Code: ${res.statusCode}');
    }
  }

  static Future<LiveMatch?> fetchLiveMatch() async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-match'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return LiveMatch.fromJson(json['data']);
      }
      // If the server says success:false or data is null, it means no live match now.
      return null;
    } else {
      // Throw an error to make the problem visible in the UI.
      throw Exception('Failed to load live match. Server responded with ${response.statusCode}: ${response.body}');
    }
  }
}
