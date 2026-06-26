import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/services/coach_chat_service.dart';
import 'package:dar_city_app/features/player/models/chat_message.dart';
import 'package:dar_city_app/features/shared/models/chat_contact.dart';
import 'package:dar_city_app/features/shared/screens/direct_chat_thread_screen.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CoachChatContactsScreen extends StatefulWidget {
  const CoachChatContactsScreen({super.key});

  @override
  State<CoachChatContactsScreen> createState() => _CoachChatContactsScreenState();
}

class _CoachChatContactsScreenState extends State<CoachChatContactsScreen> {
  List<ChatContact> _contacts = [];
  bool _loading = true;
  Object? _error;
  int? _openingUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await CoachChatService.fetchContacts();
      if (!mounted) return;
      setState(() {
        _contacts = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_contacts.isEmpty) _error = e;
      });
    }
  }

  Future<void> _openContact(ChatContact contact) async {
    if (_openingUserId != null) return;
    if (contact.userId <= 0) {
      if (mounted) {
        showFeatureSnackBar(
          context,
          'Could not open chat — invalid player id.',
          isError: true,
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[CoachChat] tap contact userId=${contact.userId} '
        'name=${contact.name} existing=${contact.hasExistingConversation}',
      );
    }

    setState(() => _openingUserId = contact.userId);
    try {
      final OpenChatConversationResult result;
      if (contact.hasExistingConversation && contact.conversationId != null) {
        result = OpenChatConversationResult(
          conversationId: contact.conversationId!,
          otherUserId: contact.userId,
          displayName: contact.name,
          roleLabel: contact.roleLabel,
          avatarUrl: contact.avatarUrl,
        );
      } else {
        result = await CoachChatService.openConversation(contact.userId);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DirectChatThreadScreen(
            conversationId: result.conversationId,
            peerName: contact.name,
            peerRoleLabel: contact.roleLabel ?? result.roleLabel,
            peerAvatarUrl: contact.avatarUrl ?? result.avatarUrl,
            role: DirectChatRole.coach,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (kDebugMode) debugPrint('[CoachChat] open contact failed: $e');
      if (mounted) {
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarScaffold(
      showBack: true,
      showBottomNav: false,
      title: 'Message player',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DarColors.accentRed),
      );
    }
    if (_error != null && _contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                featureErrorMessage(_error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Text('No players available', style: TextStyle(color: DarColors.muted)),
      );
    }

    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          DarLayoutMetrics.of(context).horizontalPadding,
          16,
          DarLayoutMetrics.of(context).horizontalPadding,
          24,
        ),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final contact = _contacts[i];
          final busy = _openingUserId == contact.userId;
          return Material(
            color: DarColors.cardBrown,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: busy ? null : () => _openContact(contact),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    DarPlayerAvatar(
                      name: contact.name,
                      imageUrl: contact.avatarUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            contact.subtitle,
                            style: TextStyle(color: DarColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.chevron_right, color: DarColors.muted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
