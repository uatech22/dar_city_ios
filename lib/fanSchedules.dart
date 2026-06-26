import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/fan_schedule_calendar.dart';
import 'package:dar_city_app/fan_schedule_theme.dart';
import 'package:dar_city_app/game_result_tab.dart';
import 'package:dar_city_app/fan_standings_coming_soon.dart';
import 'package:dar_city_app/services/game_service.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/utils/dar_city_match_layout.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  int selectedIndex = 0;
  late FanMotion _motion;

  static const _tabs = ['Upcoming', 'Past Results', 'Standings'];

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
        Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 6, layout.horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FanHeroCard(
                    motion: _motion,
                    minimal: true,
                    badge: 'SEASON 2026',
                    title: _getTitle(),
                    trailing: const Icon(
                      Icons.calendar_month_rounded,
                      color: DarColors.accentRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tabs.asMap().entries.map((entry) {
                        return FanFilterChip(
                          label: entry.value,
                          selected: selectedIndex == entry.key,
                          onTap: () => setState(() => selectedIndex = entry.key),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return const UpcomingGamesList();
      case 1:
        return const PastResultsList();
      case 2:
        return const StandingsList();
      default:
        return const SizedBox();
    }
  }

  String _getTitle() {
    switch (selectedIndex) {
      case 0:
        return 'Upcoming Matches';
      case 1:
        return 'Match Results';
      case 2:
        return 'League Standings';
      default:
        return 'Basketball Schedule';
    }
  }
}

/* =========================
   UPCOMING GAMES
========================= */

class UpcomingGamesList extends StatefulWidget {
  const UpcomingGamesList({super.key});

  @override
  State<UpcomingGamesList> createState() => _UpcomingGamesListState();
}

class _UpcomingGamesListState extends State<UpcomingGamesList> {
  List<Game>? _games;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingGames();
    _timer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _fetchUpcomingGames());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUpcomingGames() async {
    try {
      final games = await MatchService.fetchScheduleCalendar();
      if (mounted) {
        setState(() {
          _games = games;
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
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    final games = _games;

    final calendarHeight = FanScheduleMetrics.calendarHostHeight(
      context,
      topChrome: 120,
    );

    if (games == null || games.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchUpcomingGames,
        color: FanSchedulePalette.accentRed,
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: SizedBox(
                height: calendarHeight,
                child: const FanMatchCalendar(games: []),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUpcomingGames,
      color: FanSchedulePalette.purpleMid,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: SizedBox(
              height: calendarHeight,
              child: FanMatchCalendar(games: games),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading Matches...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching latest game schedules',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Could not fetch match data. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchUpcomingGames,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Colors.grey,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  String _formatDateTime() {
    try {
      final dateTime = DateTime.parse(game.date);
      final formattedDate = DateFormat('EEE, MMM d').format(dateTime);
      return '$formattedDate • ${game.time}';
    } catch (e) {
      return '${game.date} • ${game.time}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle game tap
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.red.withOpacity(0.1),
          highlightColor: Colors.red.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Match Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateTime(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Teams
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Team
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade900,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                            child: Image.network(
                              game.fanLeftLogo,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports_basketball, color: Colors.grey),
                            )
                          ),
                          const SizedBox(height: 12),
                          Text(
                            game.fanLeftShort,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // VS Circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    // Away Team
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade900,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                            child: Image.network(
                              game.fanRightLogo,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.sports_basketball, color: Colors.grey),
                            )

                          ),
                          const SizedBox(height: 12),
                          Text(
                            game.fanRightShort,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Venue
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          game.venue,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 12,
                      //     vertical: 6,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: Colors.red,
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //
                      //   child: const Text(
                      //     'BUY TICKETS',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 11,
                      //       fontWeight: FontWeight.w700,
                      //       letterSpacing: 0.5,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/* =========================
   STANDINGS
========================= */

class StandingsList extends StatelessWidget {
  const StandingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return const FanStandingsComingSoon();
  }
}

class StandingRow extends StatelessWidget {
  final int rank;
  final String team;
  final int wins, losses;
  final bool isHighlighted;

  const StandingRow({
    super.key,
    required this.rank,
    required this.team,
    required this.wins,
    required this.losses,
    this.isHighlighted = false,
  });

  int get points => wins * 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.red.withOpacity(0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? Colors.red.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle team tap
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.red : const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Team
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade900,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.sports_basketball_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        team,
                        style: TextStyle(
                          color: isHighlighted ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Wins
                Expanded(
                  child: Center(
                    child: Text(
                      '$wins',
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Losses
                Expanded(
                  child: Center(
                    child: Text(
                      '$losses',
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Points
                Expanded(
                  child: Center(
                    child: Text(
                      '$points',
                      style: TextStyle(
                        color: isHighlighted ? Colors.red : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}