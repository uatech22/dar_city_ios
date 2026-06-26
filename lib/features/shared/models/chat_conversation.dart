import 'package:dar_city_app/features/shared/json_parse.dart';

/// Inbox row for player or coach 1:1 chat lists.
class ChatConversation {
  const ChatConversation({
    required this.conversationId,
    required this.otherUserId,
    required this.contactType,
    required this.displayName,
    this.roleLabel,
    this.avatarUrl,
    this.lastMessage = '',
    this.lastMessageAt = '',
    this.unreadCount = 0,
  });

  final int conversationId;
  final int otherUserId;
  final String contactType;
  final String displayName;
  final String? roleLabel;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;

  String get preview =>
      lastMessage.trim().isNotEmpty ? lastMessage : 'No messages yet';

  String get subtitle =>
      roleLabel?.trim().isNotEmpty == true ? roleLabel!.trim() : contactType;

  /// Coach inbox compatibility.
  int get playerId => otherUserId;

  String get playerName => displayName;

  String? get playerAvatarUrl => avatarUrl;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final contactType = json['contact_type']?.toString();
    final playerUserId = intFromJsonNullable(
      json['player_user_id'] ?? json['player_id'] ?? json['other_player_id'],
    );
    final staffUserId = intFromJsonNullable(
      json['staff_user_id'] ?? json['staff_id'],
    );
    final hasStaffName = json['staff_name'] != null;
    final hasPlayerName = json['player_name'] != null;
    final hasOtherPlayerName = json['other_player_name'] != null;

    // Player app — inbox row with a staff member (API includes own player_* too).
    if (contactType == 'staff' ||
        (hasStaffName && contactType != 'player')) {
      final staffId = intFromJson(
        json['staff_user_id'] ??
            json['staff_id'] ??
            json['conversation_id'],
      );
      return ChatConversation(
        conversationId: staffId,
        otherUserId: staffId,
        contactType: 'staff',
        displayName: json['staff_name']?.toString() ?? 'Staff',
        roleLabel: json['staff_role_label']?.toString(),
        avatarUrl: json['staff_avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: json['last_message_at']?.toString() ?? '',
        unreadCount: intFromJson(json['unread_count'] ?? 0),
      );
    }

    // Coach app — inbox row with a player (row includes staff_* + player_*).
    if (contactType == 'player' && hasStaffName && hasPlayerName) {
      final playerId = intFromJson(
        json['player_user_id'] ?? json['player_id'] ?? json['other_player_id'],
      );
      return ChatConversation(
        conversationId: playerId,
        otherUserId: playerId,
        contactType: 'player',
        displayName: json['player_name']?.toString() ?? 'Player',
        roleLabel: json['player_role_label']?.toString() ??
            json['other_player_role_label']?.toString(),
        avatarUrl: json['player_avatar_url']?.toString() ??
            json['other_player_avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: json['last_message_at']?.toString() ?? '',
        unreadCount: intFromJson(json['unread_count'] ?? 0),
      );
    }

    // Player app — teammate row (no staff on row).
    if (hasOtherPlayerName && !hasStaffName && playerUserId != null) {
      return ChatConversation(
        conversationId: playerUserId,
        otherUserId: playerUserId,
        contactType: 'player',
        displayName: json['other_player_name']?.toString() ?? 'Player',
        roleLabel: json['other_player_role_label']?.toString(),
        avatarUrl: json['other_player_avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: json['last_message_at']?.toString() ?? '',
        unreadCount: intFromJson(json['unread_count'] ?? 0),
      );
    }

    // Coach app fallback — player counterparty only.
    if (hasPlayerName && playerUserId != null) {
      return ChatConversation(
        conversationId: playerUserId,
        otherUserId: playerUserId,
        contactType: 'player',
        displayName: json['player_name']?.toString() ?? 'Player',
        roleLabel: json['player_role_label']?.toString(),
        avatarUrl: json['player_avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: json['last_message_at']?.toString() ?? '',
        unreadCount: intFromJson(json['unread_count'] ?? 0),
      );
    }

    if (staffUserId != null) {
      return ChatConversation(
        conversationId: staffUserId,
        otherUserId: staffUserId,
        contactType: 'staff',
        displayName: json['staff_name']?.toString() ?? 'Staff',
        roleLabel: json['staff_role_label']?.toString(),
        avatarUrl: json['staff_avatar_url']?.toString(),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt: json['last_message_at']?.toString() ?? '',
        unreadCount: intFromJson(json['unread_count'] ?? 0),
      );
    }

    throw FormatException('Unrecognized chat conversation row: $json');
  }
}
