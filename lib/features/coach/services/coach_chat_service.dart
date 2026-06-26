import 'dart:convert';

import 'package:dar_city_app/features/player/models/chat_message.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/chat_list_filters.dart';
import 'package:dar_city_app/features/shared/models/chat_contact.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:flutter/foundation.dart';

class CoachChatService {
  static const _tag = 'CoachChat';

  static void _log(String message) {
    if (kDebugMode) debugPrint('[$_tag] $message');
  }

  static Future<List<ChatContact>> fetchContacts() async {
    const path = '/coach/chat/contacts';
    final list = await FeatureApiClient.getJsonList(path);
    final authUserId = await ChatListFilters.resolveAuthUserId();
    final contacts = list
        .map((e) => ChatContact.fromJson(e as Map<String, dynamic>))
        .toList();
    final filtered = ChatListFilters.contactsWithoutSelf(contacts, authUserId);
    _log('GET $path → ${filtered.length} contact(s)');
    if (kDebugMode && list.isNotEmpty) {
      _log('contact sample: ${jsonEncode(list.first)}');
    }
    if (kDebugMode && authUserId != null && filtered.length < contacts.length) {
      _log('filtered ${contacts.length - filtered.length} self contact(s)');
    }
    return filtered;
  }

  static Future<List<ChatConversation>> fetchConversations() async {
    const path = '/coach/chat/conversations';
    final list = await FeatureApiClient.getJsonList(path);
    final authUserId = await ChatListFilters.resolveAuthUserId();
    final conversations = list
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    final filtered =
        ChatListFilters.conversationsWithoutSelf(conversations, authUserId);
    _log('GET $path → ${filtered.length} conversation(s)');
    if (kDebugMode && list.isNotEmpty) {
      _log('inbox sample: ${jsonEncode(list.first)}');
    }
    if (kDebugMode && authUserId != null && filtered.length < conversations.length) {
      _log('filtered ${conversations.length - filtered.length} self thread(s)');
    }
    return filtered;
  }

  static Future<OpenChatConversationResult> openConversation(int playerUserId) async {
    const path = '/coach/chat/conversations';
    final body = {'player_id': playerUserId};
    _log('POST $path ${jsonEncode(body)}');
    try {
      final json = await FeatureApiClient.postJson(path, body);
      final result = OpenChatConversationResult.fromJson(json);
      _log(
        'POST $path → OK threadId=${result.conversationId} '
        '(raw conversation_id=${json['conversation_id']})',
      );
      return result;
    } catch (e) {
      _log('POST $path → FAILED: $e');
      rethrow;
    }
  }

  static Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final path = '/coach/chat/conversations/$conversationId/messages';
    final list = await FeatureApiClient.getJsonList(path);
    _log('GET $path → ${list.length} message(s)');
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ChatMessage> sendMessage(
    int conversationId,
    SendChatMessagePayload payload,
  ) async {
    final path = '/coach/chat/conversations/$conversationId/messages';
    _log('POST $path ${jsonEncode(payload.toJson())}');
    final json = await FeatureApiClient.postJson(path, payload.toJson());
    return ChatMessage.fromJson(json);
  }

  static Future<void> markRead(int conversationId, {int? lastReadMessageId}) async {
    final path = '/coach/chat/conversations/$conversationId/read';
    final body = <String, dynamic>{};
    if (lastReadMessageId != null) {
      body['last_read_message_id'] = lastReadMessageId;
    }
    await FeatureApiClient.postJson(path, body);
  }
}
