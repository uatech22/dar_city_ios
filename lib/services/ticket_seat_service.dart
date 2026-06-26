import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/seat_section.dart';
import 'package:dar_city_app/models/seat_grid.dart';

class TicketSeat {
  static const baseUrl = ApiConfig.baseUrl;

  Future<List<SeatSection>> fetchSections(int matchId) async {
    final url = Uri.parse('$baseUrl/matches/$matchId/sections');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load sections (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);

    return (json['sections'] as List)
        .map((s) => SeatSection.fromJson(s))
        .toList();
  }


  Future<List<Seat>> fetchSeatGrid({
    required int matchId,
    required String section,
    required String row,
  }) async {
    final url =
        '$baseUrl/matches/$matchId/sections/$section/rows/$row/seats';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load seat grid');
    }

    final json = jsonDecode(response.body);

    return (json['seats'] as List)
        .map((s) => Seat.fromJson(s))
        .toList();
  }

}
