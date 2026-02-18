import 'dart:async';
import 'package:flutter/material.dart';
import 'coach_profile.dart';
import 'player_profile.dart';
import 'models/person.dart';
import 'services/team_service.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Dar City Team'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TEAM HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/dar-city-logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dar City Basketball Club',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Official Team Squad',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ===== PLAYERS =====
            _sectionTitle('Players'),
            const PlayersList(),

            const SizedBox(height: 32),

            /// ===== COACHES =====
            _sectionTitle('Coaches & Staff'),
            const CoachesList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PlayersList extends StatefulWidget {
  const PlayersList({super.key});

  @override
  State<PlayersList> createState() => _PlayersListState();
}

class _PlayersListState extends State<PlayersList> {
  late Future<List<Person>> _playersFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchPlayers());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _fetchPlayers() {
    if (mounted) {
      setState(() {
        _playersFuture = TeamService.fetchPlayers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: _playersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading players: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No players found', style: TextStyle(color: Colors.white70)),
          );
        }

        final players = snapshot.data!;
        return ListView.builder(
          itemCount: players.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) {
            return PlayerCard(person: players[index]);
          },
        );
      },
    );
  }
}

class PlayerCard extends StatelessWidget {
  final Person person;

  const PlayerCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(person: person),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: person.image != null
                  ? NetworkImage(person.image!)
                  : const AssetImage('assets/images/dar-city-logo.png') as ImageProvider,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      person.position,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class CoachesList extends StatefulWidget {
  const CoachesList({super.key});

  @override
  State<CoachesList> createState() => _CoachesListState();
}

class _CoachesListState extends State<CoachesList> {
  late Future<List<Person>> _coachesFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchCoaches());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _fetchCoaches() {
    if (mounted) {
      setState(() {
        _coachesFuture = TeamService.fetchCoaches();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: _coachesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading coaches: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No coaches found', style: TextStyle(color: Colors.white70)),
          );
        }

        final coaches = snapshot.data!;
        return ListView.builder(
          itemCount: coaches.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return CoachCard(coach: coaches[index]);
          },
        );
      },
    );
  }
}

class CoachCard extends StatelessWidget {
  final Person coach;

  const CoachCard({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachProfileScreen(coach: coach),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: coach.image != null
                  ? NetworkImage(coach.image!)
                  : const AssetImage('assets/images/dar-city-logo.png') as ImageProvider,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coach.position,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
