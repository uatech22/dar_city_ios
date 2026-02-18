import 'package:dar_city_app/models/ticket_item.dart';

class Order {
  final int id;
  final int totalAmount;
  final String status;
  final List<TicketItem> tickets;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.tickets,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int _parseFlexibleInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) return doubleValue.toInt();
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return Order(
      id: _parseFlexibleInt(json['id']),
      totalAmount: _parseFlexibleInt(json['total_amount']),
      status: json['status'] ?? 'pending',
      tickets: (json['tickets'] as List? ?? [])
          .map((item) => TicketItem.fromJson(item))
          .toList(),
    );
  }
}
