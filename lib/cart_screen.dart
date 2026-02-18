import 'package:dar_city_app/checkout_product.dart';
import 'package:dar_city_app/models/cart_item.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartManager _cartManager = CartManager();
  late List<CartItem> _cartItems;

  @override
  void initState() {
    super.initState();
    _cartItems = _cartManager.items;
  }

  void _updateCart() {
    setState(() {
      _cartItems = _cartManager.items;
    });
  }

  void _removeItem(CartItem item) {
    setState(() {
      // Correctly remove the item by passing the CartItem object
      _cartManager.removeFromCart(item);
      _cartItems = _cartManager.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return CartItemCard(
                        item: item,
                        onIncrement: () {
                          _cartManager.incrementItem(item);
                          _updateCart();
                        },
                        onDecrement: () {
                          _cartManager.decrementItem(item);
                          _updateCart();
                        },
                        onRemove: () => _removeItem(item),
                      );
                    },
                  ),
                ),
                _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow('Subtotal', _cartManager.subtotal),
          const SizedBox(height: 8),
          _buildPriceRow('Delivery Cost', _cartManager.totalDeliveryCost),
          const Divider(color: Colors.white24, height: 24),
          _buildPriceRow('Total', _cartManager.grandTotal, isTotal: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductCheckoutScreen(cartItems: _cartItems),
                  ),
                ).then((_) => _updateCart());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white70,
            fontSize: isTotal ? 20 : 16,
          ),
        ),
        Text(
          'TZS ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? Colors.red : Colors.white,
            fontSize: isTotal ? 22 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the discounted price based on the variant's price and product's discount
    final discountedPrice = item.price * (1 - item.product.discount / 100);

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        // Use imageUrl from product model
        leading: item.product.imageUrl != null
            ? Image.network(
                item.product.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red);
                },
              )
            : const SizedBox(width: 50, height: 50, child: Icon(Icons.image, color: Colors.grey)),
        title: Text(item.product.name, style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display variant information
            if (item.variant.displayName.isNotEmpty)
              Text(item.variant.displayName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            // Display the calculated discounted price
            Text(
              'TZS ${discountedPrice.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
              onPressed: onDecrement,
            ),
            Text(item.quantity.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70, size: 18),
              onPressed: onIncrement,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
