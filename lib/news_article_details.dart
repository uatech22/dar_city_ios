import 'dart:async';
import 'dart:io';
import 'package:dar_city_app/loginScreen.dart';
import 'package:dar_city_app/models/comment.dart';
import 'package:dar_city_app/models/news_model.dart';
import 'package:dar_city_app/services/comment_service.dart';
import 'package:dar_city_app/services/news_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final CommentService _commentService = CommentService();
  Future<List<Comment>>? _commentsFuture;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Timer? _refreshTimer;

  final Set<int> _expandedReplies = {};

  late bool _isNewsLiked;
  late int _newsLikesCount;
  late int _newsCommentsCount;

  @override
  void initState() {
    super.initState();
    _isNewsLiked = widget.news.isLiked;
    _newsLikesCount = widget.news.likesCount;
    _newsCommentsCount = widget.news.commentsCount;
    _loadInitialData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshComments());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData({bool showMainLoader = true}) async {
    if (showMainLoader && mounted) {
      setState(() => _isLoading = true);
    }

    await SessionManager().loadToken();
    final token = SessionManager().getToken();

    try {
      final freshNews = await NewsService.getNewsDetails(widget.news.id);
      if (mounted) {
        setState(() {
          _isNewsLiked = freshNews.isLiked;
          _newsLikesCount = freshNews.likesCount;
          _newsCommentsCount = freshNews.commentsCount;
        });
      }
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = token != null;
        _commentsFuture = _commentService.getComments(widget.news.id);
        if (showMainLoader) {
          _isLoading = false;
        }
      });
    }
  }

  void _refreshComments() {
    if (mounted) {
      setState(() {
        _commentsFuture = _commentService.getComments(widget.news.id);
      });
    }
  }

  String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  Future<void> _toggleNewsLike() async {
    if (!_isAuthenticated) {
      _showLoginDialog();
      return;
    }
    try {
      final result = await _commentService.toggleNewsLike(widget.news.id);
      if (mounted && result['success'] == true) {
        setState(() {
          _isNewsLiked = result['liked'] ?? _isNewsLiked;
          final newLikesCount = int.tryParse(result['likes_count'].toString());
          if (newLikesCount != null) {
            _newsLikesCount = newLikesCount;
          }
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    if (!_isAuthenticated) {
      _showLoginDialog();
      return;
    }
    try {
      final result = await _commentService.toggleCommentLike(comment.id);
      if (mounted && result['success'] == true) {
        setState(() {
          comment.isLiked = result['liked'] ?? comment.isLiked;
          final newLikesCount = int.tryParse(result['likes_count'].toString());
          if (newLikesCount != null) {
            comment.likesCount = newLikesCount;
          }
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _shareNews() async {
    final String contentSnippet = widget.news.content.length > 150
        ? '${widget.news.content.substring(0, 150)}...'
        : widget.news.content;
    const String appDownloadLink = 'https://darcitybasketball.com/';
    final String shareText =
        '${widget.news.title}\n\n'
        '$contentSnippet\n\n'
        'Read more on the Dar City Basketball app!\n'
        'Download now: $appDownloadLink';

    // If there is no image, share text only
    if (widget.news.image == null) {
      await Share.share(shareText, subject: widget.news.title);
      return;
    }

    // If there is an image, download and share it
    try {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing image...')));

      final response = await http.get(Uri.parse(widget.news.image!));
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/news_image.jpg').writeAsBytes(response.bodyBytes);

      final xFile = XFile(file.path);

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await Share.shareXFiles([xFile], text: shareText, subject: widget.news.title);

    } catch (e) {
      // Fallback to text-only share on error
      await Share.share(shareText, subject: widget.news.title);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Login Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'You need to login to like, comment, or interact with this article.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _loadInitialData());
            },
            child: const Text('Login Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog({int? parentId}) {
    if (!_isAuthenticated) {
      _showLoginDialog();
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool isPosting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.red, width: 1),
              ),
              title: Row(
                children: [
                  Icon(parentId == null ? Icons.comment_rounded : Icons.reply_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(parentId == null ? 'Add a Comment' : 'Add a Reply', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write your ${parentId == null ? 'comment' : 'reply'} here...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isPosting ? null : () async {
                    if (controller.text.trim().isEmpty) return;
                    setDialogState(() => isPosting = true);
                    try {
                      if (parentId == null) {
                        await _commentService.postComment(widget.news.id, controller.text.trim());
                      } else {
                        await _commentService.postReply(parentId, controller.text.trim());
                      }
                      if (mounted) Navigator.of(ctx).pop();
                      _loadInitialData();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
                    } finally {
                      setDialogState(() => isPosting = false);
                    }
                  },
                  child: isPosting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Post', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Article Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
            ),
            onPressed: _shareNews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Article...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            if (widget.news.image != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      widget.news.image!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.grey,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'SPORTS NEWS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Article Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Title
                  Text(
                    widget.news.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Article Meta Info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.shade800],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dar City Official',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Colors.white54),
                              const SizedBox(width: 6),
                              // Text(
                              //   _formatTimeAgo(widget.news.createdAt),
                              //   style: const TextStyle(
                              //     color: Colors.white54,
                              //     fontSize: 14,
                              //   ),
                              // ),
                              const SizedBox(width: 16),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.visibility_rounded, size: 14, color: Colors.white54),
                              const SizedBox(width: 6),
                              const Text(
                                ' Views',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Article Content
                  Text(
                    widget.news.content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Engagement Stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isNewsLiked
                                      ? [Colors.red, Colors.red.shade800]
                                      : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
                                ),
                                boxShadow: _isNewsLiked
                                    ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                    : null,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isNewsLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: _isNewsLiked ? Colors.white : Colors.white70,
                                  size: 24,
                                ),
                                onPressed: _toggleNewsLike,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_newsLikesCount',
                              style: TextStyle(
                                color: _isNewsLiked ? Colors.red : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Likes',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                                ),
                              ),
                              child: const Icon(
                                Icons.comment_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_newsCommentsCount',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Comments',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                                ),
                              ),
                              child:  IconButton(
                                icon: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                                ),
                                onPressed: _shareNews,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Share',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Comments Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshComments,
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                ],
              ),
            ),

            // Comments Section
            _buildCommentSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCommentSection() {
    return FutureBuilder<List<Comment>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load comments',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final comments = snapshot.data ?? [];
        if (_newsCommentsCount != comments.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) setState(() => _newsCommentsCount = comments.length);
          });
        }

        return Column(
          children: [
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 2),
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be the first to comment on this article',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (ctx, index) => _buildComment(comments[index]),
              ),
            if (!_isAuthenticated) _buildLoginPrompt(),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade800],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Join the Conversation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Log in to post your own comments, reply to others, and engage with the community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _loadInitialData()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 12),
                Text(
                  'Login or Sign Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment, {int level = 0}) {
    final bool isOwnComment = _isAuthenticated && comment.isOwnComment;
    final bool isExpanded = _expandedReplies.contains(comment.id);
    final isNested = level > 0;

    return Container(
      margin: EdgeInsets.fromLTRB(isNested ? 20.0 : 16.0, 8.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: isNested
                  ? Border.all(color: Colors.red.withOpacity(0.2))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red.shade800],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Comment Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimeAgo(comment.createdAt),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isOwnComment)
                            IconButton(
                              icon: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                              onPressed: () async => await _deleteComment(comment.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Comment Text
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions Row
                      Row(
                        children: [
                          // Like Button
                          InkWell(
                            onTap: () => _toggleCommentLike(comment),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: comment.isLiked ? Colors.red.withOpacity(0.15) : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: comment.isLiked ? Colors.red : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    comment.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    color: comment.isLiked ? Colors.red : Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    comment.likesCount.toString(),
                                    style: TextStyle(
                                      color: comment.isLiked ? Colors.red : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Reply Button
                          InkWell(
                            onTap: () => _showCommentDialog(parentId: comment.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.reply_rounded, color: Colors.white70, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // View/Hide Replies
          if (comment.repliesCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 76, top: 8),
              child: InkWell(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedReplies.remove(comment.id);
                  } else {
                    _expandedReplies.add(comment.id);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpanded ? 'Hide Replies' : 'View ${comment.repliesCount} Replies',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Replies
          if (isExpanded && comment.replies.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(left: 32),
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: comment.replies.map((reply) => _buildComment(reply, level: level + 1)).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _commentService.deleteComment(commentId);
      _loadInitialData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Like Button
            Expanded(
              child: InkWell(
                onTap: _toggleNewsLike,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isNewsLiked ? Colors.red.withOpacity(0.15) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isNewsLiked ? Colors.red : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon(
                      //   _isNewsLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      //   color: _isNewsLiked ? Colors.red : Colors.white70,
                      //   size: 20,
                      // ),
                      const SizedBox(height: 4),
                      Text(
                        '$_newsLikesCount',
                        style: TextStyle(
                          color: _isNewsLiked ? Colors.red : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Write Comment Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _showCommentDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Write Comment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}