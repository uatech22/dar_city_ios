import 'package:dar_city_app/config/api_config.dart';
import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/screens/coach_announcements_hub_screen.dart';
import 'package:dar_city_app/features/coach/screens/coach_chat_contacts_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_chat_service.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/chat_inbox_tile.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

class CoachChartHubScreen extends StatefulWidget {
  const CoachChartHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CoachChartHubScreen> createState() => _CoachChartHubScreenState();
}

class _CoachChartHubScreenState extends State<CoachChartHubScreen>
    with AutoRefreshStateMixin {
  bool _showAnnouncement = false;
  List<ChatConversation> _conversations = [];
  bool _loadingChats = true;
  Object? _chatError;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    startAutoRefresh(_loadConversations, interval: ApiConfig.refreshIntervalFast);
  }

  Future<void> _loadConversations() async {
    try {
      final list = await CoachChatService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loadingChats = false;
        _chatError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingChats = false;
        if (_conversations.isEmpty) _chatError = e;
      });
    }
  }

  Future<void> _openNewChat() async {
    final opened = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CoachChatContactsScreen()),
    );
    if (opened == true) await _loadConversations();
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
              role: DirectChatRole.coach,
            ),
          ),
        )
        .then((_) => _loadConversations());
  }

  double get _bottomPadding => widget.embedded ? 96 : 24;

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      showBack: !widget.embedded,
      showBottomNav: false,
      title: 'Team Chat',
      actions: [
        if (!_showAnnouncement)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Message player',
            onPressed: _openNewChat,
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: DarColors.cardBrown,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      label: 'Player Chat',
                      selected: !_showAnnouncement,
                      onTap: () => setState(() => _showAnnouncement = false),
                    ),
                  ),
                  Expanded(
                    child: _tabButton(
                      label: 'Announcements',
                      selected: _showAnnouncement,
                      onTap: () => setState(() => _showAnnouncement = true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _showAnnouncement
                ? CoachAnnouncementsHubScreen(scrollBottomPadding: _bottomPadding)
                : _buildConversationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_loadingChats && _conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DarColors.accentRed),
      );
    }
    if (_chatError != null && _conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: DarColors.accentRed, size: 40),
              const SizedBox(height: 12),
              Text(
                featureErrorMessage(_chatError),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadConversations,
                style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No conversations yet',
                style: TextStyle(color: DarColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openNewChat,
                style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Message a player'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: _loadConversations,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          DarLayoutMetrics.of(context).horizontalPadding,
          16,
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

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? DarColors.accentRed : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : DarColors.muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
