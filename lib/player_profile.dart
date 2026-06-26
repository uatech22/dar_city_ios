import 'package:flutter/material.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/utils/person_display.dart';
import 'models/person.dart';

class PlayerProfileScreen extends StatelessWidget {
  final Person person;

  const PlayerProfileScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Player Profile'),
        backgroundColor: Colors.black,
      ),
      body: darResponsiveBody(
        SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeroImage(imageUrl: person.image),
            Padding(
              padding: EdgeInsets.all(DarLayoutMetrics.of(context).horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    person.displayTeamLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  if (person.jerseyNumber != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Jersey #${person.jerseyNumber}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _sectionTitle('Player Information'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      InfoItem(label: 'Nationality', value: person.nationality),
                      InfoItem(
                        label: 'Height',
                        value: person.height != null ? '${person.height} cm' : null,
                      ),
                      InfoItem(
                        label: 'Weight',
                        value: person.weight != null ? '${person.weight} kg' : null,
                      ),
                      InfoItem(
                        label: 'Date of Birth',
                        value: person.formattedDateOfBirth,
                      ),
                      if (person.showRoleInfoItem)
                        InfoItem(
                          label: 'Role',
                          value: person.displayRoleLabel,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle('Career Stats'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Points', value: person.points ?? 0),
                      _StatItem(label: 'Rebounds', value: person.rebounds ?? 0),
                      _StatItem(label: 'Assists', value: person.assists ?? 0),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle('Biography'),
                  const SizedBox(height: 8),
                  Text(
                    person.bio ??
                        'This player is a key member of Dar City Basketball Club, known for dedication and strong performance on the court.',
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class ProfileHeroImage extends StatelessWidget {
  const ProfileHeroImage({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return SizedBox(
      width: width,
      height: width * 1.0,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('IMAGE LOAD ERROR: $error');
                return Image.asset(
                  'assets/images/dar-city-logo.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                );
              },
            )
          : Image.asset(
              'assets/images/dar-city-logo.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
    );
  }
}

/// ===== INFO ITEM =====
class InfoItem extends StatelessWidget {
  final String label;
  final String? value;

  const InfoItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== STAT ITEM =====
class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
