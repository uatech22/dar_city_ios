class Seat {
  final int id;
  final int seatNumber;
  final String status;
  final String? row; // Added to store the row identifier

  Seat({
    required this.id,
    required this.seatNumber,
    required this.status,
    this.row,
  });

  // A method to create a copy of a Seat with a new row
  Seat copyWith({String? row}) {
    return Seat(
      id: id,
      seatNumber: seatNumber,
      status: status,
      row: row ?? this.row,
    );
  }

  factory Seat.fromJson(Map<String, dynamic> json) {
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

    return Seat(
      id: _parseFlexibleInt(json['id']),
      seatNumber: _parseFlexibleInt(json['seat_number']),
      status: json['status'] ?? 'unknown',
    );
  }
}
