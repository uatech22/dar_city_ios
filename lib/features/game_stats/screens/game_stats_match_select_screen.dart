import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/game_stats/models/game_stats_session.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_live_console_screen.dart';
import 'package:dar_city_app/features/game_stats/screens/game_stats_match_lineup_screen.dart';
import 'package:dar_city_app/features/game_stats/services/game_stats_service.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/utils/match_logo.dart';
import 'package:dar_city_app/utils/team_name_short.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Step 1 — featured match + paginated picker (5 fixtures per slide).
class GameStatsMatchSelectScreen extends StatefulWidget {
  const GameStatsMatchSelectScreen({super.key});

  @override
  State<GameStatsMatchSelectScreen> createState() =>
      _GameStatsMatchSelectScreenState();
}

class _GameStatsMatchSelectScreenState extends State<GameStatsMatchSelectScreen>
    with AutoRefreshStateMixin {
  late Future<List<Game>> _matchesFuture;
  Game? _selectedMatch;
  bool _pickerOpen = false;
  late PageController _pageController;
  int _currentPage = 0;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = GameStatsService.fetchSelectableMatches();
    setState(() => _matchesFuture = future);
    final matches = await future;
    if (!mounted) return;

    setState(() {
      _selectedMatch = GameStatsService.resolveSelected(
        matches,
        current: _selectedMatch,
      );
      _syncPickerPage(matches);
    });
  }

  void _syncPickerPage(List<Game> matches, [Game? selected]) {
    final pick = selected ?? _selectedMatch;
    final page = GameStatsService.pageIndexForMatch(matches, pick);
    _currentPage = page;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page);
    }
  }

  void _openPicker(List<Game> matches) {
    final selected = GameStatsService.resolveSelected(matches, current: _selectedMatch);
    setState(() {
      _selectedMatch = selected;
      _pickerOpen = true;
      _syncPickerPage(matches, selected);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _selectMatch(Game game, List<Game> matches) {
    setState(() => _selectedMatch = game);
    _syncPickerPage(matches);
  }

  Future<void> _continue(Game match) async {
    setState(() => _resuming = true);
    try {
      final active = await GameStatsService.fetchActiveSession(match.id);
      if (!mounted) return;
      if (active != null) {
        final apiSession = await GameStatsService.fetchSession(active.sessionId);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameStatsLiveConsoleScreen(
              session: GameStatsSession.fromApi(apiSession),
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // Fall through to new-session lineup flow.
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameStatsMatchLineupScreen(match: match),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);
    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        Stack(
        children: [
          FeatureAsyncBody<List<Game>>(
        future: _matchesFuture,
        onRetry: _load,
        builder: (context, matches) {
          if (matches.isEmpty) {
            return const _EmptyMatches();
          }

          final selected = GameStatsService.resolveSelected(
            matches,
            current: _selectedMatch,
          );
          if (_selectedMatch == null ||
              !GameStatsService.isSameMatch(_selectedMatch!, selected)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedMatch = selected);
            });
          }

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 148,
                      pinned: true,
                      backgroundColor: Colors.black,
                      iconTheme: const IconThemeData(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DarColors.accentRed.withValues(alpha: 0.45),
                                Colors.black,
                                DarColors.background,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(56, 8, layout.horizontalPadding, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COACH HUB',
                                    style: TextStyle(
                                      color: DarColors.accentRed.withValues(alpha: 0.95),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Game Stats',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Nearest upcoming fixture is pre-selected — change it anytime',
                                    style: TextStyle(color: DarColors.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(layout.horizontalPadding, 12, layout.horizontalPadding, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FeaturedMatchCard(
                              game: selected,
                              isToday: GameStatsService.isToday(selected),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (_pickerOpen) {
                                  setState(() => _pickerOpen = false);
                                } else {
                                  _openPicker(matches);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: _pickerOpen
                                      ? DarColors.accentRed
                                      : DarColors.muted.withValues(alpha: 0.35),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                _pickerOpen
                                    ? Icons.expand_less_rounded
                                    : Icons.swap_horiz_rounded,
                                color: DarColors.accentRed,
                              ),
                              label: Text(
                                _pickerOpen ? 'Hide match list' : 'Change / select match',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 260),
                              crossFadeState: _pickerOpen
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _MatchPickerCarousel(
                                  matches: matches,
                                  selected: selected,
                                  pageController: _pageController,
                                  currentPage: _currentPage,
                                  onPageChanged: (page) => setState(() => _currentPage = page),
                                  onSelect: (game) => _selectMatch(game, matches),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _BottomBar(
                label:
                    '${shortTeamName(selected.homeTeam)} vs ${shortTeamName(selected.awayTeam)}',
                onContinue: () => _continue(selected),
              ),
            ],
          );
        },
      ),
          if (_resuming)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _FeaturedMatchCard extends StatelessWidget {
  const _FeaturedMatchCard({required this.game, required this.isToday});

  final Game game;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheduled = game.scheduledAt?.toLocal();
    final dateLabel = scheduled != null
        ? DateFormat('EEEE, MMM d · HH:mm').format(scheduled)
        : '${game.date} · ${game.time}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.accentRed.withValues(alpha: 0.28),
            DarColors.cardDark,
            DarColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DarColors.accentRed.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'SELECTED MATCH',
                  style: TextStyle(
                    color: DarColors.accentRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DarColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DarColors.green.withValues(alpha: 0.45)),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: DarColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TeamBlock(
                  name: game.homeTeam,
                  short: game.homeTeamShort,
                  logoUrl: game.homeTeamLogo,
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      game.hasResult ? '${game.homeScore} - ${game.awayScore}' : 'VS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday ? 'Game day' : 'Upcoming',
                      style: TextStyle(color: DarColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _TeamBlock(
                  name: game.awayTeam,
                  short: game.awayTeamShort,
                  logoUrl: game.awayTeamLogo,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: DarColors.muted.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: DarColors.muted.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(dateLabel, style: const TextStyle(color: DarColors.muted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: DarColors.muted.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  game.venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DarColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchPickerCarousel extends StatelessWidget {
  const _MatchPickerCarousel({
    required this.matches,
    required this.selected,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSelect,
  });

  final List<Game> matches;
  final Game selected;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Game> onSelect;

  @override
  Widget build(BuildContext context) {
    final pages = GameStatsService.chunkMatches(matches);
    final pageCount = pages.length;
    final maxOnPage = pages.map((p) => p.length).fold(1, (a, b) => a > b ? a : b);
    final carouselHeight = maxOnPage * 74.0 + (maxOnPage - 1) * 8.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Upcoming fixtures',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Nearest first · ${matches.length} total',
                style: TextStyle(color: DarColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: carouselHeight,
            child: PageView.builder(
              controller: pageController,
              itemCount: pageCount,
              onPageChanged: onPageChanged,
              itemBuilder: (context, pageIndex) {
                final pageMatches = pages[pageIndex];
                return Column(
                  children: [
                    for (var i = 0; i < pageMatches.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _CompactMatchTile(
                        game: pageMatches[i],
                        rank: pageIndex * GameStatsService.matchesPerPickerPage + i + 1,
                        selected: GameStatsService.isSameMatch(pageMatches[i], selected),
                        isToday: GameStatsService.isToday(pageMatches[i]),
                        onTap: () => onSelect(pageMatches[i]),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 0
                      ? () => pageController.previousPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          )
                      : null,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: currentPage > 0 ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  'Slide ${currentPage + 1} of $pageCount',
                  style: const TextStyle(color: DarColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: currentPage < pageCount - 1
                      ? () => pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          )
                      : null,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: currentPage < pageCount - 1
                        ? DarColors.accentRed
                        : DarColors.muted.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                final active = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactMatchTile extends StatelessWidget {
  const _CompactMatchTile({
    required this.game,
    required this.rank,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final Game game;
  final int rank;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheduled = game.scheduledAt?.toLocal();
    final when = scheduled != null
        ? DateFormat('EEE d MMM · HH:mm').format(scheduled)
        : '${game.date} · ${game.time}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? DarColors.accentRed.withValues(alpha: 0.1) : DarColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.14),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: DarColors.accentRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Logo(url: game.homeTeamLogo, fallback: game.homeTeamShort, size: 34),
              const SizedBox(width: 6),
              const Text('vs', style: TextStyle(color: DarColors.muted, fontSize: 11)),
              const SizedBox(width: 6),
              _Logo(url: game.awayTeamLogo, fallback: game.awayTeamShort, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shortTeamName(game.homeTeam)} vs ${shortTeamName(game.awayTeam)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : DarColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: DarColors.muted.withValues(alpha: 0.85), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: DarColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(color: DarColors.green, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({
    required this.name,
    required this.short,
    required this.logoUrl,
    required this.alignEnd,
  });

  final String name;
  final String short;
  final String logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _Logo(url: logoUrl, fallback: short, size: 52),
        const SizedBox(height: 8),
        Text(
          shortTeamName(name),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(color: DarColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url, required this.fallback, this.size = 44});

  final String url;
  final String fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = normalizeLogoUrl(url);
    if (resolved.isEmpty) return _fallbackBadge();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackBadge(),
      ),
    );
  }

  Widget _fallbackBadge() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.2)),
      ),
      child: Text(
        fallback.length >= 2 ? fallback.substring(0, 2).toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.black,
          title: const Text('Game Stats'),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: DarColors.muted.withValues(alpha: 0.6)),
                  const SizedBox(height: 14),
                  const Text(
                    'No upcoming matches',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Past fixtures are hidden. New games will appear here once scheduled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.onContinue,
  });

  final String label;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final h = DarLayoutMetrics.of(context).horizontalPadding;
    return Container(
      padding: EdgeInsets.fromLTRB(h, 12, h, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: DarColors.navBar,
        border: Border(top: BorderSide(color: DarColors.muted.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selected', style: TextStyle(color: DarColors.muted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: DarColors.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
