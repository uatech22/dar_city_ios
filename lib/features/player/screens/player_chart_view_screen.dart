import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/player/screens/player_chat_contacts_screen.dart';
import 'package:dar_city_app/features/player/services/player_chat_service.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/chat_inbox_tile.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:flutter/material.dart';

/// Player Chats tab — 1:1 inbox (staff + teammates).
class PlayerChartViewScreen extends StatefulWidget {
  const PlayerChartViewScreen({
    super.key,
    this.embedded = false,
    this.refreshToken = 0,
  });

  final bool embedded;
  final int refreshToken;

  @override
  State<PlayerChartViewScreen> createState() => _PlayerChartViewScreenState();
}

class _PlayerChartViewScreenState extends State<PlayerChartViewScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  List<ChatConversation> _conversations = [];
  bool _loading = true;
  Object? _error;
  late PlayerMotion _motion;

  double get _bottomPadding => widget.embedded ? 96 : 24;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load, interval: ApiConfig.refreshIntervalFast);
  }

  @override
  void didUpdateWidget(PlayerChartViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await PlayerChatService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_conversations.isEmpty) _error = e;
      });
    }
  }

  Future<void> _openNewChat() async {
    final opened = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PlayerChatContactsScreen()),
    );
    if (opened == true) await _load();
  }

  void _openThread(ChatConversation chat) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => DirectChatThreadScreen(
              conversationId: chat.conversationId,
              peerName: chat.displayName,
              peerRoleLabel: chat.roleLabel,
              peerAvatarUrl: chat.avatarUrl,
              role: DirectChatRole.player,
            ),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: canPop,
      showBottomNav: false,
      title: 'Chats',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: 'New chat',
          onPressed: _openNewChat,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      floatingActionButton: widget.embedded
          ? null
          : FloatingActionButton(
              backgroundColor: DarColors.accentRed,
              onPressed: _openNewChat,
              child: const Icon(Icons.add_comment_outlined),
            ),
      body: Column(
        children: [
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: PlayerHeroCard(
                motion: _motion,
                badge: 'DIRECT MESSAGES',
                title: 'Your conversations',
                subtitle: 'Private 1:1 with coaches, staff, and teammates',
                chips: [PlayerLiveChip(motion: _motion)],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: DarColors.accentRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your conversations',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Private 1:1 messages',
                          style: TextStyle(color: DarColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DarColors.accentRed),
      );
    }
    if (_error != null && _conversations.isEmpty) {
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
    if (_conversations.isEmpty) {
      return RefreshIndicator(
        color: DarColors.accentRed,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            PlayerEmptyState(
              icon: Icons.chat_outlined,
              message:
                  'No conversations yet. Tap + to message a coach or teammate.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          DarLayoutMetrics.of(context).horizontalPadding,
          12,
          DarLayoutMetrics.of(context).horizontalPadding,
          _bottomPadding,
        ),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          return ChatInboxTile(
            conversation: _conversations[i],
            onTap: () => _openThread(_conversations[i]),
          );
        },
      ),
    );
  }
}
