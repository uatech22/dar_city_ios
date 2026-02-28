import 'package:dar_city_app/models/donation.dart';
import 'package:dar_city_app/screens/thank_you_screen.dart';
import 'package:dar_city_app/services/donation_service.dart';
import 'package:flutter/material.dart';

class DonationPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> donationData;

  const DonationPaymentScreen({Key? key, required this.donationData}) : super(key: key);

  @override
  _DonationPaymentScreenState createState() => _DonationPaymentScreenState();
}

class _DonationPaymentScreenState extends State<DonationPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processDonation() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final fullDonationData = {
      ...widget.donationData,
      'payment_method': _selectedPaymentMethod,
      if (_selectedPaymentMethod == 'mobile_money')
         'donor_phone': _phoneController.text,
    };

    try {
      // 1. Create the donation record
      final initialDonation = await DonationService().createDonation(fullDonationData);

      // 2. Immediately complete the donation (simulating a successful payment)
      final completedDonation = await DonationService().completeDonation(initialDonation.id, 'simulated_transaction_id');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ThankYouScreen(donation: completedDonation),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Donation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Total Amount: Tsh ${_formatNumber(widget.donationData['amount'].toDouble())}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildPaymentOption('Mobile Money', 'mobile_money', Icons.phone_android),
              _buildPaymentOption('Credit Card', 'credit_card', Icons.credit_card),
              _buildPaymentOption('Bank Transfer', 'bank_transfer', Icons.account_balance),
              _buildPaymentOption('Cash', 'cash', Icons.money),
              
              if (_selectedPaymentMethod == 'mobile_money')
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number for Payment'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number for mobile money payment';
                      }
                      return null;
                    },
                  ),
                ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processDonation,
                  icon: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.lock),
                  label: Text(_isProcessing ? 'Processing...' : 'Complete Donation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String value, IconData icon) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedPaymentMethod,
      secondary: Icon(icon),
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue;
        });
      },
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}
