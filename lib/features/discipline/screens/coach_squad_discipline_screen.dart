import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/core/widgets/dar_multi_select_field.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/services/attendance_service.dart';
import 'package:dar_city_app/features/attendance/widgets/session_day_page_indicator.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/training_session_picker.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

const _daysPerPage = 5;

enum _PenaltyFilter { all, late, absent }

class _PenaltyRow {
  const _PenaltyRow({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.details,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tokens,
    required this.totalAmount,
    required this.currency,
    this.arrivalLabel,
    this.penaltyStatus,
  });

  final String id;
  final int playerId;
  final String playerName;
  final String details;
  final String title;
  final String subtitle;
  final String status;
  final int tokens;
  final int totalAmount;
  final String currency;
  final String? arrivalLabel;
  final String? penaltyStatus;
}

class CoachSquadDisciplineScreen extends StatefulWidget {
  const CoachSquadDisciplineScreen({super.key});

  @override
  State<CoachSquadDisciplineScreen> createState() =>
      _CoachSquadDisciplineScreenState();
}

class _CoachSquadDisciplineScreenState extends State<CoachSquadDisciplineScreen>
    with AutoRefreshStateMixin {
  late Future<List<TrainingSession>> _sessionsFuture;
  String? _sessionId;
  DateTime? _selectedDate;
  int _dayPageIndex = 0;
  late Future<SessionAttendanceSummary> _dataFuture;

  final _searchController = TextEditingController();
  String _query = '';
  _PenaltyFilter _statusFilter = _PenaltyFilter.all;
  Set<int> _selectedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
    _dataFuture = _emptyData();
    startAutoRefresh(_autoRefresh);
  }

  Future<void> _autoRefresh() async {
    await _reloadSessions();
    _loadData();
    await _dataFuture;
  }

  @override
  void dispose() {
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

  Future<SessionAttendanceSummary> _emptyData() async {
    return const SessionAttendanceSummary(
      sessionId: '',
      dateLabel: '',
      sessionTitle: '',
      presentRate: '0%',
      players: [],
    );
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
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
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

  void _loadData() {
    if (_sessionId == null || _selectedDate == null) return;
    final sessionId = _sessionId!;
    final dateIso = formatSessionDateIso(_selectedDate!);
    setState(() {
      _dataFuture =
          AttendanceService.fetchSessionAttendance(sessionId, date: dateIso);
    });
  }

  void _onSessionChanged(String? sessionId, List<TrainingSession> sessions) {
    if (sessionId == null) return;
    final session = _sessionById(sessions, sessionId);
    if (session == null) return;
    final defaultDate = _defaultDateForSession(session);
    setState(() {
      _sessionId = sessionId;
      _selectedDate = defaultDate;
      _dayPageIndex = _pageIndexForDate(trainingSessionDates(session), defaultDate);
      _selectedPlayerIds = {};
    });
    _loadData();
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
    _loadData();
  }

  void _shiftDayPage(int delta, int totalPages) {
    final next = (_dayPageIndex + delta).clamp(0, totalPages - 1);
    if (next == _dayPageIndex) return;
    setState(() => _dayPageIndex = next);
  }

  String _penaltyTitle(String status) {
    switch (status) {
      case 'late':
        return 'Late Arrival';
      case 'absent':
      case 'noshow':
        return 'Unexcused Absence';
      case 'warning':
        return 'Discipline Warning';
      default:
        return 'Penalty';
    }
  }

  String? _formatArrivalLabel(String? timeIn, String status) {
    if (status != 'late' || timeIn == null || timeIn.trim().isEmpty) return null;
    final parsed = parseAttendanceTimeIn(timeIn);
    if (parsed != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
      return DateFormat.jm().format(dt);
    }
    return timeIn.trim();
  }

  List<_PenaltyRow> _buildRows(SessionAttendanceSummary session) {
    final rows = <_PenaltyRow>[];

    for (final p in session.players) {
      final penalty = p.penalty;
      if (penalty == null) continue;

      rows.add(
        _PenaltyRow(
          id: penalty.penaltyId ?? 'att-${p.playerId}',
          playerId: p.playerId,
          playerName: p.name,
          details: p.details,
          title: _penaltyTitle(p.status),
          subtitle: '${session.sessionTitle} · ${session.dateLabel}',
          status: p.status,
          tokens: penalty.tokens,
          totalAmount: penalty.totalAmount,
          currency: penalty.currency,
          arrivalLabel: _formatArrivalLabel(p.timeIn, p.status),
          penaltyStatus: penalty.status,
        ),
      );
    }

    return rows;
  }

  List<_PenaltyRow> _visibleRows(List<_PenaltyRow> rows) {
    var list = rows;

    switch (_statusFilter) {
      case _PenaltyFilter.late:
        list = list.where((r) => r.status == 'late').toList();
        break;
      case _PenaltyFilter.absent:
        list = list.where((r) => r.status == 'absent' || r.status == 'noshow').toList();
        break;
      case _PenaltyFilter.all:
        break;
    }

    if (_selectedPlayerIds.isNotEmpty) {
      list = list.where((r) => _selectedPlayerIds.contains(r.playerId)).toList();
    }

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where(
            (r) =>
                r.playerName.toLowerCase().contains(q) ||
                r.details.toLowerCase().contains(q) ||
                r.title.toLowerCase().contains(q) ||
                r.subtitle.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  List<MultiSelectOption<int>> _playerOptions(SessionAttendanceSummary session) {
    return session.players
        .map(
          (p) => MultiSelectOption<int>(
            id: p.playerId,
            title: p.name,
            subtitle: p.details,
            leading: DarPlayerAvatar(name: p.name, size: 36),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Squad Penalties',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: darResponsiveBody(
        FeatureAsyncBody<List<TrainingSession>>(
        future: _sessionsFuture,
        onRetry: _reloadSessions,
        builder: (context, sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'No training sessions yet',
                style: TextStyle(color: DarColors.muted),
              ),
            );
          }

          if (_sessionId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _sessionId == null) {
                _onSessionChanged(sessions.first.id, sessions);
              }
            });
          }

          final session = _sessionById(sessions, _sessionId);
          if (session == null) {
            return const Center(child: CircularProgressIndicator(color: DarColors.accentRed));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: DarColors.accentRed,
                  onRefresh: () async {
                    _loadData();
                    await _dataFuture;
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 0),
                          child: _filtersCard(session, sessions),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FeatureAsyncBody<SessionAttendanceSummary>(
                          future: _dataFuture,
                          onRetry: _loadData,
                          builder: (context, session) {
                            final rows = _buildRows(session);
                            final visible = _visibleRows(rows);

                            return Padding(
                              padding: DarLayoutMetrics.of(context).scrollPadding(top: 16, bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _statsStrip(rows),
                                  const SizedBox(height: 16),
                                  DarMultiSelectField<int>(
                                    label: 'Filter players',
                                    placeholder: 'All players — tap to pick one or more',
                                    searchHint: 'Search squad…',
                                    emptyMessage: 'No players match',
                                    options: _playerOptions(session),
                                    selectedIds: _selectedPlayerIds,
                                    onChanged: (ids) =>
                                        setState(() => _selectedPlayerIds = ids),
                                  ),
                                  const SizedBox(height: 14),
                                  _statusChips(),
                                  const SizedBox(height: 14),
                                  _searchBar(),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Penalties',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${visible.length} shown',
                                        style: TextStyle(color: DarColors.muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (visible.isEmpty)
                                    _emptyState(rows.isEmpty)
                                  else
                                    ...visible.map(_rowTile),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _filtersCard(TrainingSession session, List<TrainingSession> sessions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.accentRed.withValues(alpha: 0.18),
            DarColors.cardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSION & DATE',
            style: TextStyle(
              color: DarColors.accentRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          TrainingSessionPicker(
            includeAllSessions: true,
            sessions: sessions,
            label: 'Training session',
            hint: 'Pick a session',
            selectedTrainingId: _sessionId,
            onChanged: (id) => _onSessionChanged(id, sessions),
          ),
          const SizedBox(height: 12),
          _dayPager(session),
        ],
      ),
    );
  }

  Widget _dayPager(TrainingSession session) {
    final days = trainingSessionDates(session);
    if (days.isEmpty) return const SizedBox.shrink();

    final selected = _selectedDate ?? days.first;
    final totalPages = _totalDayPages(days.length);
    final safePage = _dayPageIndex.clamp(0, totalPages - 1);
    final start = safePage * _daysPerPage;
    final end = (start + _daysPerPage).clamp(0, days.length);
    final pageDays = days.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'DATE',
              style: TextStyle(
                color: DarColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('EEE, MMM d').format(selected),
              style: TextStyle(color: DarColors.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (days.length > _daysPerPage)
              _pageArrow(
                icon: Icons.chevron_left,
                enabled: safePage > 0,
                onTap: () => _shiftDayPage(-1, totalPages),
              ),
            Expanded(
              child: Row(
                children: pageDays.map((day) {
                  final isSelected = day.year == selected.year &&
                      day.month == selected.month &&
                      day.day == selected.day;
                  final dayNumber = days.indexOf(day) + 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _dayChip(
                        day: day,
                        dayNumber: dayNumber,
                        isSelected: isSelected,
                        onTap: () => _onDateSelected(day, days),
                      ),
                    ),
                  );
                }).toList(),
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
          const SizedBox(height: 6),
          SessionDayPageIndicator(
            totalPages: totalPages,
            currentPage: safePage,
            onPageSelected: (page) => setState(() => _dayPageIndex = page),
          ),
        ],
      ],
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: enabled ? Colors.white : DarColors.muted.withValues(alpha: 0.35),
          size: 20,
        ),
      ),
    );
  }

  Widget _dayChip({
    required DateTime day,
    required int dayNumber,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? DarColors.accentRed : DarColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? DarColors.accentRed
                  : DarColors.muted.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                'D$dayNumber',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : DarColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('d').format(day),
                style: TextStyle(
                  color: isSelected ? Colors.white : DarColors.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsStrip(List<_PenaltyRow> allRows) {
    final lateCount = allRows.where((r) => r.status == 'late').length;
    final absentCount =
        allRows.where((r) => r.status == 'absent' || r.status == 'noshow').length;
    final totalTokens = allRows.fold<int>(0, (sum, r) => sum + r.tokens);
    final totalAmount = allRows.fold<int>(0, (sum, r) => sum + r.totalAmount);
    final currency = allRows.isNotEmpty ? allRows.first.currency : 'TZS';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _miniStat('$lateCount', 'Late', Icons.schedule_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('$absentCount', 'Absent', Icons.event_busy_rounded)),
            const SizedBox(width: 8),
            Expanded(
              child: _miniStat('-$totalTokens', 'Tokens cut', Icons.toll_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payments_outlined, color: DarColors.accentRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'Total salary cut: ${formatPenaltyMoney(totalAmount, currency)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: DarColors.accentRed, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(label, style: TextStyle(color: DarColors.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _statusChips() {
    Widget chip(String label, _PenaltyFilter filter) {
      final active = _statusFilter == filter;
      return FilterChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: active ? Colors.white : DarColors.muted,
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: DarColors.cardDark,
        selectedColor: DarColors.accentRed.withValues(alpha: 0.85),
        side: BorderSide(
          color: active ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.25),
        ),
        onSelected: (_) => setState(() => _statusFilter = filter),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('All penalties', _PenaltyFilter.all),
        chip('Late', _PenaltyFilter.late),
        chip('Absent', _PenaltyFilter.absent),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Search player or infraction…',
        hintStyle: TextStyle(color: DarColors.muted, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, color: DarColors.accentRed, size: 20),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: Icon(Icons.close_rounded, color: DarColors.muted, size: 18),
              )
            : null,
        filled: true,
        fillColor: DarColors.cardDark,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarColors.muted.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarColors.muted.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarColors.accentRed),
        ),
      ),
    );
  }

  Widget _emptyState(bool noPenaltiesAtAll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user_outlined, size: 40, color: DarColors.green),
          const SizedBox(height: 10),
          Text(
            noPenaltiesAtAll
                ? 'Clean sheet — no penalties for this session & date'
                : 'No penalties match your filters',
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(_PenaltyRow row) {
    final statusColor = attendanceStatusColor(row.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarPlayerAvatar(name: row.playerName, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.playerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.details,
                            style: TextStyle(color: DarColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (row.tokens > 0)
                      _deductionBadge(
                        tokens: row.tokens,
                        totalAmount: row.totalAmount,
                        currency: row.currency,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  row.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (row.status == 'late' && row.arrivalLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: DarColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Arrived ${row.arrivalLabel}',
                        style: TextStyle(color: DarColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  row.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: DarColors.muted, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deductionBadge({
    required int tokens,
    required int totalAmount,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '-$tokens ${tokens == 1 ? 'token' : 'tokens'}',
            style: const TextStyle(
              color: DarColors.accentRed,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatPenaltyMoney(totalAmount, currency),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
