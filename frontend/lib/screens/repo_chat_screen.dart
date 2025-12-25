import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

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
  final List<_ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  // ================= INIT CHAT =================

  Future<void> _initChat() async {
    debugPrint('========== INIT CHAT ==========');
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/chat/session');

      debugPrint('POST $uri');
      debugPrint('JWT: ${AppState.jwt}');
      debugPrint('Repo: ${widget.owner}/${widget.repo}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'repoOwner': widget.owner, 'repoName': widget.repo}),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Init failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body);

      if (data['_id'] == null) {
        throw Exception('Session ID missing in response');
      }

      sessionId = data['_id'];
      debugPrint('SESSION ID: $sessionId');

      await _loadHistory();
    } catch (e, stack) {
      debugPrint('INIT ERROR: $e');
      debugPrint('STACK TRACE:\n$stack');

      _showError('Failed to initialize chat');
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= LOAD HISTORY =================

  Future<void> _loadHistory() async {
    debugPrint('========== LOAD HISTORY ==========');

    try {
      final uri = Uri.parse(
        '${AppConfig.backendBaseUrl}/chat/history/$sessionId',
      );

      debugPrint('GET $uri');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode != 200) return;

      final List list = jsonDecode(response.body);

      setState(() {
        messages.clear();
        messages.addAll(
          list.map((m) => _ChatMessage(role: m['role'], content: m['content'])),
        );
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('LOAD HISTORY ERROR: $e');
    }
  }

  // ================= SEND MESSAGE =================

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || sending) return;

    debugPrint('========== SEND MESSAGE ==========');
    debugPrint('SESSION: $sessionId');
    debugPrint('MESSAGE: $text');

    setState(() {
      sending = true;
      messages.add(_ChatMessage(role: 'user', content: text));
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/chat/message');

      debugPrint('POST $uri');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'sessionId': sessionId, 'message': text}),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Message failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body);

      if (!data.containsKey('reply')) {
        throw Exception('Invalid response: missing reply');
      }

      setState(() {
        messages.add(_ChatMessage(role: 'assistant', content: data['reply']));
      });
    } catch (e, stack) {
      debugPrint('SEND ERROR: $e');
      debugPrint('STACK TRACE:\n$stack');

      _showError('Failed to send message');
    } finally {
      setState(() => sending = false);
      _scrollToBottom();
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.repo} Assistant')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _chatList()),
                _inputBar(),
              ],
            ),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final isUser = msg.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF4F46E5) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.content,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ask about this repository...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: sending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ================= MODEL =================

class _ChatMessage {
  final String role;
  final String content;

  _ChatMessage({required this.role, required this.content});
}
