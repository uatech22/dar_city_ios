import 'package:dar_city_app/models/product_variant_model.dart';

class Product {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final String? category;
  final double deliveryCost;
  final double discount;
  final String? imageUrl;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.category,
    required this.deliveryCost,
    required this.discount,
    this.imageUrl,
    required this.variants,
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

  // Safely parse from JSON with default values and robust variant parsing.
  factory Product.fromJson(Map<String, dynamic> json) {
    var variantsJson = json['variants'] as List?;
    List<ProductVariant> productVariants = (variantsJson != null)
        ? variantsJson.map((v) => ProductVariant.fromJson(v)).toList()
        : [];

    return Product(
      id: parseInt(json['id']),
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Product',
      description: json['description'] as String?,
      category: json['category'] as String?,
      deliveryCost: parseDouble(json['delivery_cost']),
      discount: parseDouble(json['discount']),
      imageUrl: json['image_url'] as String?,
      variants: productVariants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'category': category,
      'delivery_cost': deliveryCost,
      'discount': discount,
      'image_url': imageUrl,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  bool get hasVariants => variants.isNotEmpty;
}
