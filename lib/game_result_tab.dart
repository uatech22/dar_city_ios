import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/fan_schedule_theme.dart';
import 'package:dar_city_app/models/game_results.dart';
import 'package:dar_city_app/services/game_service.dart';
import 'package:dar_city_app/utils/dar_city_match_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastResultsList extends StatefulWidget {
  const PastResultsList({super.key});

  @override
  State<PastResultsList> createState() => _PastResultsListState();
}

class _PastResultsListState extends State<PastResultsList> {
  List<Result>? _results;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPastResults();
    _timer = Timer.periodic(
      ApiConfig.refreshIntervalSlow,
      (_) => _fetchPastResults(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPastResults() async {
    try {
      final results = await MatchService.fetchFinishedMatches();
      if (mounted) {
        setState(() {
          _results = results;
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

  _DarCityRecord _darCityRecord(List<Result> results) {
    var wins = 0;
    var losses = 0;
    for (final r in results) {
      if (!r.involvesDarCity) continue;
      if (r.darCityWon) {
        wins++;
      } else if (r.darCityLost) {
        losses++;
      }
    }
    return _DarCityRecord(wins: wins, losses: losses);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_results == null || _results!.isEmpty) return _buildEmptyState();

    final layout = DarLayoutMetrics.of(context);
    final results = _results!;
    final record = _darCityRecord(results);

    return RefreshIndicator(
      onRefresh: _fetchPastResults,
      color: DarColors.accentRed,
      backgroundColor: DarColors.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: layout.scrollPadding(top: 8, bottom: 24),
        itemCount: results.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ResultsSummaryBar(
                totalGames: results.length,
                record: record,
              ),
            );
          }
          final result = results[index - 1];
          return _AnimatedResultEntry(
            index: index - 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FanPastResultCard(result: result),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: DarColors.accentRed.withValues(alpha: 0.85),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Icon(
                  Icons.sports_basketball_rounded,
                  color: DarColors.accentRed.withValues(alpha: 0.9),
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading past results…',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DarColors.accentRed.withValues(alpha: 0.12),
                border: Border.all(
                  color: DarColors.accentRed.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: DarColors.accentRed,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load results',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pull to refresh or try again.',
              style: TextStyle(color: DarColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _fetchPastResults,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: DarColors.accentRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: FanEmptyState(
          icon: Icons.sports_score_rounded,
          message:
              'No completed matches yet.\nResults will show here after games finish.',
        ),
      ),
    );
  }
}

class _DarCityRecord {
  const _DarCityRecord({required this.wins, required this.losses});

  final int wins;
  final int losses;

  bool get hasGames => wins + losses > 0;
}

class _ResultsSummaryBar extends StatelessWidget {
  const _ResultsSummaryBar({
    required this.totalGames,
    required this.record,
  });

  final int totalGames;
  final _DarCityRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FanSchedulePalette.purpleMid.withValues(alpha: 0.35),
            DarColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DarColors.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: DarColors.accentRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalGames ${totalGames == 1 ? 'game' : 'games'} played',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (record.hasGames)
                  Text(
                    'Dar City ${record.wins}W · ${record.losses}L',
                    style: TextStyle(
                      color: FanSchedulePalette.gold.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Season results archive',
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedResultEntry extends StatelessWidget {
  const _AnimatedResultEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

class FanPastResultCard extends StatelessWidget {
  const FanPastResultCard({super.key, required this.result});

  final Result result;

  @override
  Widget build(BuildContext context) {
    final leftWon = result.fanLeftScore > result.fanRightScore;
    final rightWon = result.fanRightScore > result.fanLeftScore;
    final isDraw = result.fanLeftScore == result.fanRightScore;
    final darCityGame = result.involvesDarCity;
    final darCityWon = result.darCityWon;

    final accent = darCityGame && darCityWon
        ? FanSchedulePalette.gold
        : darCityGame && result.darCityLost
            ? FanSchedulePalette.loss
            : DarColors.accentRed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarColors.cardDark,
            DarColors.background,
          ],
        ),
        border: Border.all(
          color: darCityGame
              ? accent.withValues(alpha: darCityWon ? 0.45 : 0.25)
              : Colors.white.withValues(alpha: 0.07),
          width: darCityGame ? 1.5 : 1,
        ),
        boxShadow: [
          if (darCityWon)
            BoxShadow(
              color: FanSchedulePalette.gold.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDraw: isDraw),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamResultColumn(
                      name: result.fanLeftShort,
                      logoUrl: result.homeTeamLogo,
                      score: result.fanLeftScore,
                      isWinner: leftWon,
                      isDarCity: result.isDarCityHome,
                      alignEnd: false,
                    ),
                  ),
                  _buildScoreCenter(isDraw: isDraw, accent: accent),
                  Expanded(
                    child: _TeamResultColumn(
                      name: result.fanRightShort,
                      logoUrl: result.awayTeamLogo,
                      score: result.fanRightScore,
                      isWinner: rightWon,
                      isDarCity: isDarCityTeamName(result.teamB),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            if (darCityGame) _buildDarCityFooter(won: darCityWon),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isDraw}) {
    final dateLabel = result.scheduledAt != null
        ? DateFormat('EEE, MMM d · yyyy').format(result.scheduledAt!.toLocal())
        : 'Final';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _chip(
            isDraw ? 'DRAW' : 'FINAL',
            color: isDraw ? DarColors.muted : DarColors.accentRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateLabel,
              style: TextStyle(
                color: DarColors.muted.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (result.competition?.trim().isNotEmpty == true)
            _chip(
              result.competition!.trim(),
              color: FanSchedulePalette.purpleSoft,
              outline: true,
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, {required Color color, bool outline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: outline ? 0.45 : 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: outline ? color : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildScoreCenter({required bool isDraw, required Color accent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              '${result.fanLeftScore} - ${result.fanRightScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 0.5,
              ),
            ),
            if (isDraw)
              Text(
                'TIE',
                style: TextStyle(
                  color: DarColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarCityFooter({required bool won}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: (won ? FanSchedulePalette.gold : FanSchedulePalette.loss)
          .withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            won ? Icons.military_tech_rounded : Icons.sports_basketball_outlined,
            size: 14,
            color: won ? FanSchedulePalette.gold : FanSchedulePalette.loss,
          ),
          const SizedBox(width: 6),
          Text(
            won ? 'Dar City victory' : 'Dar City result',
            style: TextStyle(
              color: won ? FanSchedulePalette.gold : FanSchedulePalette.loss,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamResultColumn extends StatelessWidget {
  const _TeamResultColumn({
    required this.name,
    required this.logoUrl,
    required this.score,
    required this.isWinner,
    required this.isDarCity,
    required this.alignEnd,
  });

  final String name;
  final String logoUrl;
  final int score;
  final bool isWinner;
  final bool isDarCity;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final winColor = isDarCity ? FanSchedulePalette.gold : DarColors.accentRed;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _TeamLogoBadge(url: logoUrl, highlight: isWinner, isDarCity: isDarCity),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
            height: 1.15,
          ),
        ),
        if (isWinner) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: winColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: winColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              'WIN',
              style: TextStyle(
                color: winColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            score.toString(),
            style: TextStyle(
              color: DarColors.muted.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamLogoBadge extends StatelessWidget {
  const _TeamLogoBadge({
    required this.url,
    required this.highlight,
    required this.isDarCity,
  });

  final String url;
  final bool highlight;
  final bool isDarCity;

  @override
  Widget build(BuildContext context) {
    final ring = isDarCity
        ? FanSchedulePalette.gold
        : highlight
            ? DarColors.accentRed
            : Colors.white.withValues(alpha: 0.15);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DarColors.surface,
        border: Border.all(
          color: ring.withValues(alpha: highlight || isDarCity ? 0.65 : 0.2),
          width: highlight || isDarCity ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: ring.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: url.trim().isEmpty
            ? Icon(
                Icons.shield_outlined,
                color: DarColors.muted.withValues(alpha: 0.6),
                size: 24,
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(
                  Icons.sports_basketball,
                  color: DarColors.muted.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
      ),
    );
  }
}

extension _ResultDarCity on Result {
  bool get involvesDarCity =>
      isDarCityTeamName(teamA) || isDarCityTeamName(teamB);

  bool get darCityWon {
    if (isDarCityHome) return scoreA > scoreB;
    if (isDarCityTeamName(teamB)) return scoreB > scoreA;
    return false;
  }

  bool get darCityLost {
    if (isDarCityHome) return scoreA < scoreB;
    if (isDarCityTeamName(teamB)) return scoreB < scoreA;
    return false;
  }
}
