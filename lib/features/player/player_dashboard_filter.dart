import 'package:intl/intl.dart';

import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/player/models/assigned_drill.dart';
import 'package:dar_city_app/features/player/services/player_dashboard_service.dart';

enum PlayerDashboardRange { today, week, month, year }

extension PlayerDashboardRangeLabel on PlayerDashboardRange {
  String get label {
    switch (this) {
      case PlayerDashboardRange.today:
        return 'Today';
      case PlayerDashboardRange.week:
        return 'Week';
      case PlayerDashboardRange.month:
        return 'Month';
      case PlayerDashboardRange.year:
        return 'Year';
    }
  }

  String get periodHint {
    switch (this) {
      case PlayerDashboardRange.today:
        return 'today';
      case PlayerDashboardRange.week:
        return 'this week';
      case PlayerDashboardRange.month:
        return 'this month';
      case PlayerDashboardRange.year:
        return 'this year';
    }
  }
}

/// Client-side filtered view — no extra backend calls.
class PlayerDashboardFilteredView {
  const PlayerDashboardFilteredView({
    required this.range,
    required this.rangeLabel,
    required this.drillsInRange,
    required this.drillsCompletedInRange,
    required this.drillsDueInRange,
    required this.tokenChangeInRange,
    required this.announcements,
    required this.alerts,
  });

  final PlayerDashboardRange range;
  final String rangeLabel;
  final List<AssignedDrill> drillsInRange;
  final int drillsCompletedInRange;
  final int drillsDueInRange;
  final int tokenChangeInRange;
  final List<Announcement> announcements;
  final List<PerformanceAlert> alerts;

  int get drillCompletionPercent => drillsDueInRange == 0
      ? 0
      : ((drillsCompletedInRange / drillsDueInRange) * 100).round();

  String get tokenPeriodLabel {
    final change = tokenChangeInRange;
    final sign = change > 0 ? '+' : '';
    return '$sign$change ${range.periodHint}';
  }

  factory PlayerDashboardFilteredView.from(
    PlayerDashboardData data,
    PlayerDashboardRange range, [
    DateTime? now,
  ]) {
    final bounds = rangeBounds(range, now);

    final drills = data.allDrills.where((d) {
      final due = parseDashboardDate(d.dueDate);
      if (due == null) {
        // Can't filter by date — show in month/year so wider ranges still populate.
        return range == PlayerDashboardRange.month ||
            range == PlayerDashboardRange.year;
      }
      return dateInBounds(due, bounds);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final completed = drills.where((d) => d.status == 'completed').length;

    final announcements = data.allAnnouncements.where((a) {
      final published = parseDashboardDate(a.publishedAt);
      if (published == null) return range == PlayerDashboardRange.year;
      return dateInBounds(published, bounds);
    }).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final alerts = data.allAlerts
        .where((a) => a.isPlayerFacing)
        .where((a) {
      final when = parseAlertTimestamp(a.timestamp, now);
      if (when == null) {
        return range != PlayerDashboardRange.today;
      }
      return dateInBounds(when, bounds);
    }).toList();

    final tokenChange = sumTokenChangeInRange(
      data.discipline?.history ?? const [],
      bounds,
    );

    return PlayerDashboardFilteredView(
      range: range,
      rangeLabel: formatRangeLabel(bounds),
      drillsInRange: drills,
      drillsCompletedInRange: completed,
      drillsDueInRange: drills.length,
      tokenChangeInRange: tokenChange,
      announcements: announcements,
      alerts: alerts.take(5).toList(),
    );
  }
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

class DateRangeBounds {
  const DateRangeBounds({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

DateRangeBounds rangeBounds(PlayerDashboardRange range, [DateTime? now]) {
  final today = startOfDay(now ?? DateTime.now());
  switch (range) {
    case PlayerDashboardRange.today:
      return DateRangeBounds(start: today, end: today);
    case PlayerDashboardRange.week:
      // Full calendar week Mon–Sun (includes upcoming days this week).
      final start = today.subtract(Duration(days: today.weekday - DateTime.monday));
      return DateRangeBounds(start: start, end: start.add(const Duration(days: 6)));
    case PlayerDashboardRange.month:
      return DateRangeBounds(
        start: DateTime(today.year, today.month, 1),
        end: DateTime(today.year, today.month + 1, 0),
      );
    case PlayerDashboardRange.year:
      return DateRangeBounds(
        start: DateTime(today.year, 1, 1),
        end: DateTime(today.year, 12, 31),
      );
  }
}

bool dateInBounds(DateTime date, DateRangeBounds bounds) {
  final day = startOfDay(date);
  return !day.isBefore(bounds.start) && !day.isAfter(bounds.end);
}

String formatRangeLabel(DateRangeBounds bounds) {
  final sameDay = bounds.start == bounds.end;
  if (sameDay) {
    return DateFormat('EEE, MMM d').format(bounds.start);
  }
  final start = DateFormat('MMM d').format(bounds.start);
  final end = DateFormat('MMM d').format(bounds.end);
  return '$start – $end';
}

DateTime? parseDashboardDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final isoEmbedded = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(trimmed);
  if (isoEmbedded != null) {
    try {
      return startOfDay(DateTime.parse(isoEmbedded.group(1)!));
    } catch (_) {}
  }

  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return startOfDay(iso.toLocal());

  for (final pattern in [
    'yyyy-MM-dd',
    'yyyy/MM/dd',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'MMM d, yyyy',
    'd MMM yyyy',
    'EEEE, MMM d',
  ]) {
    try {
      return startOfDay(DateFormat(pattern).parse(trimmed));
    } catch (_) {}
  }
  return null;
}

DateTime? parseHistoryDate(String subtitle) {
  final part = subtitle.split('•').first.trim();
  return parseDashboardDate(part);
}

DateTime? parseAlertTimestamp(String timestamp, [DateTime? now]) {
  final upper = timestamp.toUpperCase();
  if (upper.contains('TODAY')) {
    return startOfDay(now ?? DateTime.now());
  }
  return parseDashboardDate(timestamp);
}

int parseTokenChange(String tokenChange) {
  final trimmed = tokenChange.trim();
  final isNegative = trimmed.startsWith('-');
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  final value = int.tryParse(digits) ?? 0;
  return isNegative ? -value : value;
}

int sumTokenChangeInRange(
  List<DisciplineHistoryItem> history,
  DateRangeBounds bounds,
) {
  var sum = 0;
  for (final item in history) {
    final date = parseHistoryDate(item.subtitle);
    if (date == null || !dateInBounds(date, bounds)) continue;
    sum += parseTokenChange(item.tokenChange);
  }
  return sum;
}
