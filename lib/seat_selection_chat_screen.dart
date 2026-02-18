import 'dart:async';
import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/models/seat_grid.dart';
import 'package:dar_city_app/models/seat_section.dart';
import 'package:dar_city_app/services/order_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:dar_city_app/services/ticket_seat_service.dart';
import 'package:flutter/material.dart';
import 'loginScreen.dart';
import 'seat_checkout_summary.dart';

class SeatsSelectionChartScreen extends StatefulWidget {
  final int matchId;
  final SeatSection section;

  const SeatsSelectionChartScreen({
    Key? key,
    required this.matchId,
    required this.section,
  }) : super(key: key);

  @override
  State<SeatsSelectionChartScreen> createState() => _SeatsSelectionChartScreenState();
}

class _SeatsSelectionChartScreenState extends State<SeatsSelectionChartScreen> {
  final OrderService _orderService = OrderService();
  Timer? _timer;
  List<Seat>? _seats;
  bool _isLoading = true;
  String? _error;
  final Set<Seat> _selectedSeats = {};

  @override
  void initState() {
    super.initState();
    _fetchAllSeats();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAllSeats(showLoading: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllSeats({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final seatService = TicketSeat();
      final List<Seat> allSeats = [];
      for (final row in widget.section.rows) {
        final seatsInRow = await seatService.fetchSeatGrid(
          matchId: widget.matchId,
          section: widget.section.section,
          row: row.row,
        );
        final seatsWithRow = seatsInRow.map((seat) => seat.copyWith(row: row.row)).toList();
        allSeats.addAll(seatsWithRow);
      }
      if (mounted) {
        setState(() {
          _seats = allSeats;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white)),
          content: const Text('You need to be logged in to place an order.', style: TextStyle(color: Colors.white70)),
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

  Future<void> _placeOrderAndNavigate() async {
    if (_selectedSeats.isEmpty) return;

    final token = SessionManager().getToken();
    if (token == null) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final priceMap = {for (var row in widget.section.rows) row.row: row.price};
      int totalPrice = 0;
      for (final seat in _selectedSeats) {
        totalPrice += priceMap[seat.row] ?? 0;
      }

      final seatIds = _selectedSeats.map((seat) => seat.id).toList();

      final createdOrder = await _orderService.createOrder(
        matchId: widget.matchId,
        seatIds: seatIds,
        totalAmount: totalPrice,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeatCheckoutSummaryScreen(
              matchId: widget.matchId,
              selectedSeats: _selectedSeats,
              section: widget.section,
              order: createdOrder,
            ),
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

  Color _getSeatColor(Seat seat) {
    if (_selectedSeats.contains(seat)) {
      return Colors.blue; // Selected by the user
    }
    switch (seat.status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'sold': // Corrected from 'taken'
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _toggleSeatSelection(Seat seat) {
    if (seat.status.toLowerCase() == 'available') {
      setState(() {
        if (_selectedSeats.contains(seat)) {
          _selectedSeats.remove(seat);
        } else {
          _selectedSeats.add(seat);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seats Selection Chart'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Section ${widget.section.section}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(),
            ),
            const SizedBox(height: 20),
            Text(
              '${_selectedSeats.length} Seats Selected',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSeats.isNotEmpty && !_isLoading
                    ? _placeOrderAndNavigate
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey.shade700,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
  
    Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load seats: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_seats == null || _seats!.isEmpty) {
       return const Center(
        child: Text(
          'No seats available in this section.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _seats!.length,
      itemBuilder: (context, index) {
        final seat = _seats![index];
        final seatLabel = '${seat.row}${seat.seatNumber}';

        return GestureDetector(
          onTap: () => _toggleSeatSelection(seat),
          child: Tooltip(
            message: 'Seat $seatLabel',
            child: Container(
              decoration: BoxDecoration(
                color: _getSeatColor(seat),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  seatLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
