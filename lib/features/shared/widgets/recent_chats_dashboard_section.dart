import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/screens/coach_chart_hub_screen.dart';
import 'package:dar_city_app/features/coach/services/coach_chat_service.dart';
import 'package:dar_city_app/features/player/screens/player_chart_view_screen.dart';
import 'package:dar_city_app/features/player/services/player_chat_service.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/chat_inbox_tile.dart';
import 'package:flutter/material.dart';

/// Recent 1:1 chats for player or coach home dashboard.
class RecentChatsDashboardSection extends StatefulWidget {
  const RecentChatsDashboardSection({
    super.key,
    required this.role,
    this.maxItems = 3,
  });

  final DirectChatRole role;
  final int maxItems;

  @override
  State<RecentChatsDashboardSection> createState() =>
      _RecentChatsDashboardSectionState();
}

class _RecentChatsDashboardSectionState extends State<RecentChatsDashboardSection> {
  List<ChatConversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = widget.role == DirectChatRole.coach
          ? await CoachChatService.fetchConversations()
          : await PlayerChatService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list.take(widget.maxItems).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openSeeAll() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.role == DirectChatRole.coach
            ? const CoachChartHubScreen()
            : const PlayerChartViewScreen(),
      ),
    );
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
              role: widget.role,
            ),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DarColors.accentRed,
            ),
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: DarColors.accentRed, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Recent chats',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: _openSeeAll,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.role == DirectChatRole.coach
              ? 'Your latest player conversations'
              : 'Private messages with staff and teammates',
          style: TextStyle(color: DarColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ..._conversations.map(
          (chat) => ChatInboxTile(
            conversation: chat,
            onTap: () => _openThread(chat),
          ),
        ),
      ],
    );
  }
}
