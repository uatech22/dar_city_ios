import 'dart:async';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/fan_schedule_calendar.dart';
import 'package:dar_city_app/fan_schedule_theme.dart';
import 'package:dar_city_app/utils/dar_city_match_layout.dart';
import 'package:dar_city_app/utils/team_name_short.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/live_matches.dart';
import 'package:dar_city_app/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:dar_city_app/news_tab.dart';
import 'game_result_tab.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedTab = 0;
  late FanMotion _motion;

  static const _tabs = ['Post', 'Live', 'Upcoming', 'Past'];

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

  String get _heroTitle {
    switch (selectedTab) {
      case 1:
        return 'Live scores';
      case 2:
        return 'Upcoming fixtures';
      case 3:
        return 'Past results';
      default:
        return 'News & updates';
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dar City Basketball',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: darResponsiveBody(
        Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 6, layout.horizontalPadding, 0),
            child: FanHeroCard(
              motion: _motion,
              minimal: true,
              badge: 'FAN ZONE',
              title: _heroTitle,
            ),
          ),
          const SizedBox(height: 8),
          _buildTopNavigation(),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: DarLayoutMetrics.of(context).horizontalPadding),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          return FanFilterChip(
            label: entry.value,
            selected: selectedTab == entry.key,
            onTap: () => setState(() => selectedTab = entry.key),
          );
        }).toList(),
      ),
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
// ================= UPCOMING CALENDAR =================
class UpcomingGameWidget extends StatefulWidget {
  const UpcomingGameWidget({super.key});

  @override
  State<UpcomingGameWidget> createState() => _UpcomingGameWidgetState();
}

class _UpcomingGameWidgetState extends State<UpcomingGameWidget> {
  List<Game>? _games;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _timer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _loadGames());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGames() async {
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF552583)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load schedule',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadGames,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final games = _games ?? [];
    final calendarHeight = FanScheduleMetrics.calendarHostHeight(
      context,
      topChrome: 180,
    );

    if (games.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGames,
        color: FanSchedulePalette.accentRed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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
      onRefresh: _loadGames,
      color: FanSchedulePalette.purpleMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: SizedBox(
              height: calendarHeight,
              child: FanMatchCalendar(games: games),
            ),
          ),
        ],
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
      ApiConfig.refreshIntervalFast,
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

  bool _isCompactLayout(BoxConstraints constraints) {
    final landscape =
        constraints.maxWidth > constraints.maxHeight && constraints.maxHeight > 0;
    return landscape || constraints.maxHeight < 460;
  }

  Widget _wrapScrollable(BuildContext context, Widget child, BoxConstraints constraints) {
    final layout = DarLayoutMetrics.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: layout.bottomNavClearance),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    );
  }

  Widget _buildLoadingState({required bool compact}) {
    final iconSize = compact ? 72.0 : 120.0;
    final ballSize = compact ? 32.0 : 50.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: iconSize,
              height: iconSize,
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
              child: Center(
                child: Icon(
                  Icons.sports_basketball_rounded,
                  color: Colors.white,
                  size: ballSize,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 32),
          Text(
            'Loading live match...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              'Checking for live basketball action',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool compact}) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(compact ? 12 : 20),
        padding: EdgeInsets.all(compact ? 20 : 32),
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
            Text(
              'No Live Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(
              compact
                  ? 'No live matches right now.'
                  : 'There are no live basketball matches\nat the moment. Check back soon!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 14 : 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? 16 : 32),
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

  Widget _buildMatchCard(LiveMatch match, {required bool compact}) {
    final outerPad = compact ? 10.0 : 16.0;
    final innerPad = compact ? 12.0 : 20.0;
    final logoSize = compact ? 48.0 : 70.0;
    final scoreFont = compact ? 28.0 : 36.0;
    final teamFont = compact ? 14.0 : 18.0;
    final vsSize = compact ? 40.0 : 50.0;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: EdgeInsets.all(outerPad),
        padding: EdgeInsets.all(innerPad),
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
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: compact ? 6 : 10,
              ),
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
                    Text(
                      'LIVE NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        shadows: const [
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

            SizedBox(height: compact ? 12 : 24),

            // TEAMS IN HORIZONTAL LAYOUT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTeamSection(
                    teamName: shortTeamName(match.fanLeftName),
                    score: match.fanLeftScore,
                    isHomeTeam: true,
                    logoUrl: match.fanLeftLogo,
                    compact: compact,
                    logoSize: logoSize,
                    scoreFont: scoreFont,
                    teamFont: teamFont,
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: vsSize,
                        height: vsSize,
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
                        child: Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: compact ? 13 : 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: compact ? 6 : 8,
                        ),
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
                              size: compact ? 14 : 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Q${match.quarter}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 13 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _buildTeamSection(
                    teamName: shortTeamName(match.fanRightName),
                    score: match.fanRightScore,
                    isHomeTeam: false,
                    logoUrl: match.fanRightLogo,
                    compact: compact,
                    logoSize: logoSize,
                    scoreFont: scoreFont,
                    teamFont: teamFont,
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 10 : 20),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 12,
              ),
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
    required bool compact,
    required double logoSize,
    required double scoreFont,
    required double teamFont,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
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
              width: logoSize * 0.72,
              height: logoSize * 0.72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.sports_basketball, color: Colors.grey),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 12),

        Text(
          teamName,
          style: TextStyle(
            color: Colors.white,
            fontSize: teamFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: compact ? 6 : 12),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 8 : 12,
          ),
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
                fontSize: scoreFont,
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
        if (!compact) ...[
          const SizedBox(height: 8),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = _isCompactLayout(constraints);
        Widget content;
        if (_isLoading) {
          content = _buildLoadingState(compact: compact);
        } else if (_liveMatch == null) {
          content = _buildEmptyState(compact: compact);
        } else {
          content = _buildMatchCard(_liveMatch!, compact: compact);
        }
        return _wrapScrollable(context, content, constraints);
      },
    );
  }
}






