import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';
import '../widgets/repo_card.dart';
import '../screens/repos_screen.dart';

class MyReposPreview extends StatefulWidget {
  const MyReposPreview({Key? key}) : super(key: key);

  @override
  State<MyReposPreview> createState() => _MyReposPreviewState();
}

class _MyReposPreviewState extends State<MyReposPreview> {
  static const int previewLimit = 3;

  bool loading = true;
  List<dynamic> repos = [];

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn) {
      fetchRepos();
    } else {
      loading = false;
    }
  }

  Future<void> fetchRepos() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (res.statusCode == 200) {
        repos = jsonDecode(res.body);
      }
    } catch (_) {}

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Text('Login to view repositories');
    }

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (repos.isEmpty) {
      return const Text('No repositories found');
    }

    final previewRepos = repos.take(previewLimit).toList();
    final hasMore = repos.length > previewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...previewRepos.map((repo) {
          final fullName = repo['full_name'] ?? '';
          final owner = fullName.contains('/')
              ? fullName.split('/').first
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
        }),

        if (hasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReposScreen()),
                );
              },
              child: const Text('Show all'),
            ),
          ),
      ],
    );
  }
}
