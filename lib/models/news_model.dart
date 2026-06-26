class News {
  final String id;
  final String title;
  final String content;
  final String? image;
  final DateTime? createdAt;
  final String? category;
  final Author? author;

  bool isLiked;
  int likesCount;
  int commentsCount;
  int viewsCount;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.createdAt,
    this.category,
    this.author,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      category: json['category'] ?? '',
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      isLiked: _parseBool(json['is_liked']),
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '') ?? 0,
      commentsCount: int.tryParse(json['comments_count']?.toString() ?? '') ?? 0,
      viewsCount: int.tryParse(
            json['views_count']?.toString() ??
                json['view_count']?.toString() ??
                json['views']?.toString() ??
                '',
          ) ??
          0,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'category': category,
      'author': author?.toJson(),
      'is_liked': isLiked,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'views_count': viewsCount,
    };
  }
}

class Author {
  final int id;
  final String name;

  Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
