import 'dart:math' as math;

import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/services/attendance_service.dart';
import 'package:dar_city_app/features/attendance/widgets/session_day_page_indicator.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_attendance_premium.dart';
import 'package:dar_city_app/features/coach/widgets/training_session_picker.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

const _daysPerPage = 5;

/// Coach session attendance insights — same session/day filters as Take Attendance.
class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachAttendanceMotion _motion;
  final _searchController = TextEditingController();
  late Future<List<TrainingSession>> _sessionsFuture;
  String? _sessionId;
  DateTime? _selectedDate;
  int _dayPageIndex = 0;
  late Future<SessionAttendanceSummary> _attendanceFuture;
  AttendanceRosterFilter _filter = AttendanceRosterFilter.all;

  @override
  void initState() {
    super.initState();
    _motion = CoachAttendanceMotion(this);
    _sessionId = widget.sessionId;
    _sessionsFuture = _loadSessions();
    _attendanceFuture = Future.value(
      const SessionAttendanceSummary(
        sessionId: '',
        dateLabel: '',
        sessionTitle: '',
        presentRate: '0%',
        players: [],
      ),
    );
    startAutoRefresh(_autoRefresh);
  }

  Future<void> _autoRefresh() async {
    await _reloadSessions();
    _loadAttendance();
    await _attendanceFuture;
  }

  @override
  void dispose() {
    _motion.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<TrainingSession>> _loadSessions() async {
    final results = await Future.wait([
      CoachTrainingSessionService.fetchSessions(status: 'upcoming'),
      CoachTrainingSessionService.fetchSessions(status: 'past'),
    ]);
    final byId = <String, TrainingSession>{};
    for (final session in [...results[0], ...results[1]]) {
      byId[session.id] = session;
    }
    return byId.values.toList();
  }

  TrainingSession? _sessionById(List<TrainingSession> sessions, String? id) {
    if (id == null) return null;
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  DateTime _defaultDateForSession(TrainingSession session) {
    final days = trainingSessionDates(session);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    for (final day in days) {
      if (day.year == todayOnly.year &&
          day.month == todayOnly.month &&
          day.day == todayOnly.day) {
        return day;
      }
    }
    return days.first;
  }

  int _pageIndexForDate(List<DateTime> days, DateTime date) {
    final index = days.indexWhere(
      (d) =>
          d.year == date.year && d.month == date.month && d.day == date.day,
    );
    if (index < 0) return 0;
    return index ~/ _daysPerPage;
  }

  int _totalDayPages(int dayCount) =>
      dayCount <= 0 ? 1 : ((dayCount - 1) ~/ _daysPerPage) + 1;

  Future<void> _reloadSessions() async {
    final future = _loadSessions();
    setState(() => _sessionsFuture = future);
    await future;
  }

  void _loadAttendance() {
    if (_sessionId == null || _selectedDate == null) return;
    setState(() {
      _attendanceFuture = AttendanceService.fetchSessionAttendance(
        _sessionId!,
        date: formatSessionDateIso(_selectedDate!),
      );
    });
  }

  void _onSessionChanged(String? sessionId, List<TrainingSession> sessions) {
    if (sessionId == null) return;
    final session = _sessionById(sessions, sessionId);
    if (session == null) return;
    final days = trainingSessionDates(session);
    final defaultDate = _defaultDateForSession(session);
    setState(() {
      _sessionId = sessionId;
      _selectedDate = defaultDate;
      _dayPageIndex = _pageIndexForDate(days, defaultDate);
    });
    _loadAttendance();
  }

  void _onDateSelected(DateTime date, List<DateTime> allDays) {
    if (_selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day) {
      return;
    }
    setState(() {
      _selectedDate = date;
      _dayPageIndex = _pageIndexForDate(allDays, date);
    });
    _loadAttendance();
  }

  void _shiftDayPage(int delta, int totalPages) {
    final next = (_dayPageIndex + delta).clamp(0, totalPages - 1);
    if (next == _dayPageIndex) return;
    setState(() => _dayPageIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: darResponsiveBody(
        SafeArea(
        child: FeatureAsyncBody<List<TrainingSession>>(
          future: _sessionsFuture,
          onRetry: _reloadSessions,
          builder: (context, sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No training sessions — create one in the Session tab first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DarColors.muted, fontSize: 14),
                  ),
                ),
              );
            }

            if (_sessionId == null ||
                _sessionById(sessions, _sessionId) == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onSessionChanged(sessions.first.id, sessions);
              });
            }

            final session = _sessionById(sessions, _sessionId);
            if (session == null) {
              return const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              );
            }

            if (_selectedDate == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final days = trainingSessionDates(session);
                  final date = _defaultDateForSession(session);
                  setState(() {
                    _selectedDate = date;
                    _dayPageIndex = _pageIndexForDate(days, date);
                  });
                  _loadAttendance();
                }
              });
            }

            return FeatureAsyncBody<SessionAttendanceSummary>(
              future: _attendanceFuture,
              onRetry: _loadAttendance,
              builder: (context, summary) {
                final filtered = summary.playersFiltered(
                  search: _searchController.text,
                  filter: _filter,
                );
                final breakdown = summary.statusBreakdown;
                final chartSegments = _chartSegments(breakdown);

                return RefreshIndicator(
                  color: DarColors.accentRed,
                  backgroundColor: DarColors.surface,
                  onRefresh: () async => _loadAttendance(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: DarLayoutMetrics.of(context).scrollPadding(top: 8, bottom: 32),
                    children: [
                      CoachAttendanceHero(
                        motion: _motion,
                        badge: 'INSIGHTS',
                        title: 'Analytics',
                        subtitle: summary.sessionTitle,
                        stats: [
                          (value: summary.presentRate, label: 'PRESENT'),
                          (value: '${summary.rosterSize}', label: 'ROSTER'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TrainingSessionPicker(
                        sessions: sessions,
                        includeAllSessions: true,
                        required: true,
                        label: 'Training Session',
                        hint: 'Select a session',
                        selectedTrainingId: _sessionId,
                        onChanged: (id) => _onSessionChanged(id, sessions),
                      ),
                      const SizedBox(height: 12),
                      _dayPager(session),
                      const SizedBox(height: 16),
                      _heroCard(summary),
                      const SizedBox(height: 16),
                      _statsRow(summary),
                      const SizedBox(height: 22),
                      const CoachAttendanceStaticHeader(
                        label: 'FILTERS',
                        icon: Icons.tune_rounded,
                      ),
                      const SizedBox(height: 10),
                      _searchField(),
                      const SizedBox(height: 10),
                      _filterChips(),
                      const SizedBox(height: 22),
                      const CoachAttendanceStaticHeader(
                        label: 'STATUS BREAKDOWN',
                        icon: Icons.pie_chart_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _chartCard(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: _DonutChart(segments: chartSegments),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: chartSegments
                                    .map(
                                      (s) => _legendRow(s.label, s.count, s.color),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CoachAttendanceStaticHeader(
                        label: 'DISTRIBUTION',
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 10),
                      _chartCard(
                        child: Column(
                          children: chartSegments
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _HorizontalBar(
                                    label: s.label,
                                    value: s.count,
                                    max: summary.rosterSize.clamp(1, 999),
                                    color: s.color,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      CoachAttendanceStaticHeader(
                        label: 'NEEDS ATTENTION (${summary.atRiskCount})',
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 10),
                      summary.players
                              .where(
                                (p) => AttendanceManagementSummary.isAtRiskStatus(p.status),
                              )
                              .isEmpty
                          ? _emptyHint(
                              'No at-risk players for this session day.',
                            )
                          : Column(
                              children: summary.players
                                  .where(
                                    (p) => AttendanceManagementSummary.isAtRiskStatus(
                                      p.status,
                                    ),
                                  )
                                  .take(5)
                                  .map((p) => _playerInsightTile(p, highlight: true))
                                  .toList(),
                            ),
                      const SizedBox(height: 22),
                      CoachAttendanceStaticHeader(
                        label:
                            'SQUAD SNAPSHOT (${filtered.length}${_filter != AttendanceRosterFilter.all ? ' filtered' : ''})',
                        icon: Icons.groups_rounded,
                      ),
                      const SizedBox(height: 10),
                      filtered.isEmpty
                          ? _emptyHint('No players match your filter.')
                          : Column(
                              children: filtered
                                  .map((p) => _playerInsightTile(p))
                                  .toList(),
                            ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _dayPager(TrainingSession session) {
    final days = trainingSessionDates(session);
    final selected = _selectedDate ?? days.first;
    final totalPages = _totalDayPages(days.length);
    final safePage = _dayPageIndex.clamp(0, totalPages - 1);
    final start = safePage * _daysPerPage;
    final end = (start + _daysPerPage).clamp(0, days.length);
    final pageDays = days.sublist(start, end);
    final rangeLabel = days.length <= _daysPerPage
        ? '${days.length} day${days.length == 1 ? '' : 's'}'
        : 'Day ${start + 1}–$end of ${days.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CoachAttendanceStaticHeader(
            label: 'SELECT DAY',
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Text(
                rangeLabel,
                style: TextStyle(color: DarColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (days.length > _daysPerPage)
                _pageArrow(
                  icon: Icons.chevron_left,
                  enabled: safePage > 0,
                  onTap: () => _shiftDayPage(-1, totalPages),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotWidth = constraints.maxWidth / pageDays.length;
                    return Row(
                      children: pageDays.map((day) {
                        final isSelected = day.year == selected.year &&
                            day.month == selected.month &&
                            day.day == selected.day;
                        final dayNumber = days.indexOf(day) + 1;
                        return SizedBox(
                          width: slotWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _dayChip(
                              day: day,
                              dayNumber: dayNumber,
                              isSelected: isSelected,
                              compact: slotWidth < 58,
                              onTap: () => _onDateSelected(day, days),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              if (days.length > _daysPerPage)
                _pageArrow(
                  icon: Icons.chevron_right,
                  enabled: safePage < totalPages - 1,
                  onTap: () => _shiftDayPage(1, totalPages),
                ),
            ],
          ),
          if (days.length > _daysPerPage) ...[
            const SizedBox(height: 8),
            SessionDayPageIndicator(
              totalPages: totalPages,
              currentPage: safePage,
              onPageSelected: (page) => setState(() => _dayPageIndex = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 36,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: enabled ? Colors.white : DarColors.muted.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _dayChip({
    required DateTime day,
    required int dayNumber,
    required bool isSelected,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected ? DarColors.accentRed : DarColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? DarColors.accentRed
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'D$dayNumber',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : DarColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                DateFormat('d').format(day),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                DateFormat('EEE').format(day).toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : DarColors.muted,
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ChartSegment> _chartSegments(Map<String, int> breakdown) {
    const order = ['present', 'late', 'absent', 'warning', 'noshow', 'none', 'default'];
    final segments = <_ChartSegment>[];
    for (final key in order) {
      final count = breakdown[key];
      if (count != null && count > 0) {
        segments.add(
          _ChartSegment(
            label: attendanceStatusLabel(key),
            count: count,
            color: attendanceStatusColor(key),
          ),
        );
      }
    }
    for (final entry in breakdown.entries) {
      if (!order.contains(entry.key) && entry.value > 0) {
        segments.add(
          _ChartSegment(
            label: attendanceStatusLabel(entry.key),
            count: entry.value,
            color: attendanceStatusColor(entry.key),
          ),
        );
      }
    }
    if (segments.isEmpty) {
      segments.add(
        const _ChartSegment(label: 'No data', count: 1, color: DarColors.muted),
      );
    }
    return segments;
  }

  Widget _heroCard(SessionAttendanceSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.accentRed.withValues(alpha: 0.22),
            DarColors.surface,
            DarColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: DarColors.accentRed.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: _RateRing(percent: summary.ratePercent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.dateLabel.toUpperCase(),
                  style: TextStyle(
                    color: DarColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.sessionTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.rosterSize} players · ${summary.presentRate} present rate',
                  style: TextStyle(color: DarColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill('${summary.presentCount} present', DarColors.greenBright),
                    _pill('${summary.lateCount} late', const Color(0xFFFFAA44)),
                    _pill('${summary.absentCount} absent', DarColors.accentRed),
                    if (summary.unmarkedCount > 0)
                      _pill('${summary.unmarkedCount} unmarked', DarColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(SessionAttendanceSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            label: 'Present',
            value: '${summary.presentCount}',
            sub: 'On time',
            color: DarColors.greenBright,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            label: 'Late',
            value: '${summary.lateCount}',
            sub: 'Arrived late',
            color: const Color(0xFFFFAA44),
            icon: Icons.schedule,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStatCard(
            label: 'Absent',
            value: '${summary.absentCount}',
            sub: 'Missed session',
            color: DarColors.accentRed,
            icon: Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(sub, style: TextStyle(color: DarColors.muted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search player name or number',
          hintStyle: TextStyle(color: DarColors.muted, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: DarColors.muted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: DarColors.muted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AttendanceRosterFilter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              backgroundColor: DarColors.surface,
              selectedColor: DarColors.accentRed.withValues(alpha: 0.25),
              checkmarkColor: DarColors.accentRed,
              labelStyle: TextStyle(
                color: selected ? Colors.white : DarColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: BorderSide(
                color: selected
                    ? DarColors.accentRed
                    : DarColors.muted.withValues(alpha: 0.25),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _legendRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerInsightTile(SessionPlayerAttendance player, {bool highlight = false}) {
    final color = attendanceStatusColor(player.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? DarColors.accentRed.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          DarPlayerAvatar(name: player.name, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  player.details,
                  style: TextStyle(color: DarColors.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.timeIn != null && player.timeIn!.isNotEmpty)
                  Text(
                    'Time: ${player.timeIn}',
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              attendanceStatusLabel(player.status).toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: DarColors.muted, fontSize: 13),
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _RateRing extends StatelessWidget {
  const _RateRing({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RateRingPainter(percent: percent.clamp(0, 100)),
      child: Center(
        child: Text(
          '${percent.round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _RateRingPainter extends CustomPainter {
  _RateRingPainter({required this.percent});

  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const stroke = 8.0;

    final track = Paint()
      ..color = DarColors.muted.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progress = Paint()
      ..color = DarColors.accentRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    final sweep = 2 * math.pi * (percent / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RateRingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.segments});

  final List<_ChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutChartPainter(segments: segments),
      child: const SizedBox.expand(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.segments});

  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 14.0;
    final total = segments.fold<int>(0, (sum, s) => sum + s.count);
    if (total == 0) return;

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = 2 * math.pi * (segment.count / total);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
