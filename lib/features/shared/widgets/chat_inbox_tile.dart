import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:flutter/material.dart';

class ChatInboxTile extends StatelessWidget {
  const ChatInboxTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  String _formatTimestamp(String raw) {
    if (raw.length >= 16 && raw.contains('T')) {
      return raw.substring(11, 16);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              DarPlayerAvatar(
                name: conversation.displayName,
                imageUrl: conversation.avatarUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (conversation.subtitle.isNotEmpty)
                      Text(
                        conversation.subtitle,
                        style: TextStyle(color: DarColors.muted, fontSize: 11),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.preview,
                      style: TextStyle(
                        color: DarColors.mutedPink,
                        fontSize: 13,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (conversation.lastMessageAt.isNotEmpty)
                    Text(
                      _formatTimestamp(conversation.lastMessageAt),
                      style: TextStyle(color: DarColors.mutedPink, fontSize: 12),
                    ),
                  if (conversation.unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: DarColors.accentRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
