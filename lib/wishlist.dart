import 'package:flutter/material.dart';

void main() {
  runApp(DarCityBasketballApp());
}

class DarCityBasketballApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dar City Basketball',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Updated for Flutter 3.0+
        ),
      ),
      home: WishlistScreen(),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildEventCard('Dar City vs. JKT', '\$50', 'Section 102, Row 5, Seat 12'),
                  _buildEventCard('Dar City vs. Outsiders', '\$75', 'Section 205, Row 10, Seat 25'),
                  _buildEventCard('Dar City vs. ABC', '\$60', 'Section 101, Row 3, Seat 8'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String price, String details) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Placeholder for event image
            Container(
              width: 100,
              height: 70,
              color: Colors.grey, // Replace with actual image
              child: const Center(child: Text('Image', style: TextStyle(color: Colors.white))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original Price: $price',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    details,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle buy now action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Buy Now'),
            ),
          ],
        ),
      ),
    );
  }
}