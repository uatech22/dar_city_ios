import 'dart:convert';
import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = 'https://darcitybasketball.com/api';
  
  
//service for create ticket order 
  Future<Order> createOrder({
    required int matchId,
    required List<int> seatIds,
    required int totalAmount,
  }) async {
    final url = Uri.parse('$baseUrl/orders');
    
    final token = await SessionManager().getToken();

    if (token == null) {
      throw Exception('User is not authenticated. Cannot create order.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'match_id': matchId,
        'seats': seatIds, 
        'total_amount': totalAmount,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('data')) {
        return Order.fromJson(responseData['data']);
      } else if (responseData.containsKey('order')) {
        return Order.fromJson(responseData['order']);
      } else {
        return Order.fromJson(responseData);
      }
    } else {
      throw Exception('Failed to create order. Status code: ${response.statusCode}\nResponse: ${response.body}');
    }
  }

  
  
  
  //service for create product order
  static Future<Order> createOrderProduct({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final token = await SessionManager().getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/orderproduct'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items,
        'total_amount': totalAmount,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('data')) {
        return Order.fromJson(responseData['data']);
      } else if (responseData.containsKey('order')) {
        return Order.fromJson(responseData['order']);
      } else {
        return Order.fromJson(responseData);
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Order creation failed');
    }
  }
}
