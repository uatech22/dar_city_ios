import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== PROFILE HEADER =====
            Row(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade900,
                  child: ClipOval(
                    child: Image.network(
                      person.image ?? '',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('IMAGE LOAD ERROR: $error');
                        return Image.asset(
                          'assets/images/dar-city-logo.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        person.position,
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// ===== PLAYER INFO =====
            _sectionTitle('Player Information'),
            const SizedBox(height: 16),

            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                InfoItem(label: 'Nationality', value: person.nationality),
                InfoItem(label: 'Height', value: person.height != null ? '${person.height} cm' : null),
                InfoItem(label: 'Weight', value: person.weight != null ? '${person.weight} kg' : null),
                InfoItem(
                  label: 'Date of Birth',
                  value: person.dob != null
                      ? '${person.dob!.day}-${person.dob!.month}-${person.dob!.year}'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// ===== CAREER STATS =====
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

            /// ===== BIOGRAPHY =====
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
