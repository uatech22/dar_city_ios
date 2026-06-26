import 'dart:convert';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;

class DeliveryService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<void> saveDeliveryInfo({
    required int orderId,
    required String fullName,
    required String streetAddress,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
  }) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User is not authenticated.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/delivery'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'customer_name': fullName,
        'customer_address': streetAddress,
        'city': city,
        'state_province': state,
        'postal_code': postalCode,
        'country': country,
        'customer_phone': phone,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save delivery information. Status: ${response.statusCode} Body: ${response.body}');
    }
  }
}
