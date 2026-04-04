import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../state/app_state.dart';
import '../widgets/common/state_views.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/loading/app_skeleton.dart';

class RepoChatScreen extends StatefulWidget {
  final String owner;
  final String repo;

  const RepoChatScreen({super.key, required this.owner, required this.repo});

  @override
  State<RepoChatScreen> createState() => _RepoChatScreenState();
}

class _RepoChatScreenState extends State<RepoChatScreen> {
  static const int _maxScrollRetries = 10;
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 320);
  static const Duration _scrollButtonHideDelay = Duration(seconds: 4);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool loading = true;
  bool sending = false;
  bool _showScrollToBottom = false;
  String? sessionId;
  String? error;
  Timer? _scrollButtonHideTimer;

  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _initChat();
  }

  @override
  void dispose() {
    _scrollButtonHideTimer?.cancel();
    _controller.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/chat/session');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'repoOwner': widget.owner, 'repoName': widget.repo}),
      );

      final data = jsonDecode(response.body);
      sessionId = data['_id'];

      await _loadHistory();
    } catch (_) {
      error = 'Could not start chat session';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    if (sessionId == null) return;

    final uri = Uri.parse('${AppConfig.backendBaseUrl}/chat/history/$sessionId');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
    );

    final List list = jsonDecode(response.body);

    if (!mounted) return;

    setState(() {
      messages
        ..clear()
        ..addAll(
          list.map((m) => ChatMessage(role: m['role'], content: m['content'])),
        );
    });

    _scrollToBottom(jump: true);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || sending || sessionId == null) return;

    setState(() {
      sending = true;
      messages.add(ChatMessage(role: 'user', content: text));
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/chat/message');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'sessionId': sessionId, 'message': text}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          messages.add(ChatMessage(role: 'assistant', content: data['reply']));
          sending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => sending = false);
      }
    }

    _scrollToBottom();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final shouldShow = !_isAtBottom;
    if (shouldShow != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = shouldShow);
    }

    if (shouldShow) {
      _scheduleScrollButtonHide();
    } else {
      _cancelScrollButtonHide();
    }
  }

  bool get _isAtBottom {
    if (!_scrollController.hasClients) return true;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    return (maxExtent - currentOffset).abs() < 32;
  }

  void _scheduleScrollButtonHide() {
    _scrollButtonHideTimer?.cancel();
    _scrollButtonHideTimer = Timer(_scrollButtonHideDelay, () {
      if (!mounted || _isAtBottom || !_showScrollToBottom) return;
      setState(() => _showScrollToBottom = false);
    });
  }

  void _cancelScrollButtonHide() {
    _scrollButtonHideTimer?.cancel();
    _scrollButtonHideTimer = null;
  }

  void _scrollToBottom({bool jump = false}) {
    _scrollToBottomAfterFrame(jump: jump);
  }

  void _scrollToBottomAfterFrame({required bool jump, int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (!_scrollController.hasClients) {
        if (attempt >= _maxScrollRetries) return;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        _scrollToBottomAfterFrame(jump: jump, attempt: attempt + 1);
        return;
      }

      final targetOffset = _scrollController.position.maxScrollExtent;

      if (jump) {
        _scrollController.jumpTo(targetOffset);
      } else {
        await _scrollController.animateTo(
          targetOffset,
          duration: _scrollAnimationDuration,
          curve: Curves.easeOutCubic,
        );
      }

      if (mounted && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.86),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.repo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.owner}/${widget.repo}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
              isDark
                  ? colorScheme.surfaceContainerLow
                  : colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: loading
            ? const ChatScreenSkeleton()
            : (error != null)
            ? AppErrorState(message: error!, onRetry: _initChat)
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.separated(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            itemCount: messages.length + (sending ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return _TypingIndicatorBubble(
                                  colorScheme: colorScheme,
                                );
                              }

                              final msg = messages[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: msg.role == 'user' ? 40 : 4,
                                  right: msg.role == 'user' ? 4 : 40,
                                ),
                                child: ChatBubble(
                                  message: msg.content,
                                  isUser: msg.role == 'user',
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 18,
                            bottom: 12,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 220),
                              offset: _showScrollToBottom
                                  ? Offset.zero
                                  : const Offset(0, 0.4),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: _showScrollToBottom ? 1 : 0,
                                child: IgnorePointer(
                                  ignoring: !_showScrollToBottom,
                                  child: _ScrollToBottomButton(
                                    onPressed: _scrollToBottom,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Composer(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      sending: sending,
                      onSend: _sendMessage,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  final ColorScheme colorScheme;

  const _TypingIndicatorBubble({required this.colorScheme});

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final value = (_controller.value - index * 0.18) % 1.0;
                    final opacity = (0.35 + (value < 0.5 ? value : 1 - value))
                        .clamp(0.25, 1.0);

                    return Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: opacity.toDouble(),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -6),
              color: colorScheme.shadow.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Ask about this repository...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.auto_awesome_outlined,
                      color: colorScheme.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: sending
                      ? [
                          colorScheme.outline,
                          colorScheme.outline.withValues(alpha: 0.85),
                        ]
                      : [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.arrow_upward_rounded, color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ScrollToBottomButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}
