import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcement_detail_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcements_list_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_team_announcement_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_announcement_service.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

/// Announcements dashboard — Team Chat → Send Announcement tab.
class CoachAnnouncementsHubScreen extends StatefulWidget {
  const CoachAnnouncementsHubScreen({super.key, this.scrollBottomPadding = 24});

  /// Extra list padding when embedded above coach bottom nav.
  final double scrollBottomPadding;

  @override
  State<CoachAnnouncementsHubScreen> createState() =>
      _CoachAnnouncementsHubScreenState();
}

class _CoachAnnouncementsHubScreenState extends State<CoachAnnouncementsHubScreen>
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

  Future<void> _openCreate() async {
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CoachTeamAnnouncementScreen()),
    );
    if (published == true) await _load();
  }

  void _openViewAll() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachAnnouncementsListScreen()),
    ).then((_) => _load());
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
    final preview = sorted.take(5).toList();
    final withMedia = countAnnouncementsWithMedia(sorted);

    final layout = DarLayoutMetrics.of(context);

    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: layout.scrollPadding(top: 16, bottom: widget.scrollBottomPadding),
        children: [
          _StatsCard(
            total: sorted.length,
            withMedia: withMedia,
            latestDate: sorted.isNotEmpty ? sorted.first.publishedAt : null,
            onCreate: _openCreate,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LATEST ANNOUNCEMENTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              if (sorted.isNotEmpty)
                TextButton(
                  onPressed: _openViewAll,
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: DarColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            _EmptyPrompt(onCreate: _openCreate)
          else ...[
            ...preview.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnnouncementPreviewRow(
                  announcement: a,
                  onTap: () => _openDetail(a),
                ),
              ),
            ),
            if (sorted.length > 5) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _openViewAll,
                  child: Text(
                    'View all ${sorted.length} announcements',
                    style: const TextStyle(
                      color: DarColors.accentRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.total,
    required this.withMedia,
    required this.onCreate,
    this.latestDate,
  });

  final int total;
  final int withMedia;
  final String? latestDate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.cardDark,
            DarColors.cardDark.withValues(alpha: 0.9),
            DarColors.accentRed.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'PUBLISHED',
                        style: TextStyle(
                          color: DarColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _CreateAnnouncementButton(onPressed: onCreate),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                label: 'With media',
                value: '$withMedia',
                color: DarColors.eliteGold,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Text only',
                value: '${total - withMedia}',
                color: DarColors.muted,
              ),
            ],
          ),
          if (latestDate != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.schedule, color: DarColors.muted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Latest: $latestDate',
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateAnnouncementButton extends StatelessWidget {
  const _CreateAnnouncementButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DarColors.accentRed,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: DarColors.accentRed.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text(
                'New',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementPreviewRow extends StatelessWidget {
  const _AnnouncementPreviewRow({
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
            border: Border.all(color: DarColors.muted.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DarColors.cardBrown,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  announcement.hasMedia
                      ? Icons.perm_media_outlined
                      : Icons.campaign_outlined,
                  color: Colors.white,
                  size: 20,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        color: DarColors.muted.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined, color: DarColors.muted, size: 40),
          const SizedBox(height: 12),
          Text(
            'No announcements yet',
            style: TextStyle(
              color: DarColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap New to publish your first team update.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onCreate,
            child: const Text(
              'Create announcement',
              style: TextStyle(
                color: DarColors.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
