import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'thank_you_screen.dart';

class CreditDebitCardScreen extends StatefulWidget {
  final Order order;
  const CreditDebitCardScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<CreditDebitCardScreen> createState() => _CreditDebitCardScreenState();
}

class _CreditDebitCardScreenState extends State<CreditDebitCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardholderNameController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  Future<void> _handleConfirmPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _paymentService.makeCardPayment(
        orderId: widget.order.id,
        cardNumber: cardNumberController.text,
        cardHolderName: cardholderNameController.text,
        expiryDate: expiryDateController.text,
        cvv: cvvController.text,
      );

      if (mounted) {
        if (response.success) {
          // Clear the cart on successful payment
          CartManager().clearCart();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ThankYouScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Credit / Debit Card'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField('Card Number', cardNumberController),
                    _buildTextField('Cardholder Name', cardholderNameController),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('MM/YY', expiryDateController),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('CVV', cvvController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleConfirmPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Confirm Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Select Card'),
      items: const [
        DropdownMenuItem(value: 'Visa', child: Text('Visa')),
        DropdownMenuItem(value: 'MasterCard', child: Text('MasterCard')),
        DropdownMenuItem(value: 'American Express', child: Text('American Express')),
      ],
      onChanged: (_) {},
      validator: (value) => value == null ? 'Please select a card type' : null,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
