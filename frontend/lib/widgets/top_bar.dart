import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/interview_review_screen.dart';
import '../screens/repo_chat_screen.dart';
import '../screens/settings_screen.dart';
import '../services/search_service.dart';
import '../state/theme_controller.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeController themeController;

  const TopBar({super.key, required this.themeController});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0.5,
      toolbarHeight: 56,
      titleSpacing: 12,
      title: Text(
        'CareerCraft',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () => _openSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(themeController: themeController),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _GlobalSearchSheet(),
    );
  }
}

class _GlobalSearchSheet extends StatefulWidget {
  const _GlobalSearchSheet();

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String _activeQuery = '';
  List<dynamic> _repos = [];
  List<dynamic> _chats = [];
  List<dynamic> _interviews = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final query = _controller.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() {
        _activeQuery = '';
        _repos = [];
        _chats = [];
        _interviews = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _activeQuery = query;
    });

    try {
      final result = await SearchService.globalSearch(query);
      if (!mounted) return;
      setState(() {
        _repos = List<dynamic>.from(result['repos'] ?? const []);
        _chats = List<dynamic>.from(result['chats'] ?? const []);
        _interviews = List<dynamic>.from(result['interviews'] ?? const []);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _repos = [];
        _chats = [];
        _interviews = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _repos.isNotEmpty || _chats.isNotEmpty || _interviews.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search repos, chats, interviews...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_activeQuery.isEmpty)
                  ? const Center(child: Text('Start typing to search'))
                  : (!hasResults)
                  ? const Center(child: Text('No results found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                      children: [
                        if (_repos.isNotEmpty) ...[
                          _sectionTitle(context, 'Repositories'),
                          ..._repos.map(
                            (repo) => _searchTile(
                              context: context,
                              icon: Icons.folder_open_rounded,
                              title: repo['name'] ?? 'Unnamed Repo',
                              subtitle: repo['description'] ?? 'Repository',
                              query: _activeQuery,
                              onTap: () {
                                final fullName =
                                    (repo['full_name'] ?? '').toString();
                                final owner = fullName.contains('/')
                                    ? fullName.split('/').first
                                    : 'unknown';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RepoChatScreen(
                                      owner: owner,
                                      repo: repo['name'] ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_chats.isNotEmpty) ...[
                          _sectionTitle(context, 'Chats'),
                          ..._chats.map((chat) => _searchTile(
                                context: context,
                                icon: Icons.chat_bubble_outline,
                                title: chat['repoName'] ?? 'Repo chat',
                                subtitle: chat['title'] ?? 'Repository assistant',
                                query: _activeQuery,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RepoChatScreen(
                                        owner: chat['repoOwner'] ?? 'unknown',
                                        repo: chat['repoName'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              )),
                          const SizedBox(height: 8),
                        ],
                        if (_interviews.isNotEmpty) ...[
                          _sectionTitle(context, 'Interview History'),
                          ..._interviews.map((interview) {
                            final score = interview['score'];
                            final subtitle = score != null
                                ? 'Score: $score · ${interview['difficulty']}'
                                : 'Completed interview';
                            return _searchTile(
                              context: context,
                              icon: Icons.mic_none_rounded,
                              title: 'Interview (${interview['difficulty']})',
                              subtitle: subtitle,
                              query: _activeQuery,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InterviewReviewScreen(
                                      sessionId: interview['id'].toString(),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _searchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String query,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: _highlightedText(context, title, query, isTitle: true),
        subtitle: _highlightedText(context, subtitle, query),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _highlightedText(
    BuildContext context,
    String text,
    String query, {
    bool isTitle = false,
  }) {
    final theme = Theme.of(context);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final index = lower.indexOf(q);

    if (q.isEmpty || index < 0) {
      return Text(
        text,
        style: isTitle ? theme.textTheme.titleSmall : theme.textTheme.bodySmall,
      );
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + q.length);
    final after = text.substring(index + q.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
      style: isTitle ? theme.textTheme.titleSmall : theme.textTheme.bodySmall,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
