import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/repo_card.dart';
import '../config/app_config.dart';
import '../services/repository_service.dart';
import '../models/favourite_repo.dart';
import '../widgets/logoutView.dart';

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
    } else {
      loading = false;
    }
  }

  Future<void> _loadData() async {
    try {
      // Fetch favourite repositories from DB
      final List<FavouriteRepo> favourites =
          await RepositoryService.fetchFavourites();

      favouriteRepoIds = favourites.map<int>((repo) => repo.repoId).toSet();

      // Fetch GitHub repositories
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (response.statusCode == 200) {
        repos = jsonDecode(response.body);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not logged in view
    if (!AppState.isLoggedIn) {
      return const Scaffold(body: LoggedOutView());
    }

    // Loading state
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Empty state
    if (repos.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No repositories found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Main content
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            elevation: 0,
            title: Text(
              'Repositories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final repo = repos[index];

              final String fullName = repo['full_name'] ?? '';
              final String owner = fullName.contains('/')
                  ? fullName.split('/')[0]
                  : 'unknown';

              final int repoId = repo['id'];

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
