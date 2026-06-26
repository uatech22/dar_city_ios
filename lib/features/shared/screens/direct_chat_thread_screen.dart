import 'package:dar_city_app/config/api_config.dart';
import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_bottom_nav_bar.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/features/coach/services/coach_chat_service.dart';
import 'package:dar_city_app/features/player/models/chat_message.dart';
import 'package:dar_city_app/features/player/services/player_chat_service.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';
import 'package:flutter/material.dart';

enum DirectChatRole { player, coach }

/// 1:1 message thread — conversationId is the other party's users.id.
class DirectChatThreadScreen extends StatefulWidget {
  const DirectChatThreadScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.role,
    this.peerRoleLabel,
    this.peerAvatarUrl,
    this.embedded = false,
  });

  final int conversationId;
  final String peerName;
  final String? peerRoleLabel;
  final String? peerAvatarUrl;
  final DirectChatRole role;
  final bool embedded;

  @override
  State<DirectChatThreadScreen> createState() => _DirectChatThreadScreenState();
}

class _DirectChatThreadScreenState extends State<DirectChatThreadScreen>
    with AutoRefreshStateMixin, WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _composerFocusNode = FocusNode();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composerFocusNode.addListener(_onComposerFocusChanged);
    _loadMessages(markRead: true);
    startAutoRefresh(
      () => _loadMessages(markRead: false),
      interval: ApiConfig.refreshIntervalFast,
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_composerFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _onComposerFocusChanged() {
    if (_composerFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composerFocusNode.removeListener(_onComposerFocusChanged);
    _composerFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({required bool markRead}) async {
    try {
      final list = widget.role == DirectChatRole.player
          ? await PlayerChatService.fetchMessages(widget.conversationId)
          : await CoachChatService.fetchMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
        _error = null;
      });
      if (list.isNotEmpty) {
        _scrollToBottom();
      }
      if (markRead && list.isNotEmpty) {
        final lastId = list.last.id;
        await _markRead(lastId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_messages.isEmpty) _error = e;
      });
    }
  }

  Future<void> _markRead(int lastReadMessageId) async {
    try {
      if (widget.role == DirectChatRole.player) {
        await PlayerChatService.markRead(
          widget.conversationId,
          lastReadMessageId: lastReadMessageId,
        );
      } else {
        await CoachChatService.markRead(
          widget.conversationId,
          lastReadMessageId: lastReadMessageId,
        );
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final payload = SendChatMessagePayload(body: text);
      final sent = widget.role == DirectChatRole.player
          ? await PlayerChatService.sendMessage(widget.conversationId, payload)
          : await CoachChatService.sendMessage(widget.conversationId, payload);
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        final mine = sent.isMine ? sent : sent.copyWith(isMine: true);
        if (!_messages.any((m) => m.id == mine.id)) {
          _messages = [..._messages, mine];
        }
        _error = null;
      });
      _scrollToBottom();
      await _loadMessages(markRead: true);
    } on FeatureApiException catch (e) {
      if (mounted) {
        showFeatureSnackBar(context, featureErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(String iso) {
    if (iso.length >= 16) return iso.substring(11, 16);
    return iso;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.peerRoleLabel?.trim().isNotEmpty == true
        ? widget.peerRoleLabel!
        : 'Direct message';

    return DarScaffold(
      backgroundColor: DarColors.background,
      showBack: false,
      showBottomNav: false,
      resizeToAvoidBottomInset: true,
      responsiveBody: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildThreadHeader(context, subtitle),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: _buildMessageList(),
              ),
            ),
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadHeader(BuildContext context, String subtitle) {
    return Material(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
            DarPlayerAvatar(
              name: widget.peerName,
              imageUrl: widget.peerAvatarUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: DarColors.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final metrics = DarLayoutMetrics.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final shellClearance = widget.embedded &&
        !metrics.useNavigationRail &&
        !keyboardOpen;

    // Scaffold already shrinks for the keyboard — only pad for home indicator / tab bar.
    final bottomPadding = keyboardOpen
        ? 8.0
        : 8.0 +
            viewPadding.bottom +
            (shellClearance ? DarBottomNavBar.barHeight : 0.0);

    return Material(
      color: DarColors.background,
      elevation: keyboardOpen ? 0 : 8,
      shadowColor: Colors.black54,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.horizontalPadding,
          8,
          metrics.horizontalPadding,
          bottomPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: keyboardOpen ? 88 : 120,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: DarColors.maroonBubble,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _composerFocusNode,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    scrollPhysics: const ClampingScrollPhysics(),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: DarColors.muted),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: DarColors.accentRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DarColors.accentRed),
      );
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: DarColors.accentRed, size: 40),
              const SizedBox(height: 12),
              Text(
                featureErrorMessage(_error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadMessages(markRead: true),
                style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return RefreshIndicator(
        color: DarColors.accentRed,
        onRefresh: () => _loadMessages(markRead: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: Center(
                child: Text(
                  'No messages yet. Say hello!',
                  style: TextStyle(color: DarColors.muted),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: DarColors.accentRed,
      onRefresh: () => _loadMessages(markRead: true),
      child: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          DarLayoutMetrics.of(context).horizontalPadding,
          16,
          DarLayoutMetrics.of(context).horizontalPadding,
          16,
        ),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final msg = _messages[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: msg.isMine ? _outgoingBubble(msg) : _incomingBubble(msg),
          );
        },
      ),
    );
  }

  Widget _incomingBubble(ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${msg.senderLine} · ${_formatTime(msg.sentAt)}',
          style: const TextStyle(color: DarColors.mutedPink, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DarPlayerAvatar(
              name: msg.senderName,
              imageUrl: msg.senderAvatarUrl ?? widget.peerAvatarUrl,
              size: 32,
            ),
            const SizedBox(width: 8),
            Flexible(child: _bubbleContent(msg, incoming: true)),
          ],
        ),
      ],
    );
  }

  Widget _outgoingBubble(ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'You · ${_formatTime(msg.sentAt)}',
          style: const TextStyle(color: DarColors.mutedPink, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: _bubbleContent(msg, incoming: false)),
            const SizedBox(width: 8),
            DarPlayerAvatar(
              name: msg.senderName.isNotEmpty ? msg.senderName : 'You',
              imageUrl: msg.senderAvatarUrl,
              size: 32,
            ),
          ],
        ),
        if (msg.isMine) _deliveryStatus(msg),
      ],
    );
  }

  Widget _deliveryStatus(ChatMessage msg) {
    final seen = msg.isSeen == true;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            seen ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: seen ? const Color(0xFF7EC8FF) : DarColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            seen ? 'Seen' : 'Sent',
            style: TextStyle(
              color: seen ? const Color(0xFF7EC8FF) : DarColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleContent(ChatMessage msg, {required bool incoming}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: incoming ? DarColors.maroonBubble : DarColors.accentRedBright,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: incoming
              ? Colors.white.withValues(alpha: 0.06)
              : DarColors.accentRed.withValues(alpha: 0.35),
        ),
      ),
      child: Text(msg.body, style: const TextStyle(color: Colors.white)),
    );
  }
}
