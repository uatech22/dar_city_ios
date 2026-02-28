class Comment {
  final int id;
  final String content;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String createdAt;
  final bool isOwnComment;
  final int repliesCount;
  bool isLiked;
  int likesCount;
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
    int _parseFlexibleInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    bool _parseFlexibleBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    var repliesList = json['replies'] as List? ?? [];
    List<Comment> parsedReplies = repliesList.map((r) => Comment.fromJson(r)).toList();

    return Comment(
      id: _parseFlexibleInt(json['id']),
      content: json['comment'] ?? '',
      userId: _parseFlexibleInt(json['user']?['id']),
      userName: json['user']?['name'] ?? 'Unknown User',
      userAvatar: json['user']?['passport'],
      createdAt: json['created_at'] ?? '',
      isLiked: _parseFlexibleBool(json['is_liked']),
      likesCount: _parseFlexibleInt(json['likes_count']),
      isOwnComment: _parseFlexibleBool(json['is_own_comment']),
      replies: parsedReplies,
      repliesCount: _parseFlexibleInt(json['replies_count']),
    );
  }
}
