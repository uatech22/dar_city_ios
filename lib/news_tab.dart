import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/models/news_model.dart';
import 'package:dar_city_app/news_article_details.dart';
import 'package:dar_city_app/services/news_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  Future<List<News>>? _newsFuture;
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNews());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _newsFuture = NewsService.fetchNews();
      });
      // A small delay to make the refresh indicator visible
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  String _getTimeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
  
  void _showPostOptions(News news) {
    // Placeholder for future implementation
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchNews,
      color: Colors.red,
      backgroundColor: Colors.black,
      child: FutureBuilder<List<News>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return _buildNewsLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return _buildNewsErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyNewsState();
          }

          final newsList = snapshot.data!;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 60,
                collapsedHeight: 60,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.shade800],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sports News', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('${newsList.length} articles', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      if (_isRefreshing)
                        const Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final news = newsList[index];
                    return _buildNewsPostCard(news: news, isFirst: index == 0);
                  },
                  childCount: newsList.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewsPostCard({required News news, bool isFirst = false}) {
    final hasImage = news.image != null && news.image!.isNotEmpty;

    return Container(
      margin: EdgeInsets.fromLTRB(16, isFirst ? 16 : 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news))),
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.red.withOpacity(0.1),
          highlightColor: Colors.red.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red, Colors.red.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Icon(Icons.article_outlined, color: Colors.white, size: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dar City Official', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(_getTimeAgo(news.createdAt), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                              const SizedBox(width: 6),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3), width: 1)),
                                child: Text(news.category?.toUpperCase() ?? 'SPORTS', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _showPostOptions(news), icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.7), size: 24), splashRadius: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(news.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
                if (news.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    news.content.length > 150 ? '${news.content.substring(0, 150)}...' : news.content,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
                  ),
                ],
                if (hasImage) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: news.image!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))),
                          errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey.shade800, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: Colors.red, size: 40), SizedBox(height: 8), Text('Could not load image', style: TextStyle(color: Colors.white70))])),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsLoadingSkeleton() {
    return const Center(child: CircularProgressIndicator(color: Colors.red));
  }

  Widget _buildNewsErrorState(String error) {
    return Center(child: Text('Error loading news: $error', style: const TextStyle(color: Colors.red)));
  }

  Widget _buildEmptyNewsState() {
    return const Center(child: Text('No news available.', style: TextStyle(color: Colors.white70)));
  }
}
