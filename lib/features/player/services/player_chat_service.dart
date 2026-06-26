import 'dart:convert';

import 'package:dar_city_app/features/player/models/chat_message.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/chat_list_filters.dart';
import 'package:dar_city_app/features/shared/models/chat_contact.dart';
import 'package:dar_city_app/features/shared/models/chat_conversation.dart';
import 'package:flutter/foundation.dart';

class PlayerChatService {
  static const _tag = 'PlayerChat';

  static void _log(String message) {
    if (kDebugMode) debugPrint('[$_tag] $message');
  }

  static Future<List<ChatConversation>> fetchConversations() async {
    const path = '/player/chat/conversations';
    final list = await FeatureApiClient.getJsonList(path);
    final authUserId = await ChatListFilters.resolveAuthUserId();
    final conversations = <ChatConversation>[];
    for (final item in list) {
      try {
        conversations.add(
          ChatConversation.fromJson(item as Map<String, dynamic>),
        );
      } catch (e) {
        _log('skip bad inbox row: $e');
      }
    }
    final filtered =
        ChatListFilters.conversationsWithoutSelf(conversations, authUserId);
    _log('GET $path → ${filtered.length} conversation(s)');
    if (kDebugMode && list.isNotEmpty) {
      _log('inbox sample: ${jsonEncode(list.first)}');
    }
    if (kDebugMode &&
        authUserId != null &&
        filtered.length < conversations.length) {
      _log(
        'filtered ${conversations.length - filtered.length} self thread(s) '
        '(authUserId=$authUserId)',
      );
    }
    return filtered;
  }

  static Future<List<ChatContact>> fetchContacts() async {
    const path = '/player/chat/contacts';
    final list = await FeatureApiClient.getJsonList(path);
    final authUserId = await ChatListFilters.resolveAuthUserId();
    final contacts = list
        .map((e) => ChatContact.fromJson(e as Map<String, dynamic>))
        .toList();
    final filtered = ChatListFilters.contactsWithoutSelf(contacts, authUserId);
    _log('GET $path → ${filtered.length} contact(s)');
    return filtered;
  }

  static Future<OpenChatConversationResult> openConversation({
    int? staffId,
    int? playerId,
  }) async {
    const path = '/player/chat/conversations';
    final body = OpenChatConversationPayload(staffId: staffId, playerId: playerId);
    _log('POST $path ${jsonEncode(body.toJson())}');
    final json = await FeatureApiClient.postJson(path, body.toJson());
    return OpenChatConversationResult.fromJson(json);
  }

  static Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final path = '/player/chat/conversations/$conversationId/messages';
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
    final path = '/player/chat/conversations/$conversationId/messages';
    _log('POST $path ${jsonEncode(payload.toJson())}');
    final json = await FeatureApiClient.postJson(path, payload.toJson());
    return ChatMessage.fromJson(json);
  }

  static Future<void> markRead(int conversationId, {int? lastReadMessageId}) async {
    final path = '/player/chat/conversations/$conversationId/read';
    final body = <String, dynamic>{};
    if (lastReadMessageId != null) {
      body['last_read_message_id'] = lastReadMessageId;
    }
    await FeatureApiClient.postJson(path, body);
  }
}
