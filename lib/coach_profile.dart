import 'package:flutter/material.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';

import 'player_profile.dart';
import '../models/person.dart';
import 'package:dar_city_app/utils/person_display.dart';

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
      body: darResponsiveBody(
        SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeroImage(imageUrl: coach.image),
            Padding(
              padding: EdgeInsets.all(DarLayoutMetrics.of(context).horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (coach.displayTeamLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        coach.displayTeamLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  _infoRow('Nationality', coach.nationality ?? 'N/A'),
                  if (coach.showRoleInfoItem && coach.position.trim().isNotEmpty)
                    _infoRow('Position', coach.position),
                  _infoRow(
                    'Date of Birth',
                    coach.formattedDateOfBirth ?? 'N/A',
                  ),
                  const SizedBox(height: 24),
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
          ],
        ),
      ),
      ),
    );
  }

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
