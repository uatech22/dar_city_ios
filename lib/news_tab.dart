import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/fan_premium.dart';
import 'package:dar_city_app/models/news_model.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/news_article_details.dart';
import 'package:dar_city_app/services/news_service.dart';
import 'package:dar_city_app/utils/format_time_ago.dart';
import 'package:flutter/material.dart';

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
    _refreshTimer = Timer.periodic(ApiConfig.refreshIntervalSlow, (_) => _fetchNews());
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
    return formatTimeAgo(date);
  }

  void _showPostOptions(News news) {
    // Placeholder for future implementation
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchNews,
      color: DarColors.accentRed,
      backgroundColor: DarColors.surface,
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

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            controller: _scrollController,
            padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 24),
            itemCount: newsList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FanSectionHeader(
                    label: 'Latest News',
                    icon: Icons.newspaper_rounded,
                    actionLabel: _isRefreshing ? null : null,
                  ),
                );
              }
              final news = newsList[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildNewsPostCard(news: news),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsPostCard({required News news}) {
    final hasImage = news.image != null && news.image!.isNotEmpty;

    return FanPremiumTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
        );
        if (mounted) _fetchNews();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DarColors.accentRed,
                      DarColors.accentRed.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dar City Official',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _getTimeAgo(news.createdAt),
                          style: TextStyle(color: DarColors.muted, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DarColors.accentRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: DarColors.accentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            news.category?.toUpperCase() ?? 'SPORTS',
                            style: const TextStyle(
                              color: DarColors.accentRed,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPostOptions(news),
                icon: Icon(Icons.more_horiz_rounded, color: DarColors.muted, size: 22),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            news.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (news.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              news.content.length > 150 ? '${news.content.substring(0, 150)}...' : news.content,
              style: TextStyle(color: DarColors.muted.withValues(alpha: 0.95), fontSize: 13, height: 1.5),
            ),
          ],
          if (hasImage) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: news.image!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: DarColors.cardDark,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: DarColors.accentRed,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: DarColors.cardDark,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: DarColors.accentRed, size: 36),
                      SizedBox(height: 8),
                      Text('Could not load image', style: TextStyle(color: DarColors.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildEngagementRow(news),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(News news) {
    final likeColor = news.isLiked ? DarColors.accentRed : DarColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DarColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _engagementStat(
              icon: news.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              iconColor: likeColor,
              count: news.likesCount,
              label: news.likesCount == 1 ? 'like' : 'likes',
              countColor: likeColor,
            ),
          ),
          Expanded(
            child: _engagementStat(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: DarColors.muted,
              count: news.commentsCount,
              label: news.commentsCount == 1 ? 'comment' : 'comments',
            ),
          ),
          Expanded(
            child: _engagementStat(
              icon: Icons.visibility_outlined,
              iconColor: DarColors.muted,
              count: news.viewsCount,
              label: news.viewsCount == 1 ? 'view' : 'views',
            ),
          ),
        ],
      ),
    );
  }

  Widget _engagementStat({
    required IconData icon,
    required Color iconColor,
    required int count,
    required String label,
    Color countColor = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$count $label',
            style: TextStyle(
              color: countColor == Colors.white ? DarColors.muted : countColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsLoadingSkeleton() {
    return const Center(child: CircularProgressIndicator(color: DarColors.accentRed));
  }

  Widget _buildNewsErrorState(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: FanEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Could not load news',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNewsState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        Padding(
          padding: EdgeInsets.all(24),
          child: FanEmptyState(
            icon: Icons.newspaper_outlined,
            message: 'No news available yet',
          ),
        ),
      ],
    );
  }
}
