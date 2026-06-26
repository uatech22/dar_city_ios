import 'package:dar_city_app/features/shared/json_parse.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.sentAt,
    required this.isMine,
    this.conversationId,
    this.senderRoleLabel,
    this.senderAvatarUrl,
    this.reactions,
    this.voiceMessageUrl,
    this.isSeen,
  });

  final int id;
  final int? conversationId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String? senderRoleLabel;
  final String? senderAvatarUrl;
  final String body;
  final String sentAt;
  final bool isMine;
  final Map<String, int>? reactions;
  final String? voiceMessageUrl;
  final bool? isSeen;

  String get senderLine {
    final role = senderRoleLabel?.trim();
    if (role != null && role.isNotEmpty) {
      return '$senderName · $role';
    }
    return senderName;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Map<String, int>? reactions;
    if (json['reactions'] is Map) {
      reactions = (json['reactions'] as Map).map(
        (k, v) => MapEntry(k.toString(), intFromJson(v)),
      );
    }
    final senderRole = json['sender_role']?.toString() ?? 'staff';
    return ChatMessage(
      id: intFromJson(json['id']),
      conversationId: intFromJsonNullable(json['conversation_id']),
      senderId: intFromJson(json['sender_id']),
      senderName: json['sender_name']?.toString() ?? '',
      senderRole: senderRole,
      senderRoleLabel: json['sender_role_label']?.toString(),
      senderAvatarUrl: json['sender_avatar_url']?.toString(),
      body: json['body']?.toString() ?? '',
      sentAt: json['sent_at']?.toString() ?? '',
      isMine: json['is_mine'] as bool? ??
          senderRole.toLowerCase() == 'player',
      reactions: reactions,
      voiceMessageUrl: json['voice_message_url'] as String?,
      isSeen: json['is_seen'] as bool?,
    );
  }

  ChatMessage copyWith({bool? isMine}) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      senderRoleLabel: senderRoleLabel,
      senderAvatarUrl: senderAvatarUrl,
      body: body,
      sentAt: sentAt,
      isMine: isMine ?? this.isMine,
      reactions: reactions,
      voiceMessageUrl: voiceMessageUrl,
      isSeen: isSeen,
    );
  }
}

class SendChatMessagePayload {
  const SendChatMessagePayload({
    required this.body,
    this.voiceMessageUrl,
  });

  final String body;
  final String? voiceMessageUrl;

  Map<String, dynamic> toJson() => {
        'body': body,
        if (voiceMessageUrl != null) 'voice_message_url': voiceMessageUrl,
      };
}

class OpenChatConversationPayload {
  const OpenChatConversationPayload({
    this.staffId,
    this.playerId,
  });

  final int? staffId;
  final int? playerId;

  Map<String, dynamic> toJson() {
    if (staffId != null) return {'staff_id': staffId};
    if (playerId != null) return {'player_id': playerId};
    return {};
  }
}

class OpenChatConversationResult {
  const OpenChatConversationResult({
    required this.conversationId,
    required this.otherUserId,
    required this.displayName,
    this.roleLabel,
    this.avatarUrl,
  });

  final int conversationId;
  final int otherUserId;
  final String displayName;
  final String? roleLabel;
  final String? avatarUrl;

  factory OpenChatConversationResult.fromJson(Map<String, dynamic> json) {
    final playerUserId = intFromJsonNullable(
      json['player_user_id'] ?? json['player_id'] ?? json['other_player_id'],
    );
    final staffUserId = intFromJsonNullable(
      json['staff_id'] ?? json['staff_user_id'],
    );
    // Synthetic API keys threads by the other participant's users.id.
    final threadId = playerUserId ?? staffUserId;
    final otherUserId =
        threadId ?? intFromJson(json['conversation_id']);

    final displayName = _peerDisplayName(json, otherUserId, playerUserId, staffUserId);
    final roleLabel = _peerRoleLabel(json, otherUserId, playerUserId, staffUserId);
    final avatarUrl = _peerAvatarUrl(json, otherUserId, playerUserId, staffUserId);

    return OpenChatConversationResult(
      conversationId: threadId ?? otherUserId,
      otherUserId: otherUserId,
      displayName: displayName,
      roleLabel: roleLabel,
      avatarUrl: avatarUrl,
    );
  }

  static String _peerDisplayName(
    Map<String, dynamic> json,
    int otherUserId,
    int? playerUserId,
    int? staffUserId,
  ) {
    if (playerUserId != null && otherUserId == playerUserId) {
      return json['player_name']?.toString() ??
          json['other_player_name']?.toString() ??
          'Player';
    }
    if (staffUserId != null && otherUserId == staffUserId) {
      return json['staff_name']?.toString() ?? 'Staff';
    }
    return json['player_name']?.toString() ??
        json['other_player_name']?.toString() ??
        json['staff_name']?.toString() ??
        'Chat';
  }

  static String? _peerRoleLabel(
    Map<String, dynamic> json,
    int otherUserId,
    int? playerUserId,
    int? staffUserId,
  ) {
    if (playerUserId != null && otherUserId == playerUserId) {
      return json['player_role_label']?.toString() ??
          json['other_player_role_label']?.toString();
    }
    if (staffUserId != null && otherUserId == staffUserId) {
      return json['staff_role_label']?.toString();
    }
    return json['player_role_label']?.toString() ??
        json['other_player_role_label']?.toString() ??
        json['staff_role_label']?.toString();
  }

  static String? _peerAvatarUrl(
    Map<String, dynamic> json,
    int otherUserId,
    int? playerUserId,
    int? staffUserId,
  ) {
    if (playerUserId != null && otherUserId == playerUserId) {
      return json['player_avatar_url']?.toString() ??
          json['other_player_avatar_url']?.toString();
    }
    if (staffUserId != null && otherUserId == staffUserId) {
      return json['staff_avatar_url']?.toString();
    }
    return json['player_avatar_url']?.toString() ??
        json['other_player_avatar_url']?.toString() ??
        json['staff_avatar_url']?.toString();
  }
}
