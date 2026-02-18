import 'package:flutter/material.dart';
import '../models/person.dart';

class CoachProfileScreen extends StatelessWidget {
  final Person coach;

  const CoachProfileScreen({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Coach Profile'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== HEADER =====
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: coach.image != null
                      ? NetworkImage(coach.image!)
                      : const AssetImage('assets/images/dar-city-logo.png')
                  as ImageProvider,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coach.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// ROLE BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          coach.position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// ===== DETAILS =====
            _infoRow('Nationality', coach.nationality ?? 'N/A'),
            _infoRow(
              'Date of Birth',
              coach.dob != null
                  ? coach.dob!.toString().split(' ')[0]
                  : 'N/A',
            ),

            const SizedBox(height: 24),

            /// ===== BIO =====
            const Text(
              'Biography',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coach.bio ?? 'No biography available.',
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== INFO ROW =====
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
