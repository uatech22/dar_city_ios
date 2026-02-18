import 'dart:convert';
import 'package:dar_city_app/models/payment.dart';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class PaymentService {
  static const String _baseUrl = 'https://darcitybasketball.com/api';

  Future<PaymentResponse> makePayment({
    required int orderId,
    required String mobileProvider,
    required String mobileNumber,
    required String notificationEmail,
  }) async {
    final token = SessionManager().getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/pay'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_id': orderId,
        'payment_method': 'mobile',
        'mobile_provider': mobileProvider,
        'mobile_number': mobileNumber,
        'notification_email': notificationEmail,
      }),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Payment failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<PaymentResponse> makeCardPayment({
    required int orderId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
  }) async {
    final token = SessionManager().getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/pay'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_id': orderId,
        'payment_method': 'card',
        'card_number': cardNumber,
        'cardholder_name': cardHolderName,
        'expiry_date': expiryDate,
        'cvv': cvv,
      }),
    );

    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Payment failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
