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
      final decoded = json.decode(res.body);
      List<dynamic> list;
      if (decoded is Map && decoded['data'] is List) {
        list = decoded['data'] as List;
      } else if (decoded is List) {
        list = decoded;
      } else {
        throw Exception('Unexpected finished-matches response shape');
      }
      return list
          .map((e) => Result.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load past results. Status Code: ${res.statusCode}');
    }
  }

  /// Upcoming + finished matches for the fan schedule calendar.
  static Future<List<Game>> fetchScheduleCalendar() async {
    final results = await Future.wait([
      fetchUpcomingMatches().catchError((_) => <Game>[]),
      fetchFinishedMatches().catchError((_) => <Result>[]),
    ]);

    final upcoming = results[0] as List<Game>;
    final finished = (results[1] as List<Result>).map((r) => r.toScheduleGame());

    final merged = <Game>[...finished, ...upcoming];
    merged.sort((a, b) {
      final ad = a.scheduledAt ?? DateTime(2100);
      final bd = b.scheduledAt ?? DateTime(2100);
      return ad.compareTo(bd);
    });
    return merged;
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
