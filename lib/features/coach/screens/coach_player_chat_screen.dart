import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:flutter/material.dart';

/// Legacy entry — opens 1:1 thread by player user id (conversationId).
class CoachPlayerChatScreen extends StatelessWidget {
  const CoachPlayerChatScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    this.playerAvatarUrl,
    this.conversationId,
  });

  final int playerId;
  final String playerName;
  final String? playerAvatarUrl;
  final int? conversationId;

  @override
  Widget build(BuildContext context) {
    return DirectChatThreadScreen(
      conversationId: conversationId ?? playerId,
      peerName: playerName,
      peerAvatarUrl: playerAvatarUrl,
      role: DirectChatRole.coach,
    );
  }
}
