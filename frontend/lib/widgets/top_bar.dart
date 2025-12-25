import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';
import '../widgets/repo_card.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 56,
      titleSpacing: 12,

      title: const Text(
        'CareerCraft',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          fontSize: 20,
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          color: const Color(0xFF0F172A),
          onPressed: () => _openSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          color: const Color(0xFF0F172A),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Notifications'),
                content: const Text('No notifications received'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _RepoSearchSheet(),
    );
  }
}

/* ===========================
   SEARCH SHEET
=========================== */

class _RepoSearchSheet extends StatefulWidget {
  const _RepoSearchSheet();

  @override
  State<_RepoSearchSheet> createState() => _RepoSearchSheetState();
}

class _RepoSearchSheetState extends State<_RepoSearchSheet> {
  final TextEditingController _controller = TextEditingController();

  bool loading = false;
  List<dynamic> results = [];

  final List<String> recentSearches = [
    'portfolio',
    'flutter',
    'backend',
    'api',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearch);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos?name=$query'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (res.statusCode == 200) {
        results = jsonDecode(res.body);
      } else {
        results = [];
      }
    } catch (_) {
      results = [];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 🔍 Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search repositories...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.text.isEmpty
                  ? _buildRecentSearches()
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recent searches',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...recentSearches.map(
          (q) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () {
              _controller.text = q;
              _onSearch();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (results.isEmpty) {
      return const Center(child: Text('No repositories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final repo = results[index];

        final fullName = repo['full_name'] ?? '';
        final owner = fullName.contains('/')
            ? fullName.split('/')[0]
            : 'unknown';

        return RepoCard(
          repoId: repo['id'],
          name: repo['name'] ?? 'Unnamed Repo',
          description: repo['description'] ?? '',
          isPrivate: repo['private'] ?? false,
          owner: owner,
          htmlUrl: repo['html_url'],
          isFavourite: repo['favourite'] ?? false,
          language: repo['language'],
        );
      },
    );
  }
}
