/// Relative timestamps for fan news posts and comments.
String formatTimeAgo(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);

  if (difference.isNegative) return 'Just now';

  final days = difference.inDays;
  if (days >= 365) {
    final years = days ~/ 365;
    return years == 1 ? '1 year ago' : '$years years ago';
  }
  if (days >= 30) {
    final months = days ~/ 30;
    return months == 1 ? '1 month ago' : '$months months ago';
  }
  if (days > 0) return '${days}d ago';

  final hours = difference.inHours;
  if (hours > 0) return '${hours}h ago';

  final minutes = difference.inMinutes;
  if (minutes > 0) return '${minutes}m ago';

  return 'Just now';
}

/// Parses ISO/date strings; returns empty when invalid.
String formatTimeAgoFromString(String? dateString, {DateTime? now}) {
  if (dateString == null || dateString.trim().isEmpty) return '';
  try {
    return formatTimeAgo(DateTime.parse(dateString), now: now);
  } catch (_) {
    return '';
  }
}
