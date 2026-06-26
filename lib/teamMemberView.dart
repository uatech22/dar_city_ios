import 'dart:async';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:flutter/material.dart';
import 'coach_profile.dart';
import 'player_profile.dart';
import 'models/person.dart';
import 'package:dar_city_app/utils/person_display.dart';
import 'services/team_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> with TickerProviderStateMixin {
  late FanMotion _motion;

  @override
  void initState() {
    super.initState();
    _motion = FanMotion(this);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 6, layout.horizontalPadding, 0),
                child: FanHeroCard(
                  motion: _motion,
                  minimal: true,
                  badge: 'OFFICIAL SQUAD',
                  title: 'Dar City Team',
                  trailing: const Icon(
                    Icons.groups_rounded,
                    color: DarColors.accentRed,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 12, layout.horizontalPadding, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const FanSectionHeader(label: 'Players', icon: Icons.sports_basketball_rounded),
                const SizedBox(height: 10),
                const PlayersList(),
                const SizedBox(height: 24),
                const FanSectionHeader(label: 'Coaches & Staff', icon: Icons.military_tech_rounded),
                const SizedBox(height: 10),
                const CoachesList(),
              ]),
            ),
          ),
        ],
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
    _refreshTimer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _fetchPlayers());
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
          return FanEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Could not load players',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: DarColors.accentRed),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const FanEmptyState(
            icon: Icons.person_off_outlined,
            message: 'No players found',
          );
        }

        final players = snapshot.data!;
        return Column(
          children: [
            for (final person in players)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlayerCard(person: person),
              ),
          ],
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
    return FanPremiumTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerProfileScreen(person: person),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _personPhoto(image: person.image, width: 88, height: 96),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                if (person.displayTeamLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DarColors.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      person.displayTeamLabel,
                      style: const TextStyle(
                        color: DarColors.accentRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DarColors.muted.withValues(alpha: 0.7), size: 22),
        ],
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
    _refreshTimer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _fetchCoaches());
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
          return const FanEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Could not load coaches',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: DarColors.accentRed),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const FanEmptyState(
            icon: Icons.person_off_outlined,
            message: 'No coaches found',
          );
        }

        final coaches = snapshot.data!;
        return Column(
          children: [
            for (final coach in coaches)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CoachCard(coach: coach),
              ),
          ],
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
    return FanPremiumTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachProfileScreen(coach: coach),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _personPhoto(image: coach.image, width: 88, height: 96),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                if (coach.displayTeamLabel.isNotEmpty)
                  Text(
                    coach.displayTeamLabel,
                    style: TextStyle(color: DarColors.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DarColors.muted.withValues(alpha: 0.7), size: 22),
        ],
      ),
    );
  }
}

Widget _personPhoto({String? image, double width = 88, double height = 96}) {
  final provider = image != null
      ? NetworkImage(image) as ImageProvider
      : const AssetImage('assets/images/dar-city-logo.png');

  return SizedBox(
    width: width,
    height: height,
    child: Image(
      image: provider,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/dar-city-logo.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    ),
  );
}
