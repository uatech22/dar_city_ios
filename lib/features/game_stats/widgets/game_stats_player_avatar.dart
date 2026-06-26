import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/utils/match_logo.dart';
import 'package:flutter/material.dart';

/// Player photo for game-stats pickers — network image or first-letter fallback.
class GameStatsPlayerAvatar extends StatelessWidget {
  const GameStatsPlayerAvatar({
    super.key,
    required this.player,
    this.size = 72,
    this.highlighted = false,
    this.ringColor,
  });

  final Person player;
  final double size;
  final bool highlighted;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = ringColor ??
        (highlighted ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.28));

    return Container(
      width: size + 6,
      height: size + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: highlighted ? 2.5 : 1.5,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: DarColors.accentRed.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(child: _image()),
    );
  }

  Widget _image() {
    final url = normalizeLogoUrl(player.image ?? '');
    if (url.isEmpty) return _letterFallback();

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      placeholder: (_, __) => _loading(),
      errorWidget: (_, __, ___) => _letterFallback(),
    );
  }

  Widget _loading() {
    return Container(
      width: size,
      height: size,
      color: DarColors.surface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: DarColors.accentRed),
      ),
    );
  }

  Widget _letterFallback() {
    final letter = player.firstName.trim().isNotEmpty
        ? player.firstName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarColors.accentRed.withValues(alpha: 0.35),
            DarColors.cardDark,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
