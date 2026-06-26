import 'package:dar_city_app/features/shared/models/chat_contact.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:dar_city_app/services/profile_service.dart';
import 'package:dar_city_app/services/session_manager.dart';

/// Hide self from chat pickers / inbox when backend returns a bad row.
class ChatListFilters {
  ChatListFilters._();

  static Future<int?> resolveAuthUserId() async {
    final cached = SessionManager().getUserId();
    if (cached != null) return cached;

    try {
      final profile = await ProfileService().getProfile();
      if (profile.id != null) {
        await SessionManager().saveUserId(profile.id);
      }
      return profile.id;
    } catch (_) {
      return null;
    }
  }

  static List<ChatContact> contactsWithoutSelf(
    List<ChatContact> contacts,
    int? authUserId,
  ) {
    if (authUserId == null) return contacts;
    return contacts.where((c) => c.userId != authUserId).toList();
  }

  static List<ChatConversation> conversationsWithoutSelf(
    List<ChatConversation> conversations,
    int? authUserId,
  ) {
    if (authUserId == null) return conversations;
    return conversations
        .where(
          (c) =>
              c.otherUserId != authUserId && c.conversationId != authUserId,
        )
        .toList();
  }
}
