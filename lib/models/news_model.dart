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
      isLiked: json['is_liked'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
    );
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
    };
  }
}

class Author {
  final int id;
  final String name;

  Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
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
