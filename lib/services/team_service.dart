import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import 'package:dar_city_app/models/team.dart';

class TeamService {
  static const baseUrl = ApiConfig.baseUrl;


  static Future<List<Person>> fetchPlayers() async {
    final res = await http.get(Uri.parse('$baseUrl/team/players'));

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return (body['data'] as List)
          .map((e) => Person.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load players');
    }
  }

  static Future<List<Person>> fetchCoaches() async {
    final res = await http.get(Uri.parse('$baseUrl/team/coaches'));

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return (body['data'] as List)
          .map((e) => Person.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load coaches');
    }
  }
//refresh player every seconds
  static Future<Person> fetchSinglePerson(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/players/$id'),
    );

    if (response.statusCode == 200) {
      return Person.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to refresh player');
    }
  }

  static Future<List<Team>> getTeams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => Team.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }


  /// Fetch single team details
  static Future<Team> getTeamDetails(int teamId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Team.fromJson(data['data']);
    } else {
      throw Exception(
        'Failed to load team details. Status: ${response.statusCode}',
      );
    }
  }
}
