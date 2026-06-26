import 'package:dar_city_app/features/shared/json_parse.dart';

/// Contact row from GET /player/chat/contacts or GET /coach/chat/contacts.
class ChatContact {
  const ChatContact({
    required this.userId,
    required this.contactType,
    required this.name,
    this.roleLabel,
    this.avatarUrl,
    this.conversationId,
    this.hasExistingConversation = false,
  });

  final int userId;
  final String contactType;
  final String name;
  final String? roleLabel;
  final String? avatarUrl;
  final int? conversationId;
  final bool hasExistingConversation;

  String get subtitle =>
      roleLabel?.trim().isNotEmpty == true ? roleLabel!.trim() : contactType;

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    final explicitType = json['contact_type']?.toString();
    final isPlayer = explicitType == 'player' ||
        json['other_player_id'] != null ||
        json['other_player_name'] != null ||
        json['player_user_id'] != null ||
        (json['player_name'] != null && json['staff_name'] == null);

    if (isPlayer) {
      final userId = intFromJson(
        json['player_user_id'] ??
            json['user_id'] ??
            json['other_player_id'] ??
            json['player_id'],
      );
      return ChatContact(
        userId: userId,
        contactType: 'player',
        name: json['other_player_name']?.toString() ??
            json['player_name']?.toString() ??
            'Player',
        roleLabel: json['other_player_role_label']?.toString() ??
            json['player_role_label']?.toString(),
        avatarUrl: json['other_player_avatar_url']?.toString() ??
            json['player_avatar_url']?.toString(),
        conversationId: userId,
        hasExistingConversation:
            json['has_existing_conversation'] as bool? ?? false,
      );
    }

    final staffId = intFromJson(
      json['staff_id'] ?? json['staff_user_id'] ?? json['user_id'],
    );
    return ChatContact(
      userId: staffId,
      contactType: 'staff',
      name: json['staff_name']?.toString() ?? 'Staff',
      roleLabel: json['staff_role_label']?.toString(),
      avatarUrl: json['staff_avatar_url']?.toString(),
      conversationId: staffId,
      hasExistingConversation:
          json['has_existing_conversation'] as bool? ?? false,
    );
  }
}
