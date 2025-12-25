import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/repo_card.dart';
import '../config/app_config.dart';

class ReposScreen extends StatefulWidget {
  const ReposScreen({Key? key}) : super(key: key);

  @override
  State<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends State<ReposScreen> {
  bool loading = true;
  List<dynamic> repos = [];

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn) {
      fetchRepos();
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

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Center(child: Text('Login to view repositories'));
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (repos.isEmpty) {
      return const Center(child: Text('No repositories found'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Repositories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: repos.length,
        itemBuilder: (context, index) {
          final repo = repos[index];

          final fullName = repo['full_name'] ?? '';
          final owner = fullName.contains('/')
              ? fullName.split('/')[0]
              : 'unknown';

          return RepoCard(
            repoId: repo['id'], // ✅ REQUIRED
            name: repo['name'] ?? 'Unnamed Repo',
            description: repo['description'] ?? '',
            isPrivate: repo['private'] ?? false,
            owner: owner,
            htmlUrl: repo['html_url'], // ✅ REQUIRED
            isFavourite: repo['favourite'] ?? false,
            language: repo['language'],
          );
        },
      ),
    );
  }
}
