import 'package:dar_city_app/models/donation_campaign.dart';
import 'package:dar_city_app/screens/donation_payment_screen.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:flutter/material.dart';

class DonateFormScreen extends StatefulWidget {
  final DonationCampaign campaign;

  const DonateFormScreen({Key? key, required this.campaign}) : super(key: key);

  @override
  _DonateFormScreenState createState() => _DonateFormScreenState();
}

class _DonateFormScreenState extends State<DonateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _messageController = TextEditingController();

  double? _selectedAmount;
  bool _isAnonymous = false;
  bool _isCustomAmount = false;
  bool _isProcessing = false;

  final List<double> _predefinedAmounts = [10000, 25000, 50000, 100000];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _customAmountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onContinueToPayment() async {
    final token = await SessionManager().getToken();
    if (token == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You must be logged in to make a donation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final amount = _isCustomAmount ? double.tryParse(_customAmountController.text) : _selectedAmount;
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter a valid amount'), backgroundColor: Colors.red),
        );
        return;
      }

      final donationData = {
        'campaign_id': widget.campaign.id,
        'donor_name': _nameController.text,
        'donor_email': _emailController.text,
        'donor_phone': _phoneController.text,
        'amount': amount.toInt(),
        'type': 'one_time',
        'message': _messageController.text,
        'is_anonymous': _isAnonymous,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonationPaymentScreen(
            donationData: donationData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donate to ${widget.campaign.title}'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Information', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              Text('Choose Amount (Tsh)', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _predefinedAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount && !_isCustomAmount;
                  return ChoiceChip(
                    label: Text(_formatNumber(amount)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedAmount = amount;
                        _isCustomAmount = false;
                        _customAmountController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              ChoiceChip(
                label: const Text('Custom'),
                selected: _isCustomAmount,
                onSelected: (selected) {
                  setState(() {
                    _isCustomAmount = true;
                    _selectedAmount = null;
                  });
                },
              ),
              if (_isCustomAmount)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _customAmountController,
                    decoration: const InputDecoration(labelText: 'Enter Custom Amount', prefixText: 'Tsh '),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_isCustomAmount && (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0)) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message (Optional)', hintText: 'Add a message to the team...'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
               CheckboxListTile(
                title: const Text('Donate Anonymously'),
                subtitle: const Text('Your name will not appear in the top donors list.'),
                value: _isAnonymous,
                onChanged: (bool? value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _onContinueToPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.payment),
                  label: Text(_isProcessing ? 'Processing...' : 'Continue to Payment', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
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
