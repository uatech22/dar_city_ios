import 'dart:async';
import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/models/seat_grid.dart';
import 'package:dar_city_app/models/seat_section.dart';
import 'package:dar_city_app/loginScreen.dart';
import 'package:dar_city_app/payment_screen.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';

class SeatCheckoutSummaryScreen extends StatefulWidget {
  final int matchId;
  final Set<Seat> selectedSeats;
  final SeatSection section;
  final Order order;

  const SeatCheckoutSummaryScreen({
    Key? key,
    required this.matchId,
    required this.selectedSeats,
    required this.section,
    required this.order,
  }) : super(key: key);

  @override
  State<SeatCheckoutSummaryScreen> createState() => _SeatCheckoutSummaryScreenState();
}

class _SeatCheckoutSummaryScreenState extends State<SeatCheckoutSummaryScreen> {
  Timer? _timer;
  Duration _timeLeft = const Duration(minutes: 10);
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white)),
          content: const Text('You need to be logged in to proceed with payment.', style: TextStyle(color: Colors.white70)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _handlePayment() {
    final token = SessionManager().getToken();
    if (token == null) {
      _showLoginDialog();
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompletePaymentScreen(order: widget.order),
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft.inSeconds > 0) {
        if (mounted) {
          setState(() {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isTimeUp = true;
          });
        }
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Checkout Summary'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Dar City Basketball Team',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selected Seats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: ListView(
                children: widget.selectedSeats.map((seat) {
                   final price = widget.section.rows
                      .firstWhere((row) => row.row == seat.row, orElse: () => SeatRow(row: '', price: 0, availableSeats: 0))
                      .price;
                  return _buildSeatSummary('Seat Number ${seat.row}${seat.seatNumber}', '$price TZS');
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildPriceDetail('Subtotal', '${widget.order.totalAmount} TZS'),
            _buildPriceDetail('Grand Total', '${widget.order.totalAmount} TZS', isTotal: true),
            const SizedBox(height: 20),
            if (_isTimeUp)
              const Center(
                child: Text(
                  'Your session has expired. Please select seats again.',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seats are held for:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildTimerBox(minutes, 'Minutes'),
                      const SizedBox(width: 20),
                      _buildTimerBox(seconds, 'Seconds'),
                    ],
                  ),
                ],
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTimeUp ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey.shade700,
                ),
                child: const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatSummary(String seatNumber, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            seatNumber,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            price,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
    Widget _buildPriceDetail(String title, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isTotal ? Colors.yellow : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: isTotal ? Colors.yellow : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String time, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _isTimeUp ? Colors.grey.shade800 : Colors.red,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              time,
              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
