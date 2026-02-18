class PaymentResponse {
  final bool success;
  final String message;

  PaymentResponse({required this.success, required this.message});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An unknown error occurred',
    );
  }
}
