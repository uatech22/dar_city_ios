import 'dart:async';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/live_matches.dart';
import 'package:dar_city_app/seat_selection.dart';
import 'package:dar_city_app/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:dar_city_app/news_tab.dart';
import 'game_result_tab.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0; // 0=Home,1=Live,2=Upcoming,3=Past

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Dar City Basketball'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildTopNavigation(),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ================= TOP NAV =================
  Widget _buildTopNavigation() {
    List<String> tabs = ['Post', 'Live', 'Upcoming', 'Past'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tabs.asMap().entries.map((entry) {
        int index = entry.key;
        bool active = selectedTab == index;

        return GestureDetector(
          onTap: () => setState(() => selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: active ? Colors.redAccent : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= MAIN CONTENT SWITCH =================
  Widget _buildContent() {
    switch (selectedTab) {
      case 0:
        return const NewsTab();
      case 1:
        return const LiveMatchWidget();
      case 2:
        return const UpcomingGameWidget();
      case 3:
        return const PastResultsList();
      default:
        return const NewsTab();
    }
  }

  }
// ================= ISOLATED UPCOMING GAME WIDGET =================
class UpcomingGameWidget extends StatefulWidget {
  const UpcomingGameWidget({super.key});

  @override
  State<UpcomingGameWidget> createState() => _UpcomingGameWidgetState();
}

class _UpcomingGameWidgetState extends State<UpcomingGameWidget> {
  Game? _game;
  Timer? _timer;
  String? _error;
  Duration _timeLeft = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  void _loadGame() async {
    try {
      final fetchedGame = await MatchService.fetchNextGame();
      if (mounted && fetchedGame != null) {
        setState(() {
          _game = fetchedGame;
          _isLoading = false;
          _error = null;
        });

        if (fetchedGame.scheduledAt != null) {
          _startCountdown(fetchedGame.scheduledAt!);
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _game = null;
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

  Widget _teamName(String name) {
    return Expanded(
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }


  Widget _timerBox(int value, String label) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1F1F), Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _startCountdown(DateTime scheduledTime) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final difference = scheduledTime.isAfter(now) ? scheduledTime.difference(now) : Duration.zero;

      if (mounted) {
        setState(() {
          _timeLeft = difference;
        });
      }

      if (difference.isNegative || difference.inSeconds == 0) {
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
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load upcoming game:\n\n$_error',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_game == null) {
      return const Center(
        child: Text(
          'No upcoming games',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF1A1A1A),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              //  UPCOMING BADGE
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'UPCOMING GAME',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //  TEAMS
              Row(
                children: [
                  _teamName(_game!.homeTeam),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _teamName(_game!.awayTeam),
                ],
              ),

              const SizedBox(height: 20),

              //  MATCH INFO
              _infoRow(Icons.calendar_today, _game!.date),
              const SizedBox(height: 8),
              _infoRow(Icons.schedule, _game!.time),
              const SizedBox(height: 8),
              _infoRow(Icons.location_on, _game!.venue),

              const SizedBox(height: 28),

              // ⏱ COUNTDOWN TITLE
              const Text(
                'Kick-off In',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),

              // ⏱ COUNTDOWN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _timerBox(days, 'Days'),
                  _timerBox(hours, 'Hrs'),
                  _timerBox(minutes, 'Min'),
                  _timerBox(seconds, 'Sec'),
                ],
              ),

              const SizedBox(height: 32),

              //  BUY TICKET
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SeatSelectionScreen(matchId: _game!.id),
                      ),
                    );
                  },
                  child: const Text(
                    'Buy Ticket',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}



// ================= ISOLATED LIVE MATCH WIDGET =================


class LiveMatchWidget extends StatefulWidget {
  const LiveMatchWidget({super.key});

  @override
  State<LiveMatchWidget> createState() => _LiveMatchWidgetState();
}

class _LiveMatchWidgetState extends State<LiveMatchWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  LiveMatch? _liveMatch;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveMatch();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _fetchLiveMatch(),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveMatch() async {
    try {
      final match = await MatchService.fetchLiveMatch();
      if (mounted) {
        setState(() {
          _liveMatch = match;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liveMatch = null;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.9),
                    Colors.redAccent.withOpacity(0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_basketball_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading live match...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Checking for live basketball action',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF151515),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.sports_basketball_rounded,
                color: Colors.redAccent.withOpacity(0.7),
                size: 50,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Live Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'There are no live basketball matches\nat the moment. Check back soon!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _fetchLiveMatch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(LiveMatch match) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF121212),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LIVE HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent,
                    Colors.redAccent.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _blinkAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'LIVE NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // TEAMS IN HORIZONTAL LAYOUT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // HOME TEAM
                Expanded(
                  child: _buildTeamSection(
                    teamName: match.homeTeam,
                    score: match.homeScore,
                    isHomeTeam: true,
                      logoUrl: match.homeTeamLogo
                  ),
                ),

                // VS SEPARATOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // QUARTER INFO
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Q${match.quarter}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // AWAY TEAM
                Expanded(
                  child: _buildTeamSection(
                    teamName: match.awayTeam,
                    score: match.awayScore,
                    isHomeTeam: false,
                    logoUrl: match.awayTeamLogo
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // MATCH STATUS BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // LEAD DIFFERENCE
                  _buildStatusItem(
                    icon: Icons.leaderboard_rounded,
                    title: 'Lead',
                    value: '${(match.homeScore - match.awayScore).abs()} pts',
                    color: match.homeScore > match.awayScore
                        ? Colors.redAccent
                        : Colors.blueAccent,
                  ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    required int score,
    required bool isHomeTeam,
    required String logoUrl,



  })
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TEAM LOGO/ICON
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHomeTeam
                  ? [
                Colors.redAccent.withOpacity(0.2),
                Colors.transparent,
              ]
                  : [
                Colors.blueAccent.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Center(
            child: Image.network(
              logoUrl,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.sports_basketball, color: Colors.grey),
            )


          ),

        ),
        const SizedBox(height: 12),

        // TEAM NAME
        Text(
          teamName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // SCORE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
            child: Text(
              score.toString(),
              key: ValueKey(score),
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
                shadows: [
                  Shadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // TEAM STATUS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHomeTeam
                ? Colors.redAccent.withOpacity(0.1)
                : Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHomeTeam
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.blueAccent.withOpacity(0.3),
            ),
          ),
          child: Text(
            isHomeTeam ? 'HOME' : 'AWAY',
            style: TextStyle(
              color: isHomeTeam ? Colors.redAccent : Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_liveMatch == null) {
      return _buildEmptyState();
    }

    return _buildMatchCard(_liveMatch!);
  }
}






