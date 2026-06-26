import 'package:dar_city_app/features/shared/json_parse.dart';

/// Screen #3 — Coach Team Announcement
class AnnouncementPayload {
  const AnnouncementPayload({
    required this.subject,
    required this.body,
    this.imageUrl,
    this.videoUrl,
    this.linkUrl,
  });

  final String subject;
  final String body;
  final String? imageUrl;
  final String? videoUrl;
  final String? linkUrl;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'body': body,
        if (imageUrl != null) 'image_url': imageUrl,
        if (videoUrl != null) 'video_url': videoUrl,
        if (linkUrl != null) 'link_url': linkUrl,
      };
}

class Announcement {
  const Announcement({
    required this.id,
    required this.subject,
    required this.body,
    required this.publishedAt,
    this.authorName,
    this.imageUrl,
    this.videoUrl,
    this.linkUrl,
  });

  final String id;
  final String subject;
  final String body;
  final String publishedAt;
  final String? authorName;
  final String? imageUrl;
  final String? videoUrl;
  final String? linkUrl;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: uuidFromJson(json['id']),
      subject: json['subject'] as String,
      body: json['body'] as String,
      publishedAt: json['published_at'] as String,
      authorName: json['author_name'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      linkUrl: json['link_url'] as String?,
    );
  }

  bool get hasMedia =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (videoUrl != null && videoUrl!.isNotEmpty) ||
      (linkUrl != null && linkUrl!.isNotEmpty);

  String get bodyPreview {
    final trimmed = body.trim();
    if (trimmed.length <= 100) return trimmed;
    return '${trimmed.substring(0, 100).trim()}…';
  }
}

List<Announcement> sortAnnouncementsNewestFirst(List<Announcement> list) {
  final copy = List<Announcement>.from(list);
  copy.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  return copy;
}

int countAnnouncementsWithMedia(List<Announcement> list) =>
    list.where((a) => a.hasMedia).length;
