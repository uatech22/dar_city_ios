import 'package:dar_city_app/models/product.dart';
import 'package:dar_city_app/models/product_variant_model.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  // Safely parse from JSON, protecting against null or malformed nested objects.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>? ?? {}),
      variant: ProductVariant.fromJson(json['variant'] as Map<String, dynamic>? ?? {}),
      quantity: json['quantity'] as int? ?? 1, // Default to 1 if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'variant': variant.toJson(),
      'quantity': quantity,
    };
  }

  // A unique ID for this cart item (product ID + variant ID)
  String get id => '${product.id}-${variant.id}';

  // Get the price from the variant
  double get price => variant.price;

}
