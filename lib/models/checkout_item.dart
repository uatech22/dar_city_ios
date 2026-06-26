import 'package:dar_city_app/models/cart_item.dart';

// A model to represent an item in the checkout summary.
class CheckoutItem {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String variantName;

  CheckoutItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.variantName,
  });

  // Helper to convert a CartItem into a CheckoutItem
  factory CheckoutItem.fromCartItem(CartItem item) {
    // The price on the variant is the base price.
    // We apply the product-level discount here.
    final discountedPrice = item.variant.price * (1 - item.product.discount / 100);

    return CheckoutItem(
      name: item.product.name,
      quantity: item.quantity,
      price: discountedPrice,
      imageUrl: item.product.imageUrl,
      variantName: item.variant.displayName,
    );
  }
}
