class Delivery {
  final int id;
  final int orderId;
  final int userId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final DateTime createdAt;

  Delivery({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
    required this.createdAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerAddress: json['customer_address'],
      city: json['city'],
      stateProvince: json['state_province'],
      postalCode: json['postal_code'],
      country: json['country'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
