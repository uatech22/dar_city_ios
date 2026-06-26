import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcement_detail_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_announcement_service.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

/// Full list of team announcements — opened from hub "View all".
class CoachAnnouncementsListScreen extends StatefulWidget {
  const CoachAnnouncementsListScreen({super.key});

  @override
  State<CoachAnnouncementsListScreen> createState() =>
      _CoachAnnouncementsListScreenState();
}

class _CoachAnnouncementsListScreenState extends State<CoachAnnouncementsListScreen>
    with AutoRefreshStateMixin {
  List<Announcement> _announcements = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    startAutoRefresh(_load);
  }

  Future<void> _load() async {
    try {
      final list = await CoachAnnouncementService.fetchAll();
      if (!mounted) return;
      setState(() {
        _announcements = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_announcements.isEmpty) _error = e;
      });
    }
  }

  void _openDetail(Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachAnnouncementDetailScreen(announcement: announcement),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('All Announcements'),
        centerTitle: true,
      ),
      body: darResponsiveBody(_buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _announcements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DarColors.accentRed),
      );
    }
    if (_error != null && _announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: DarColors.accentRed, size: 40),
              const SizedBox(height: 12),
              Text(
                featureErrorMessage(_error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = sortAnnouncementsNewestFirst(_announcements);
    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'No announcements yet',
          style: TextStyle(color: DarColors.muted, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: DarLayoutMetrics.of(context).scrollPadding(top: 16, bottom: 24),
        itemCount: sorted.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AnnouncementListTile(
          announcement: sorted[i],
          onTap: () => _openDetail(sorted[i]),
        ),
      ),
    );
  }
}

class _AnnouncementListTile extends StatelessWidget {
  const _AnnouncementListTile({
    required this.announcement,
    required this.onTap,
  });

  final Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DarColors.muted.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  announcement.hasMedia ? Icons.perm_media : Icons.campaign_outlined,
                  color: DarColors.accentRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.bodyPreview,
                      style: TextStyle(color: DarColors.muted, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.publishedAt,
                      style: TextStyle(
                        color: DarColors.muted.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: DarColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
