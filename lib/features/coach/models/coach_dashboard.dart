import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/shared/json_parse.dart';

/// Screen #1 — Coach Training Dashboard
class CoachDashboard {
  const CoachDashboard({
    required this.upcomingTraining,
    required this.quickStats,
    required this.recentAnnouncements,
  });

  final UpcomingTraining upcomingTraining;
  final List<QuickStat> quickStats;
  final List<RecentAnnouncement> recentAnnouncements;

  factory CoachDashboard.fromJson(Map<String, dynamic> json) {
    return CoachDashboard(
      upcomingTraining: UpcomingTraining.fromJson(
        json['upcoming_training'] as Map<String, dynamic>,
      ),
      quickStats: (json['quick_stats'] as List<dynamic>)
          .map((e) => QuickStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAnnouncements: (json['recent_announcements'] as List<dynamic>)
          .map((e) => RecentAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UpcomingTraining {
  const UpcomingTraining({
    required this.scheduledAt,
    required this.title,
    required this.focus,
    this.imageUrl,
  });

  final String scheduledAt;
  final String title;
  final String focus;
  final String? imageUrl;

  factory UpcomingTraining.fromJson(Map<String, dynamic> json) {
    return UpcomingTraining(
      scheduledAt: json['scheduled_at'] as String,
      title: json['title'] as String,
      focus: json['focus'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }
}

class QuickStat {
  const QuickStat({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  factory QuickStat.fromJson(Map<String, dynamic> json) {
    return QuickStat(
      title: json['title'] as String,
      value: json['value'] as String,
      trend: json['trend'] as String,
      trendUp: json['trend_up'] as bool? ?? true,
    );
  }
}

class RecentAnnouncement {
  const RecentAnnouncement({
    required this.id,
    required this.title,
    required this.authorName,
  });

  final String id;
  final String title;
  final String authorName;

  factory RecentAnnouncement.fromJson(Map<String, dynamic> json) {
    return RecentAnnouncement(
      id: uuidFromJson(json['id']),
      title: json['title'] as String? ??
          json['subject'] as String? ??
          'Announcement',
      authorName: json['author_name'] as String? ?? 'Coach',
    );
  }

  /// Minimal record when full fetch is unavailable.
  Announcement toFallbackAnnouncement() {
    return Announcement(
      id: id,
      subject: title,
      body: 'Open Team Chat → Announcements for the full message.',
      publishedAt: '',
      authorName: authorName,
    );
  }
}
