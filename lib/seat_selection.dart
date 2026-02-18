import 'dart:async';
import 'package:dar_city_app/models/seat_section.dart';
import 'package:dar_city_app/services/ticket_seat_service.dart';
import 'package:flutter/material.dart';
import 'seat_selection_chat_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int matchId;
  const SeatSelectionScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Timer? _timer;
  List<SeatSection>? _sections;
  bool _isLoading = true;
  String? _error;
  SeatSection? _selectedSection;

  @override
  void initState() {
    super.initState();
    _fetchSections();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchSections(showLoading: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSections({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final sections = await TicketSeat().fetchSections(widget.matchId);
      if (mounted) {
        setState(() {
          _sections = sections;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Seat Selection'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/pitch_seat.jpg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose your section',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(),
            ),
            if (_selectedSection != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeatsSelectionChartScreen(
                          matchId: widget.matchId,
                          section: _selectedSection!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Select Seats',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
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
          'Failed to load seat sections: \n$_error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_sections == null || _sections!.isEmpty) {
      return const Center(
        child: Text(
          'No seat sections available for this match.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _sections!.length,
      itemBuilder: (context, index) {
        final section = _sections![index];
        return _buildSeatOption(section);
      },
    );
  }

  Widget _buildSeatOption(SeatSection section) {
    final bool isSelected = _selectedSection?.section == section.section;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSection = section;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.section,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24, height: 24),
            ...section.rows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Row ${row.row}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'TZS ${row.price}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${row.availableSeats} seats left',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
