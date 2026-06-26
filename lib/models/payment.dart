class PaymentResponse {
  final bool success;
  final String paymentReference;
  final String orderStatus;
  final String message;


  PaymentResponse({
    required this.success,
    required this.message,
    required this.paymentReference,
    required this.orderStatus,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      paymentReference: json['payment_reference'] ?? '',
      orderStatus: json['order_status'] ?? 'unknown',
      message: json['message'] ?? 'An unknown error occurred',
    );
  }
}
