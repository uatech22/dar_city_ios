import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/models/country.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<Country>> getCountries() async {
    // Corrected the endpoint to match the likely API structure
    final response = await http.get(
      Uri.parse('$_baseUrl/locations/countries'), 
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['countries'];
      return (data as List).map((json) => Country.fromJson(json)).toList();
    } else {
      // Added more descriptive error
      throw Exception('Failed to load countries. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<String>> getRegions(String iso2) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/locations/countries/$iso2/regions'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['regions'];
      return data.map<String>((r) => r['name'].toString()).toList();
    } else {
      // Added more descriptive error
      throw Exception('Failed to load regions. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
