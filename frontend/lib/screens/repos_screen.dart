import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/repo_card.dart';
import '../config/app_config.dart';
import '../services/repository_service.dart';
import '../models/favourite_repo.dart';

class ReposScreen extends StatefulWidget {
  const ReposScreen({Key? key}) : super(key: key);

  @override
  State<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends State<ReposScreen> {
  bool loading = true;
  List<dynamic> repos = [];
  Set<int> favouriteRepoIds = {};

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      /// 1️⃣ Fetch favourites from DB
      final List<FavouriteRepo> favourites =
          await RepositoryService.fetchFavourites();

      favouriteRepoIds = favourites.map<int>((repo) => repo.repoId).toSet();

      /// 2️⃣ Fetch GitHub repos
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (res.statusCode == 200) {
        repos = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('❌ Failed to load repos: $e');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Center(child: Text('Login to view repositories'));
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (repos.isEmpty) {
      return const Center(
        child: Text(
          'No repositories found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            title: const Text(
              'Repositories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final repo = repos[index];

              final fullName = repo['full_name'] ?? '';
              final owner = fullName.contains('/')
                  ? fullName.split('/')[0]
                  : 'unknown';

              final int repoId = repo['id'];

              /// ✅ Padding added here
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: RepoCard(
                  repoId: repoId,
                  name: repo['name'] ?? 'Unnamed Repo',
                  description: repo['description'] ?? '',
                  isPrivate: repo['private'] ?? false,
                  owner: owner,
                  htmlUrl: repo['html_url'],
                  language: repo['language'],
                  isFavourite: favouriteRepoIds.contains(repoId),
                ),
              );
            }, childCount: repos.length),
          ),
        ],
      ),
    );
  }
}
