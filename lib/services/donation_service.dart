import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/models/donation.dart';
import 'package:dar_city_app/models/top_donor.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:dar_city_app/models/donation_campaign.dart';

class DonationService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<DonationCampaign>> getCampaigns({String? category}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/donations/campaigns').replace(
        queryParameters: {'category': category}..removeWhere((key, value) => value == null),
      );

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final campaignsData = responseData['data'] as List? ?? [];
        return campaignsData.map((json) => DonationCampaign.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load campaigns: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching campaigns: $e');
    }
  }

  Future<List<TopDonor>> getTopDonors(int campaignId, {int limit = 10}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/donations/campaigns/$campaignId/top-donors').replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final topDonorsData = responseData['top_donors'] as List? ?? [];
        return topDonorsData.map((json) => TopDonor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load top donors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching top donors: $e');
    }
  }

  Future<Donation> createDonation(Map<String, dynamic> donationData) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User is not authenticated. Cannot create donation.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/donations/donate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(donationData),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Donation.fromJson(responseData['donation']);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create donation');
    }
  }

  Future<Donation> completeDonation(int donationId, String? transactionId) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User is not authenticated. Cannot complete donation.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/donations/donations/$donationId/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': 'success',
        'transaction_id': transactionId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Donation.fromJson(responseData['donation']);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to complete donation');
    }
  }
}
