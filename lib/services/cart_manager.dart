import 'dart:convert';

import 'package:dar_city_app/models/cart_item.dart';
import 'package:dar_city_app/models/product.dart';
import 'package:dar_city_app/models/product_variant_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartManager {
  CartManager._internal();

  static final CartManager _instance = CartManager._internal();

  factory CartManager() => _instance;

  final List<CartItem> _cartItems = [];
  static const _cartKey = 'cart_items';
  bool _isCartLoaded = false;

  /// Loads the cart from device storage.

  Future<void> loadCart() async {
    if (_isCartLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);

    if (cartString != null && cartString.isNotEmpty) {
      try {
        final List<dynamic> cartJson = jsonDecode(cartString);
        _cartItems.clear();

        // Loop through and parse items individually for robustness.
        // This prevents one bad item from corrupting the whole cart.
        for (var itemJson in cartJson) {
          try {
            if (itemJson is Map<String, dynamic>) {
              _cartItems.add(CartItem.fromJson(itemJson));
            }
          } catch (e) {
            // Log error for a specific item but continue processing others.
            if (kDebugMode) {
              print('Skipping a malformed cart item: $e');
            }
          }
        }
      } catch (e) {

        if (kDebugMode) {
          print('Could not decode cart JSON, old data preserved: $e');
        }
        _cartItems.clear(); // Start with an empty cart for this session only.
      }
    }
    _isCartLoaded = true;
  }

  /// Saves the entire cart to device storage.
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = _cartItems.map((item) => item.toJson()).toList();
    await prefs.setString(_cartKey, jsonEncode(cartJson));
  }

  List<CartItem> get items => List.unmodifiable(_cartItems);

  void addToCart(Product product, ProductVariant variant) {
    final cartItemId = '${product.id}-${variant.id}';
    final existingItemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);

    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(CartItem(product: product, variant: variant));
    }
    _saveCart();
  }

  void incrementItem(CartItem item) {
    final index = _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    if (index != -1) {
      _cartItems[index].quantity++;
      _saveCart();
    }
  }

  void decrementItem(CartItem item) {
    final index = _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    if (index != -1) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      _saveCart();
    }
  }

  void removeFromCart(CartItem item) {
    _cartItems.removeWhere((cartItem) => cartItem.id == item.id);
    _saveCart();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
  }

  double get subtotal {
    return _cartItems.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  double get totalDeliveryCost {
    if (_cartItems.isEmpty) return 0;
    return _cartItems.fold(
        0,
        (total, item) =>
            total + (item.product.deliveryCost * item.quantity));
  }

  double get grandTotal {
    return subtotal + totalDeliveryCost;
  }
}
