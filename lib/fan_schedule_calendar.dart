import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/fan_schedule_theme.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/utils/dar_city_match_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dar City fan schedule calendar — upcoming + past matches.
class FanMatchCalendar extends StatefulWidget {
  const FanMatchCalendar({
    super.key,
    required this.games,
  });

  final List<Game> games;

  @override
  State<FanMatchCalendar> createState() => _FanMatchCalendarState();
}

class _FanMatchCalendarState extends State<FanMatchCalendar> {
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  late DateTime _displayMonth;
  DateTime? _selectedDay;
  Game? _selectedGame;

  Map<DateTime, List<Game>> get _gamesByDay {
    final map = <DateTime, List<Game>>{};
    for (final game in widget.games) {
      final day = game.calendarDate;
      if (day == null) continue;
      map.putIfAbsent(day, () => []).add(game);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final ad = a.scheduledAt ?? DateTime(2100);
        final bd = b.scheduledAt ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _displayMonth = _initialMonth();
    _initSelection();
  }

  @override
  void didUpdateWidget(FanMatchCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.games != widget.games) {
      setState(_initSelection);
    }
  }

  void _initSelection() {
    if (widget.games.isEmpty) {
      _selectedDay = null;
      _selectedGame = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = _gamesByDay;

    Game? pick;
    DateTime? pickDay;

    if (byDay.containsKey(today)) {
      pickDay = today;
      pick = byDay[today]!.first;
    } else {
      for (final game in widget.games) {
        final day = game.calendarDate;
        if (day == null) continue;
        if (!day.isBefore(today)) {
          pick = game;
          pickDay = day;
          break;
        }
      }
      pick ??= widget.games.first;
      pickDay ??= pick.calendarDate;
    }

    _selectedGame = pick;
    _selectedDay = pickDay;
    if (pickDay != null) {
      _displayMonth = DateTime(pickDay.year, pickDay.month);
    }
  }

  DateTime _initialMonth() {
    final now = DateTime.now();
    if (widget.games.isEmpty) return DateTime(now.year, now.month);

    final sorted = [...widget.games]
      ..sort((a, b) {
        final ad = a.scheduledAt ?? DateTime(2100);
        final bd = b.scheduledAt ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    final first = sorted.first.calendarDate ?? now;
    return DateTime(first.year, first.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta);
    });
  }

  void _onDayTap(DateTime day, List<Game> dayGames) {
    setState(() {
      _selectedDay = day;
      _selectedGame = dayGames.isNotEmpty ? dayGames.first : null;
    });
  }

  List<DateTime?> _buildMonthCells() {
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(first.year, first.month);
    final leading = first.weekday - 1;
    final cells = <DateTime?>[];

    for (var i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(first.year, first.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final m = FanScheduleMetrics.of(context);
    final locale = Localizations.localeOf(context).toString();
    final cells = _buildMonthCells();
    final byDay = _gamesByDay;
    final monthLabel =
        DateFormat.yMMMM(locale).format(_displayMonth).toUpperCase();
    final rowCount = cells.length ~/ 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : FanScheduleMetrics.calendarHostHeight(context, topChrome: 220);
        final gridHeight = m.gridHeightFor(height, rowCount);
        final rowHeight = gridHeight / rowCount;

        final calendarBody = Column(
          children: [
            _calendarHeader(monthLabel, m),
            _weekdayRow(m),
            SizedBox(
              height: gridHeight,
              child: ColoredBox(
                color: FanSchedulePalette.bgCell,
                child: Column(
                  children: List.generate(rowCount, (row) {
                    return Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(7, (col) {
                          final index = row * 7 + col;
                          return Expanded(
                            child: _dayCell(
                              cells[index],
                              byDay,
                              m,
                              rowHeight,
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _detailCard(_selectedGame, m, locale),
              ),
            ),
          ],
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: m.maxContentWidth,
              minHeight: height,
            ),
            child: SizedBox(
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: FanSchedulePalette.cardGradient,
                  borderRadius: BorderRadius.circular(m.cardRadius),
                  border: Border.all(color: FanSchedulePalette.line),
                  boxShadow: [
                    BoxShadow(
                      color: FanSchedulePalette.accentRed.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(m.cardRadius),
                  child: calendarBody,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _calendarHeader(String monthLabel, FanScheduleMetrics m) {
    return Container(
      height: m.headerHeight,
      decoration: const BoxDecoration(
        gradient: FanSchedulePalette.headerGradient,
        border: Border(
          bottom: BorderSide(color: FanSchedulePalette.line, width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: m.horizontalPadding * 0.5),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _navButton(Icons.chevron_left_rounded, () => _changeMonth(-1)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SCHEDULE',
                        style: fanScheduleLabel(
                          size: 8.5,
                          color: FanSchedulePalette.accentRed,
                          weight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fanScheduleLabel(
                          size: m.monthFontSize,
                          color: FanSchedulePalette.textPrimary,
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                _navButton(Icons.chevron_right_rounded, () => _changeMonth(1)),
              ],
            ),
          ),
          Container(
            height: 3,
            width: 48,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: FanSchedulePalette.accentRed,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: FanSchedulePalette.accentRed.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FanSchedulePalette.bgElevated,
            border: Border.all(
              color: FanSchedulePalette.line,
            ),
          ),
          child: Icon(icon, color: FanSchedulePalette.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _weekdayRow(FanScheduleMetrics m) {
    return Container(
      height: m.weekdayHeight,
      decoration: const BoxDecoration(
        color: FanSchedulePalette.bgElevated,
        border: Border(
          bottom: BorderSide(color: FanSchedulePalette.line, width: 0.5),
        ),
      ),
      child: Row(
        children: _weekdays
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: fanScheduleLabel(
                      size: m.weekdayFontSize,
                      color: FanSchedulePalette.textMuted,
                      weight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _dayCell(
    DateTime? day,
    Map<DateTime, List<Game>> byDay,
    FanScheduleMetrics m,
    double rowHeight,
  ) {
    if (day == null) {
      return Container(
        decoration: const BoxDecoration(
          color: FanSchedulePalette.bgCellEmpty,
          border: Border(
            right: BorderSide(color: FanSchedulePalette.lineSoft, width: 0.5),
            bottom: BorderSide(color: FanSchedulePalette.lineSoft, width: 0.5),
          ),
        ),
      );
    }

    final dayGames = byDay[day] ?? const <Game>[];
    final hasGame = dayGames.isNotEmpty;
    final game = hasGame ? dayGames.first : null;
    final isSelected = _selectedDay != null &&
        _selectedDay!.year == day.year &&
        _selectedDay!.month == day.month &&
        _selectedDay!.day == day.day;
    final isToday = _isToday(day);
    final tight = m.cellIsTight(rowHeight);
    final logoSize = m.cellLogoSizeFor(rowHeight, hasGame: hasGame);

    return Material(
      color: isSelected
          ? FanSchedulePalette.accentRed.withValues(alpha: 0.12)
          : FanSchedulePalette.bgCell,
      child: InkWell(
        onTap: () => _onDayTap(day, dayGames),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? FanSchedulePalette.accentRed
                  : FanSchedulePalette.lineSoft,
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: FanSchedulePalette.accentRed.withValues(alpha: 0.25),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasGame && game != null)
                  _homeAwayBanner(game, m, rowHeight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 2, 0),
                  child: Row(
                    children: [
                      Text(
                        '${day.day}',
                        style: fanScheduleLabel(
                          size: m.dayNumberFontSize,
                          color: isToday
                              ? FanSchedulePalette.today
                              : FanSchedulePalette.textSecondary,
                          weight: hasGame ? FontWeight.w800 : FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: FanSchedulePalette.today,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasGame && game != null) ...[
                  if (logoSize > 0 && !tight)
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _opponentLogo(game, size: logoSize),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: box.maxWidth),
                            child: Text(
                              _cellFooter(game, dayGames.length, tight: tight),
                              textAlign: TextAlign.center,
                              maxLines: tight ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: fanScheduleLabel(
                                size: m.cellFooterFontSize,
                                color: game.hasResult
                                    ? (game.darCityWon
                                        ? FanSchedulePalette.win
                                        : FanSchedulePalette.loss)
                                    : FanSchedulePalette.textPrimary,
                                weight: FontWeight.w800,
                                letterSpacing: 0.1,
                                height: 1.05,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeAwayBanner(Game game, FanScheduleMetrics m, double rowHeight) {
    final isHome = game.isDarCityHome;
    final maxH = (rowHeight * 0.22).clamp(8.0, 12.0);

    return Container(
      height: maxH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHome
              ? [FanSchedulePalette.gold, FanSchedulePalette.goldDeep]
              : [FanSchedulePalette.purpleMid, FanSchedulePalette.purpleSoft],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            isHome ? 'HOME' : 'AWAY',
            style: fanScheduleLabel(
              size: m.bannerFontSize,
              color: isHome ? Colors.black87 : Colors.white,
              weight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  String _cellFooter(Game game, int count, {required bool tight}) {
    if (game.hasResult) {
      final line = game.darCityResultLine;
      if (count > 1) return '$line +${count - 1}';
      return line;
    }
    final opponent = game.opponentShort;
    if (tight) return opponent;
    final time = game.displayTime;
    if (count > 1) return '$opponent · $time +${count - 1}';
    return '$opponent · $time';
  }

  Widget _detailCard(Game? game, FanScheduleMetrics m, String locale) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
        ),
        border: Border(
          top: BorderSide(color: FanSchedulePalette.line, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        m.horizontalPadding,
        14,
        m.horizontalPadding,
        18,
      ),
      child: game == null
          ? _emptyDetail(m, locale)
          : _matchDetail(game, m, locale),
    );
  }

  Widget _emptyDetail(FanScheduleMetrics m, String locale) {
    final label = _selectedDay != null
        ? DateFormat.MMMd(locale).format(_selectedDay!)
        : DateFormat.MMMd(locale).format(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: fanScheduleLabel(
            size: 11,
            color: FanSchedulePalette.textMuted,
            weight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Icon(
          Icons.event_busy_rounded,
          size: 32,
          color: FanSchedulePalette.textMuted.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          'No match scheduled',
          style: fanScheduleLabel(
            size: 13,
            color: FanSchedulePalette.textSecondary,
            weight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _matchDetail(Game game, FanScheduleMetrics m, String locale) {
    final statusLabel = game.hasResult
        ? 'FINAL'
        : (game.isUpcoming ? 'UPCOMING' : 'SCHEDULED');
    final statusColor = game.hasResult
        ? FanSchedulePalette.textSecondary
        : FanSchedulePalette.accentRed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          game.detailDateLabel.toUpperCase(),
          style: fanScheduleLabel(
            size: 10,
            color: FanSchedulePalette.textMuted,
            weight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          game.matchupLabel,
          style: fanScheduleLabel(
            size: m.detailMatchupFontSize,
            color: FanSchedulePalette.textPrimary,
            weight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _teamColumn(
              game.fanLeftShort,
              game.fanLeftLogo,
              m,
              score: game.hasResult ? game.fanLeftScore : null,
              highlight: game.fanLeftIsDarCity,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: m.isCompact ? 14 : 22),
              child: Text(
                'VS',
                style: fanScheduleLabel(
                  size: 14,
                  color: FanSchedulePalette.textMuted,
                  weight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            _teamColumn(
              game.fanRightShort,
              game.fanRightLogo,
              m,
              score: game.hasResult ? game.fanRightScore : null,
              highlight: game.fanRightIsDarCity,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statusChip(statusLabel, statusColor),
        if (game.venue.isNotEmpty && game.venue != 'TBD') ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: FanSchedulePalette.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  game.venue,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: fanScheduleLabel(
                    size: 11,
                    color: FanSchedulePalette.textSecondary,
                    weight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (game.hasResult)
          Text(
            game.darCityResultLine,
            style: fanScheduleLabel(
              size: m.detailScoreFontSize,
              color: game.darCityWon
                  ? FanSchedulePalette.win
                  : FanSchedulePalette.loss,
              weight: FontWeight.w900,
              letterSpacing: 1,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                game.displayTime,
                style: fanScheduleLabel(
                  size: m.detailTimeFontSize,
                  color: FanSchedulePalette.textPrimary,
                  weight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              _homeAwayChip(game.isDarCityHome),
            ],
          ),
        if (game.hasResult) ...[
          const SizedBox(height: 10),
          _homeAwayChip(game.isDarCityHome),
        ],
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: fanScheduleLabel(
          size: 10,
          color: color,
          weight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _homeAwayChip(bool isHome) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHome
              ? [FanSchedulePalette.gold, FanSchedulePalette.goldDeep]
              : [FanSchedulePalette.purpleMid, FanSchedulePalette.purpleSoft],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: (isHome ? FanSchedulePalette.gold : FanSchedulePalette.purpleMid)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isHome ? 'HOME' : 'AWAY',
        style: fanScheduleLabel(
          size: 10,
          color: isHome ? Colors.black87 : Colors.white,
          weight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _teamColumn(
    String name,
    String logoUrl,
    FanScheduleMetrics m, {
    int? score,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          _teamMark(
            name,
            logoUrl,
            size: m.detailLogoSize,
            highlight: highlight,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: fanScheduleLabel(
              size: 11,
              color: highlight
                  ? FanSchedulePalette.gold
                  : FanSchedulePalette.textPrimary,
              weight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          if (score != null) ...[
            const SizedBox(height: 4),
            Text(
              '$score',
              style: fanScheduleLabel(
                size: m.detailScoreFontSize,
                color: FanSchedulePalette.textPrimary,
                weight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _opponentLogo(Game game, {required double size}) {
    return _teamMark(game.opponentShort, game.opponentLogo, size: size);
  }

  Widget _teamMark(
    String shortName,
    String url, {
    required double size,
    bool highlight = false,
  }) {
    final ring = highlight ? FanSchedulePalette.gold : FanSchedulePalette.line;

    Widget badge = _initialsBadge(shortName, size);
    if (url.isNotEmpty) {
      badge = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => _initialsBadge(shortName, size),
      );
    }

    return Container(
      width: size + 8,
      height: size + 8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FanSchedulePalette.bgElevated,
        border: Border.all(color: ring, width: highlight ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: badge,
    );
  }

  Widget _initialsBadge(String shortName, double size) {
    final label = shortName.length > 3 ? shortName.substring(0, 3) : shortName;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FanSchedulePalette.bgElevated,
            FanSchedulePalette.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        label,
        style: fanScheduleLabel(
          size: size * 0.28,
          color: FanSchedulePalette.textSecondary,
          weight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
