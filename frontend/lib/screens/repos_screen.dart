import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/repo_card.dart';
import '../config/app_config.dart';
import '../services/repository_service.dart';
import '../models/favourite_repo.dart';
import '../widgets/logoutView.dart';
import '../widgets/loading/repo_skeleton.dart';

class ReposScreen extends StatefulWidget {
  const ReposScreen({Key? key}) : super(key: key);

  @override
  State<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends State<ReposScreen> {
  bool loading = true;

  List<dynamic> repos = [];

  Set<int> favouriteRepoIds = {};

  // For staggered animation
  List<bool> visibleItems = [];

  @override
  void initState() {
    super.initState();

    if (AppState.isLoggedIn) {
      _loadData();
    } else {
      loading = false;
    }
  }

  // ---------------- LOAD DATA ----------------

  Future<void> _loadData() async {
    try {
      // Fetch favourite repos
      final List<FavouriteRepo> favourites =
          await RepositoryService.fetchFavourites();

      favouriteRepoIds = favourites.map<int>((repo) => repo.repoId).toSet();

      // Fetch GitHub repos
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (response.statusCode == 200) {
        repos = jsonDecode(response.body);

        // Prepare animation flags
        visibleItems = List.generate(repos.length, (_) => false);
      }
    } catch (e) {
      debugPrint('Repo load error: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });

      _startStaggeredAnimation();
    }
  }

  // ---------------- STAGGERED ANIMATION ----------------

  void _startStaggeredAnimation() {
    for (int i = 0; i < visibleItems.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) {
          setState(() {
            visibleItems[i] = true;
          });
        }
      });
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    // Not logged in
    if (!AppState.isLoggedIn) {
      return const Scaffold(body: LoggedOutView());
    }

    // Skeleton loading
    if (loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: RepoSkeleton(),
            );
          },
        ),
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

          // Repo List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final repo = repos[index];

              final String fullName = repo['full_name'] ?? '';

              final String owner = fullName.contains('/')
                  ? fullName.split('/')[0]
                  : 'unknown';

              final int repoId = repo['id'];

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: visibleItems[index] ? 1 : 0,

                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,

                  offset: visibleItems[index]
                      ? Offset.zero
                      : const Offset(0, 0.1),

                  child: Padding(
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
                  ),
                ),
              );
            }, childCount: repos.length),
          ),
        ],
      ),
    );
  }
}
