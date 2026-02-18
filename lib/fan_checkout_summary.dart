import 'package:dar_city_app/models/order.dart';
import 'package:flutter/material.dart';
import 'payment_screen.dart';

class CheckoutSummaryScreen extends StatelessWidget {
  final Order order;

  const CheckoutSummaryScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // These would ideally come from a more detailed order object or another service call
    const String gameName = 'Dar City vs. JKT';
    const String gameTime = 'Sat, Jul 20 - 7:00 PM';
    final double bookingFee = 10000;
    final double tax = 0; // Example tax
    final double grandTotal = order.totalAmount + bookingFee + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Dar City Basketball',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              gameName,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const Text(
              gameTime,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            _buildPriceDetail('Subtotal', 'TZS ${order.totalAmount}'),
            _buildPriceDetail('Booking Fee', 'TZS ${bookingFee.toStringAsFixed(0)}'),
            _buildPriceDetail('Tax Charges', 'TZS ${tax.toStringAsFixed(0)}'),
            const Divider(color: Colors.white24, height: 20),
            _buildPriceDetail('Grand Total', 'TZS ${grandTotal.toStringAsFixed(0)}', isTotal: true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompletePaymentScreen(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail(String title, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isTotal ? Colors.yellow : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: isTotal ? Colors.yellow : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
