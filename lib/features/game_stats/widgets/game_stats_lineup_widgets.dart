import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/models/game.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:dar_city_app/utils/team_name_short.dart';
import 'package:flutter/material.dart';

class GameStatsLineupHeader extends StatelessWidget {
  const GameStatsLineupHeader({
    required this.match,
    required this.title,
    required this.selectionLabel,
    required this.ready,
    required this.onCancel,
    required this.onConfirm,
    this.hint,
  });

  final Game match;
  final String title;
  final String selectionLabel;
  final bool ready;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarColors.accentRed.withValues(alpha: 0.32),
            DarColors.cardDark,
            DarColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          GameStatsLineupCircleButton(
            icon: Icons.close_rounded,
            backgroundColor: DarColors.cardDark,
            borderColor: DarColors.muted.withValues(alpha: 0.25),
            iconColor: Colors.white,
            onTap: onCancel,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'COACH HUB',
                  style: TextStyle(
                    color: DarColors.accentRed.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shortTeamName(match.homeTeam)} vs ${shortTeamName(match.awayTeam)}',
                  style: const TextStyle(color: DarColors.muted, fontSize: 12),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DarColors.muted.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: ready
                        ? DarColors.accentRed.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ready
                          ? DarColors.accentRed.withValues(alpha: 0.55)
                          : DarColors.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    selectionLabel,
                    style: TextStyle(
                      color: ready ? DarColors.accentRed : DarColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GameStatsLineupCircleButton(
            icon: Icons.check_rounded,
            backgroundColor: DarColors.accentRed,
            borderColor: DarColors.accentRed,
            iconColor: Colors.white,
            onTap: onConfirm,
          ),
        ],
      ),
    );
  }
}

class GameStatsLineupCircleButton extends StatelessWidget {
  const GameStatsLineupCircleButton({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(side: BorderSide(color: borderColor)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class GameStatsLineupValidationBanner extends StatelessWidget {
  const GameStatsLineupValidationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DarColors.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: DarColors.accentRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class GameStatsLineupPlayerCard extends StatelessWidget {
  const GameStatsLineupPlayerCard({
    required this.player,
    required this.selected,
    required this.onTap,
    this.isCaptain = false,
    this.showCaptainAction = false,
    this.onCaptainTap,
  });

  final Person player;
  final bool selected;
  final VoidCallback onTap;
  final bool isCaptain;
  final bool showCaptainAction;
  final VoidCallback? onCaptainTap;

  @override
  Widget build(BuildContext context) {
    final jersey = player.jerseyNumber?.toString() ?? '—';
    final borderColor = isCaptain
        ? const Color(0xFFFFD54F)
        : (selected ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.16));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? [
                      (isCaptain
                              ? const Color(0xFFFFD54F)
                              : DarColors.accentRed)
                          .withValues(alpha: 0.14),
                      DarColors.cardDark,
                    ]
                  : [DarColors.cardDark, DarColors.surface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: selected || isCaptain ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (isCaptain ? const Color(0xFFFFD54F) : DarColors.accentRed)
                          .withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (player.position.isNotEmpty)
                    Expanded(
                      child: Text(
                        player.position.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? DarColors.accentRed.withValues(alpha: 0.9)
                              : DarColors.muted.withValues(alpha: 0.75),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    '#$jersey',
                    style: TextStyle(
                      color: selected ? DarColors.accentRed : DarColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: GameStatsLineupPlayerPhoto(
                    imageUrl: player.image,
                    name: player.fullName,
                    selected: selected,
                    isCaptain: isCaptain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                player.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : DarColors.muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
              if (isCaptain) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.65)),
                  ),
                  child: const Text(
                    'CAPTAIN',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ] else if (selected) ...[
                const SizedBox(height: 6),
                if (showCaptainAction && onCaptainTap != null)
                  GestureDetector(
                    onTap: onCaptainTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DarColors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DarColors.muted.withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'SET CAPTAIN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DarColors.accentRed.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DarColors.accentRed.withValues(alpha: 0.45)),
                    ),
                    child: const Text(
                      'STARTER',
                      style: TextStyle(
                        color: DarColors.accentRed,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GameStatsLineupPlayerPhoto extends StatelessWidget {
  const GameStatsLineupPlayerPhoto({
    required this.imageUrl,
    required this.name,
    required this.selected,
    this.isCaptain = false,
  });

  final String? imageUrl;
  final String name;
  final bool selected;
  final bool isCaptain;

  static const _logoAsset = 'assets/images/dar-city-logo.png';

  @override
  Widget build(BuildContext context) {
    final size = DarLayoutMetrics.of(context).isTablet ? 78.0 : 68.0;
    final ringColor = isCaptain
        ? const Color(0xFFFFD54F)
        : (selected ? DarColors.accentRed : DarColors.muted.withValues(alpha: 0.25));

    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor,
          width: selected || isCaptain ? 2.5 : 1.5,
        ),
      ),
      child: ClipOval(child: _buildImage(size)),
    );
  }

  Widget _buildImage(double size) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholder: (_, __) => _placeholder(size),
        errorWidget: (_, __, ___) => _fallbackAsset(size),
      );
    }
    return _fallbackAsset(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: DarColors.surface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: DarColors.accentRed),
      ),
    );
  }

  Widget _fallbackAsset(double size) {
    return Image.asset(
      _logoAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => _initials(size),
    );
  }

  Widget _initials(double size) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (parts.isNotEmpty ? parts.first[0].toUpperCase() : '?');

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: DarColors.surface,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class GameStatsLineupEmptyRoster extends StatelessWidget {
  const GameStatsLineupEmptyRoster({required this.message, this.subtitle});

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: DarColors.muted.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: DarColors.muted.withValues(alpha: 0.9), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GameStatsLineupSelectionFooter extends StatelessWidget {
  const GameStatsLineupSelectionFooter({
    required this.label,
    required this.ready,
    required this.onContinue,
  });

  final String label;
  final bool ready;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: DarColors.cardDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: DarColors.muted.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: ready ? Colors.white : DarColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          FilledButton(
            onPressed: ready ? onContinue : null,
            style: FilledButton.styleFrom(
              backgroundColor: DarColors.accentRed,
              disabledBackgroundColor: DarColors.muted.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
