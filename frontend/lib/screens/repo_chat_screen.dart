import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class RepoChatScreen extends StatefulWidget {
  final String owner;
  final String repo;

  const RepoChatScreen({super.key, required this.owner, required this.repo});

  @override
  State<RepoChatScreen> createState() => _RepoChatScreenState();
}

class _RepoChatScreenState extends State<RepoChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool loading = true;
  bool sending = false;
  String? sessionId;

  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------
  // INIT CHAT SESSION
  // ----------------------------
  Future<void> _initChat() async {
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
    } catch (e) {
      debugPrint('🚨🚨🚨🚨🚨🚨Init chat error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ----------------------------
  // LOAD CHAT HISTORY
  // ----------------------------
  Future<void> _loadHistory() async {
    if (sessionId == null) return;

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/chat/history/$sessionId',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
    );

    final List list = jsonDecode(response.body);

    messages
      ..clear()
      ..addAll(
        list.map((m) => ChatMessage(role: m['role'], content: m['content'])),
      );

    _scrollToBottom(jump: true);
  }

  // ----------------------------
  // SEND MESSAGE
  // ----------------------------
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
    } catch (e) {
      debugPrint('🚨🚨🚨🚨🚨🚨 Send message failed! Error: $e');
      if (mounted) setState(() => sending = false);
    }

    _scrollToBottom();
  }

  // ----------------------------
  // SCROLL HANDLING
  // ----------------------------
  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position.maxScrollExtent;

      if (jump) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.repo} Assistant'), elevation: 0.5),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// CHAT LIST
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final msg = messages[index];
                      final isUser = msg.role == 'user';

                      return Padding(
                        padding: EdgeInsets.only(
                          left: isUser ? 56 : 8,
                          right: isUser ? 8 : 56,
                        ),
                        child: ChatBubble(message: msg.content, isUser: isUser),
                      );
                    },
                  ),
                ),

                /// INPUT BAR
                ChatInputBar(
                  controller: _controller,
                  sending: sending,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }
}
