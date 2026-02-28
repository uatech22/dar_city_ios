class ProductVariant {
  final int id;
  final String? color;
  final String? size;
  final double price;
  final int stock;

  ProductVariant({
    required this.id,
    this.color,
    this.size,
    required this.price,
    required this.stock,
  });

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Safely parse from JSON with default values for missing/null fields.
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: parseInt(json['id']), 
      color: json['color'] as String?,
      size: json['size'] as String?,
      price: parseDouble(json['price']), 
      stock: parseInt(json['stock']), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color,
      'size': size,
      'price': price,
      'stock': stock,
    };
  }

  bool get isInStock => stock > 0;

  String get displayName {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (size != null && size!.isNotEmpty) parts.add(size!);
    return parts.join(' / ');
  }
}
