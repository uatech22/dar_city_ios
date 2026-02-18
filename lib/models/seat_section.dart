class SeatSection {
  final String section;
  final List<SeatRow> rows;

  SeatSection({required this.section, required this.rows});

  factory SeatSection.fromJson(Map<String, dynamic> json) {
    return SeatSection(
      section: json['section'] ?? 'Unknown Section',
      rows: (json['rows'] as List)
          .map((r) => SeatRow.fromJson(r))
          .toList(),
    );
  }
}

class SeatRow {
  final String row;
  final int price;
  final int availableSeats;

  SeatRow({required this.row, required this.price, required this.availableSeats});

  factory SeatRow.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numbers from dynamic values.
    // This handles integers, doubles, and string representations of numbers.
    int _parseFlexibleInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.toInt();
      }
      if (value is String) {
        // Try parsing as a double first to handle strings like "10000.00"
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) {
          return doubleValue.toInt();
        }
        // Fallback to parsing as an int for strings like "10000"
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return SeatRow(
      row: json['row'] ?? 'N/A',
      price: _parseFlexibleInt(json['price']),
      availableSeats: _parseFlexibleInt(json['available_seats']),
    );
  }
}
