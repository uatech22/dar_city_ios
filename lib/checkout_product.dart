import 'package:dar_city_app/models/cart_item.dart';
import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:dar_city_app/payment_screen.dart';
import 'package:dar_city_app/services/order_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'delivery_info.dart';

class ProductCheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const ProductCheckoutScreen({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<ProductCheckoutScreen> createState() => _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends State<ProductCheckoutScreen> {
  bool _isLoading = false;
  bool _wantsShipping = true;

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white)),
          content: const Text('You need to be logged in to continue.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Go to Login'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // This removes all previous routes
                );
              },
            ),
          ],
        );
      },
    );
  }

  double get _subtotal {
    return widget.cartItems.fold(0, (sum, item) {
      final itemPrice = item.price * (1 - item.product.discount / 100);
      return sum + (itemPrice * item.quantity);
    });
  }

  double get _deliveryCost {
    return widget.cartItems.fold(0, (sum, item) => sum + (item.product.deliveryCost * item.quantity));
  }

  Future<void> _placeOrder({bool withShipping = false}) async {
    String? token;
    try {
      token = await SessionManager().getToken();
    } catch (e) {
      // If there's any error reading the token, assume the user is not logged in.
      token = null;
    }

    if (!mounted) return;

    if (token == null) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final items = widget.cartItems.map((item) => {
        'product_id': item.product.id,
        'variant_id': item.variant.id, // Include variant_id
        'qty': item.quantity,
      }).toList();

      double total = _subtotal;
      if (withShipping) {
        total += _deliveryCost;
      }

      final Order createdOrder = await OrderService.createOrderProduct(
        items: items,
        totalAmount: total,
      );

      if (!mounted) return;

      if (withShipping) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryInformationScreen(order: createdOrder),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompletePaymentScreen(order: createdOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = _subtotal;
    if (_wantsShipping) {
      total += _deliveryCost;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Checkout'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Order Summary',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        return CheckoutItemCard(item: widget.cartItems[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SummaryRow(label: 'Subtotal', amount: 'TZS ${_subtotal.toStringAsFixed(2)}'),
                  if (_wantsShipping)
                    SummaryRow(label: 'Delivery', amount: 'TZS ${_deliveryCost.toStringAsFixed(2)}'),
                  const Divider(color: Colors.white24, height: 20),
                  SummaryRow(label: 'Total', amount: 'TZS ${total.toStringAsFixed(2)}', isTotal: true),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'I want shipping',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: _wantsShipping,
                        onChanged: (value) {
                          setState(() {
                            _wantsShipping = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _placeOrder(withShipping: _wantsShipping),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(_wantsShipping ? 'Proceed to Delivery' : 'Proceed to Payment'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CheckoutItemCard extends StatelessWidget {
  final CartItem item;

  const CheckoutItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemPrice = item.price * (1 - item.product.discount / 100);
    final totalItemPrice = itemPrice * item.quantity;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: item.product.imageUrl != null
            ? Image.network(
                item.product.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : Container(width: 60, height: 60, color: Colors.grey.shade800),
        title: Text(item.product.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.variant.displayName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Quantity: ${item.quantity}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        trailing: Text('TZS ${totalItemPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const SummaryRow({Key? key, required this.label, required this.amount, this.isTotal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white70, fontSize: 16)),
          Text(amount, style: TextStyle(color: isTotal ? Colors.white : Colors.white70, fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
