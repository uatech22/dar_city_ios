class TicketItem {
  final int id;
  final String seatNumber;
  final int price;

  TicketItem({required this.id, required this.seatNumber, required this.price});

  factory TicketItem.fromJson(Map<String, dynamic> json) {
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

    return TicketItem(
      id: _parseFlexibleInt(json['id']),
      seatNumber: '${json['seat']?['row'] ?? ''}${json['seat']?['seat_number'] ?? ''}',
      price: _parseFlexibleInt(json['price']),
    );
  }
}
