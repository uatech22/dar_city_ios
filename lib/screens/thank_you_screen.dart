import 'package:dar_city_app/models/donation.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';

class ThankYouScreen extends StatelessWidget {
  final Donation donation;

  const ThankYouScreen({Key? key, required this.donation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Successful'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: darResponsiveBody(
        Center(
        child: Padding(
          padding: EdgeInsets.all(DarLayoutMetrics.of(context).horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Thank You For Your Donation!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your generous contribution is greatly appreciated. Your reference code is:',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                donation.referenceCode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
