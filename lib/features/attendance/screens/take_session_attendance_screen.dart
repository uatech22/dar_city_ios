import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/attendance/services/attendance_service.dart';
import 'package:dar_city_app/features/attendance/widgets/session_day_page_indicator.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_attendance_premium.dart';
import 'package:dar_city_app/features/coach/widgets/training_session_picker.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

const _daysPerPage = 5;

class _PlayerMark {
  const _PlayerMark({required this.status, this.time});

  final String status;
  final TimeOfDay? time;

  _PlayerMark copyWith({String? status, TimeOfDay? time, bool clearTime = false}) {
    return _PlayerMark(
      status: status ?? this.status,
      time: clearTime ? null : (time ?? this.time),
    );
  }
}

class TakeSessionAttendanceScreen extends StatefulWidget {
  const TakeSessionAttendanceScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<TakeSessionAttendanceScreen> createState() =>
      _TakeSessionAttendanceScreenState();
}

class _TakeSessionAttendanceScreenState extends State<TakeSessionAttendanceScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  late CoachAttendanceMotion _motion;
  late Future<List<TrainingSession>> _sessionsFuture;
  String? _sessionId;
  DateTime? _selectedDate;
  int _dayPageIndex = 0;
  late Future<SessionAttendanceSummary> _attendanceFuture;
  final Map<int, _PlayerMark> _marksByPlayer = {};
  bool _submitting = false;
  bool _initialized = false;

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
    startAutoRefresh(_autoRefresh, interval: ApiConfig.refreshIntervalFast);
  }

  Future<void> _autoRefresh() async {
    await _reloadSessions();
    if (_marksByPlayer.isEmpty && !_submitting) {
      _loadAttendance();
      await _attendanceFuture;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
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
      _marksByPlayer.clear();
      _initialized = false;
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

  Future<void> _pickTimeForPlayer(int playerId) async {
    final mark = _marksByPlayer[playerId];
    if (mark == null || !attendanceStatusNeedsTime(mark.status)) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: mark.time ?? TimeOfDay.now(),
      helpText: attendanceTimeFieldLabel(mark.status).toUpperCase(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarColors.accentRed,
              onPrimary: Colors.white,
              surface: DarColors.cardDark,
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: DarColors.cardDark,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _marksByPlayer[playerId] = mark.copyWith(time: picked);
      });
    }
  }

  Future<void> _setPlayerStatus(int playerId, String status) async {
    if (status == 'none') {
      setState(() {
        _marksByPlayer[playerId] = const _PlayerMark(status: 'none');
      });
      return;
    }

    setState(() {
      _marksByPlayer[playerId] = _PlayerMark(
        status: status,
        time: TimeOfDay.now(),
      );
    });

    if (attendanceStatusNeedsTime(status)) {
      await _pickTimeForPlayer(playerId);
    }
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _submit(SessionAttendanceSummary summary) async {
    if (_selectedDate == null) return;
    setState(() => _submitting = true);
    try {
      final records = summary.players.map((p) {
        final mark = _marksByPlayer[p.playerId] ??
            _PlayerMark(status: p.status, time: parseAttendanceTimeIn(p.timeIn));
        return AttendanceRecord(
          playerId: p.playerId,
          status: mark.status,
          timeIn: mark.time != null ? formatAttendanceTimeIn(mark.time!) : null,
        );
      }).toList();
      final response = await AttendanceService.markSessionAttendance(
        MarkSessionAttendancePayload(
          sessionId: summary.sessionId,
          records: records,
          attendanceDate: formatSessionDateIso(_selectedDate!),
        ),
      );
      if (mounted) {
        final message = response['message'] as String? ?? 'Attendance saved';
        showFeatureSnackBar(context, message);
        _loadAttendance();
      }
    } on FeatureApiException catch (e) {
      if (mounted) showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
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

  Widget _statsBar({
    required int present,
    required int late,
    required int absent,
    required int unmarked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 340;
          final stats = [
            _StatItem('$present', 'PRESENT', Colors.white),
            _StatItem('$late', 'LATE', const Color(0xFFFFAA44)),
            _StatItem('$absent', 'ABSENT', DarColors.accentRed),
            if (unmarked > 0)
              _StatItem('$unmarked', 'UNMARKED', DarColors.muted),
          ];
          if (narrow) {
            return Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 8,
              children: stats
                  .map(
                    (s) => SizedBox(
                      width: constraints.maxWidth / 2 - 8,
                      child: _statCol(s.value, s.label, s.color),
                    ),
                  )
                  .toList(),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) _divider(),
                Expanded(child: _statCol(stats[i].value, stats[i].label, stats[i].color)),
              ],
            ],
          );
        },
      ),
    );
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
          'Take Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
                if (!_initialized) {
                  for (final p in summary.players) {
                    _marksByPlayer[p.playerId] = _PlayerMark(
                      status: p.status,
                      time: parseAttendanceTimeIn(p.timeIn),
                    );
                  }
                  _initialized = true;
                }

                final present =
                    _marksByPlayer.values.where((m) => m.status == 'present').length;
                final late =
                    _marksByPlayer.values.where((m) => m.status == 'late').length;
                final absent =
                    _marksByPlayer.values.where((m) => m.status == 'absent').length;
                final unmarked =
                    _marksByPlayer.values.where((m) => m.status == 'none').length;

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
                        badge: 'ROLL CALL',
                        title: 'Mark Attendance',
                        subtitle: summary.sessionTitle,
                        stats: [
                          (value: summary.presentRate, label: 'PRESENT'),
                          (value: '${summary.players.length}', label: 'ROSTER'),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DarColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DarColors.accentRed.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                    summary.sessionTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  summary.presentRate,
                                  style: const TextStyle(
                                    color: DarColors.accentRed,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'PRESENT',
                                  style: TextStyle(
                                    color: DarColors.muted.withValues(alpha: 0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _statsBar(
                        present: present,
                        late: late,
                        absent: absent,
                        unmarked: unmarked,
                      ),
                      const SizedBox(height: 20),
                      const CoachAttendanceStaticHeader(
                        label: 'ROSTER',
                        icon: Icons.groups_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (summary.players.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No players on roster for this session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: DarColors.muted),
                          ),
                        )
                      else
                        ...summary.players.map((p) {
                          final mark = _marksByPlayer[p.playerId] ??
                              _PlayerMark(
                                status: p.status,
                                time: parseAttendanceTimeIn(p.timeIn),
                              );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _playerAttendanceCard(p, mark),
                          );
                        }),
                      const SizedBox(height: 8),
                      CoachAttendanceSubmitButton(
                        motion: _motion,
                        label: 'SUBMIT ATTENDANCE',
                        loadingLabel: 'Saving...',
                        loading: _submitting,
                        icon: Icons.check_rounded,
                        onPressed: _submitting || summary.players.isEmpty
                            ? null
                            : () => _submit(summary),
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

  Widget _statCol(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DarColors.muted.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: DarColors.muted.withValues(alpha: 0.3));

  Widget _playerAttendanceCard(SessionPlayerAttendance player, _PlayerMark mark) {
    final status = mark.status;
    final accentColor = attendanceStatusColor(status);
    final hasAccent = status != 'none' && status != 'default';
    final showTime = attendanceStatusNeedsTime(status);

    return Container(
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAccent
              ? accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasAccent)
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.details,
                          style: TextStyle(
                            color: DarColors.muted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  child: _compactStatusActions(player.playerId, status),
                ),
              ],
            ),
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _timePickerTile(player.playerId, mark, compact: true),
            ),
        ],
      ),
    );
  }

  Widget _compactStatusActions(int playerId, String selectedStatus) {
    Widget pair(String a, String aStatus, String b, String bStatus) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusTextBtn(a, aStatus, selectedStatus == aStatus, playerId, compact: true),
          const SizedBox(width: 4),
          _statusTextBtn(b, bStatus, selectedStatus == bStatus, playerId, compact: true),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        pair('Present', 'present', 'Late', 'late'),
        const SizedBox(height: 4),
        pair('Absent', 'absent', 'Clear', 'none'),
      ],
    );
  }

  Widget _statusTextBtn(
    String label,
    String status,
    bool active,
    int playerId, {
    bool compact = false,
  }) {
    final color = status == 'none'
        ? DarColors.muted
        : attendanceStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPlayerStatus(playerId, status),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: BoxConstraints(minWidth: compact ? 52 : 72),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 6 : 12,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? color : Colors.white.withValues(alpha: 0.12),
              width: active ? 1.2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 9 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _timePickerTile(int playerId, _PlayerMark mark, {bool compact = false}) {
    final label = attendanceTimeFieldLabel(mark.status);
    final time = mark.time ?? TimeOfDay.now();
    final display = _formatTimeDisplay(time);
    final accent = attendanceStatusColor(mark.status);

    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _pickTimeForPlayer(playerId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: accent, size: compact ? 16 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label · $display',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Change',
                style: TextStyle(
                  color: accent,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
}
