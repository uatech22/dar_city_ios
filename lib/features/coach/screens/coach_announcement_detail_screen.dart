import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/responsive_scaffold.dart';
import 'package:dar_city_app/features/coach/models/announcement.dart';
import 'package:dar_city_app/features/coach/services/coach_announcement_service.dart';
import 'package:dar_city_app/features/coach/widgets/coach_dashboard_motion.dart';

/// Full announcement view — premium Dar City red/black with entrance motion.
class CoachAnnouncementDetailScreen extends StatefulWidget {
  const CoachAnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  final Announcement announcement;

  @override
  State<CoachAnnouncementDetailScreen> createState() =>
      _CoachAnnouncementDetailScreenState();
}

class _CoachAnnouncementDetailScreenState extends State<CoachAnnouncementDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _entrance;
  late AnimationController _ambient;
  late AnimationController _orbit;

  Announcement get a => widget.announcement;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _orbit.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasHeroImage = a.imageUrl != null && a.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: DarColors.background,
      body: darResponsiveBody(
        CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: hasHeroImage ? 280 : 200,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasHeroImage)
                    CachedNetworkImage(
                      imageUrl: a.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _heroFallback(),
                    )
                  else
                    _heroFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DarColors.accentRed.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.55),
                          DarColors.background,
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) {
                      return CoachFloatingParticles(t: _ambient.value);
                    },
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: CoachEntrance(
                      animation: _interval(0, 0.35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _liveChip(),
                          const SizedBox(height: 10),
                          Text(
                            a.subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: DarLayoutMetrics.of(context).scrollPadding(top: 8, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachEntrance(
                    animation: _interval(0.12, 0.38),
                    slideFrom: const Offset(0, 0.06),
                    child: _metaRow(),
                  ),
                  const SizedBox(height: 22),
                  CoachEntrance(
                    animation: _interval(0.22, 0.48),
                    child: AnimatedBuilder(
                      animation: _orbit,
                      builder: (context, child) {
                        return CoachSweepBorder(
                          t: _orbit.value,
                          radius: 18,
                          child: child!,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DarColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: AnimatedBuilder(
                          animation: _entrance,
                          builder: (context, _) {
                            return Opacity(
                              opacity: _interval(0.25, 0.55).value,
                              child: Text(
                                a.body,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.65,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    CoachEntrance(
                      animation: _interval(0.38, 0.62),
                      tilt: 0.03,
                      child: _mediaImage(a.imageUrl!),
                    ),
                  ],
                  if (a.videoUrl != null && a.videoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CoachEntrance(
                      animation: _interval(0.44, 0.66),
                      child: _attachmentTile(
                        icon: Icons.videocam_rounded,
                        label: 'Video attached',
                        subtitle: a.videoUrl!,
                        onTap: () => _openLink(a.videoUrl!),
                      ),
                    ),
                  ],
                  if (a.linkUrl != null && a.linkUrl!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CoachEntrance(
                      animation: _interval(0.5, 0.72),
                      child: _attachmentTile(
                        icon: Icons.link_rounded,
                        label: 'Open link',
                        subtitle: a.linkUrl!,
                        onTap: () => _openLink(a.linkUrl!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  CoachEntrance(
                    animation: _interval(0.58, 0.82),
                    child: _footerBadge(),
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

  Widget _heroFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/ground.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: DarColors.surface),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.accentRed.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveChip() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final pulse = 0.5 + math.sin(_ambient.value * math.pi * 2) * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.15 + pulse * 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.45 + pulse * 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: DarColors.accentRed.withValues(alpha: 0.6 + pulse * 0.4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DarColors.accentRed.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'TEAM ANNOUNCEMENT',
                style: TextStyle(
                  color: DarColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: DarColors.accentRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(Icons.person_rounded, color: DarColors.accentRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.authorName?.trim().isNotEmpty == true ? a.authorName! : 'Coach',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.publishedAt.isNotEmpty
                    ? a.publishedAt.toUpperCase()
                    : 'PUBLISHED',
                style: TextStyle(
                  color: DarColors.muted.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        if (a.hasMedia)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.perm_media, color: DarColors.accentRed, size: 14),
                SizedBox(width: 4),
                Text(
                  'MEDIA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mediaImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 220,
              color: DarColors.surface,
              child: const Center(
                child: CircularProgressIndicator(
                  color: DarColors.accentRed,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 160,
              alignment: Alignment.center,
              color: DarColors.surface,
              child: Text('Image unavailable', style: TextStyle(color: DarColors.muted)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: DarColors.accentRed.withValues(alpha: 0.15),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DarColors.accentRed.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: DarColors.accentRed, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: DarColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: DarColors.accentRed.withValues(alpha: 0.8), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerBadge() {
    return Center(
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, math.sin(_ambient.value * math.pi * 2) * 2),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DarColors.accentRed.withValues(alpha: 0.2),
                DarColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_basketball, color: DarColors.accentRed, size: 16),
              SizedBox(width: 8),
              Text(
                'DAR CITY · TEAM UPDATE',
                style: TextStyle(
                  color: DarColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads full announcement then shows [CoachAnnouncementDetailScreen].
class CoachAnnouncementDetailLoader extends StatefulWidget {
  const CoachAnnouncementDetailLoader({
    super.key,
    required this.announcementId,
    required this.fallback,
  });

  final String announcementId;
  final Announcement fallback;

  @override
  State<CoachAnnouncementDetailLoader> createState() =>
      _CoachAnnouncementDetailLoaderState();
}

class _CoachAnnouncementDetailLoaderState extends State<CoachAnnouncementDetailLoader> {
  late Future<Announcement> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  Future<Announcement> _resolve() async {
    final found = await CoachAnnouncementService.findById(widget.announcementId);
    return found ?? widget.fallback;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Announcement>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: DarColors.background,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: const Text('Announcement'),
            ),
            body: darResponsiveBody(
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: DarColors.accentRed),
                    const SizedBox(height: 16),
                    Text(
                      'Loading announcement…',
                      style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return CoachAnnouncementDetailScreen(announcement: snap.data!);
      },
    );
  }
}
