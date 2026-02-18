import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/services/cart_manager.dart';
import 'package:dar_city_app/services/payment_service.dart';
import 'package:dar_city_app/thank_you_screen.dart';
import 'models/payment_response.dart';
import 'package:flutter/material.dart';
import 'card.dart';

class CompletePaymentScreen extends StatefulWidget {
  final Order order;
  const CompletePaymentScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<CompletePaymentScreen> createState() => _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends State<CompletePaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String? selectedPaymentOption;
  final _formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final connectedMobileController = TextEditingController();
  bool _isLoading = false;

  bool get isCardPayment => selectedPaymentOption == 'Credit or Debit Card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Complete Your Payment'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    Text(
                      'Total: TZS ${widget.order.totalAmount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      'Mobile Number for Receipt',
                      mobileController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a mobile number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      'Email Address',
                      emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email address';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Payment Options',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    _paymentOption('Airtel Money'),
                    _paymentOption('Tigo Pesa'),
                    _paymentOption('HaloPesa'),
                    _paymentOption('Azam Pesa'),
                    _paymentOption('M-Pesa'),
                    _paymentOption('Credit or Debit Card'),

                    const SizedBox(height: 15),

                    /// SHOW ONLY FOR MOBILE MONEY
                    if (!isCardPayment && selectedPaymentOption != null)
                      _buildTextField(
                        'Connected Mobile Number',
                        connectedMobileController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the connected mobile number';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handlePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: const Text('Proceed to Pay'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// HANDLE PAYMENT FLOW
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedPaymentOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment option')),
      );
      return;
    }

    if (isCardPayment) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreditDebitCardScreen(order: widget.order),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _paymentService.makePayment(
        orderId: widget.order.id,
        mobileProvider: selectedPaymentOption!,
        mobileNumber: connectedMobileController.text,
        notificationEmail: emailController.text,
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

  /// PAYMENT OPTION RADIO
  Widget _paymentOption(String option) {
    return RadioListTile<String>(
      title: Text(option, style: const TextStyle(color: Colors.white)),
      value: option,
      groupValue: selectedPaymentOption,
      activeColor: Colors.red,
      onChanged: (value) {
        setState(() {
          selectedPaymentOption = value;
        });
      },
    );
  }

  /// TEXT FIELD
  Widget _buildTextField(
    String label, 
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
