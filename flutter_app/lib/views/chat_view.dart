// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../l10n/generated/app_localizations.dart';

class TtsSpeakingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setSpeaking(bool val) => state = val;
}

final ttsSpeakingProvider = NotifierProvider<TtsSpeakingNotifier, bool>(TtsSpeakingNotifier.new);

final ttsServiceProvider = Provider((ref) {
  return TtsService(onUpdate: (isSpeaking) {
    ref.read(ttsSpeakingProvider.notifier).setSpeaking(isSpeaking);
  });
});

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FocusNode _focusNode = FocusNode();
  bool _shouldAutoScroll = true;

  void _scrollToBottom() {
    if (_scrollController.hasClients && _shouldAutoScroll) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      // If we are within 100px of the bottom, enable auto-scroll
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;
      if (isAtBottom != _shouldAutoScroll) {
        setState(() {
          _shouldAutoScroll = isAtBottom;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_scrollListener);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Add a small delay for keyboard to appear and layout to adjust
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final ttsService = ref.watch(ttsServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    // Scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.chat,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: l10n.clear,
                    onPressed: () {
                      ref.read(chatProvider.notifier).clearMessages();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount:
                    chatState.messages.length + (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length) {
                    return _buildLoadingBubble(l10n);
                  }
                  final message = chatState.messages[index];
                  return _buildChatBubble(context, message, ttsService);
                },
              ),
            ),
            _buildInputArea(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context,
    ChatMessage message,
    TtsService tts,
  ) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(message.timestamp);
    final durationStr = message.duration != null
        ? " (${(message.duration!.inMilliseconds / 1000).toStringAsFixed(1)}s)"
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced from 8 to fit '1 empty line' gap logic
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: TextStyle(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.2, // Reduced from 1.3 for more compactness
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$timeStr$durationStr",
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isUser) ...[
            GestureDetector(
              onTap: () {
                final isSpeaking = ref.read(ttsSpeakingProvider);
                if (isSpeaking) {
                  tts.stop();
                } else {
                  final settings = ref.read(settingsProvider);
                  tts.speak(message.text, locale: settings.locale);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ref.watch(ttsSpeakingProvider) ? Icons.stop : Icons.volume_up,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.aiThinking,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (text) {
                    ref.read(chatProvider.notifier).sendMessage(text);
                    _controller.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  final text = _controller.text;
                  ref.read(chatProvider.notifier).sendMessage(text);
                  _controller.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

