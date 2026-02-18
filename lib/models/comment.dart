class Comment {
  final int id;
  final String content;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String createdAt;
  final bool isOwnComment;
  final int repliesCount;
  bool isLiked; // Removed final
  int likesCount; // Removed final
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    this.isOwnComment = false,
    this.isLiked = false,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    bool _parseIsOwnComment(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    var repliesList = json['replies'] as List? ?? [];
    List<Comment> parsedReplies = repliesList.map((r) => Comment.fromJson(r)).toList();

    return Comment(
      id: json['id'] ?? 0, // Added fallback
      content: json['comment'] ?? '',
      userId: json['user']?['id'] ?? 0,
      userName: json['user']?['name'] ?? 'Unknown User',
      userAvatar: json['user']?['passport'],
      createdAt: json['created_at'] ?? '',
      isLiked: json['is_liked'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      isOwnComment: _parseIsOwnComment(json['is_own_comment']),
      replies: parsedReplies,
      repliesCount: json['replies_count'] ?? 0, // Added fallback
    );
  }
}
