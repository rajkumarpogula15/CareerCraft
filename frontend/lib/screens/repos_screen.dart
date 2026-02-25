import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/favourite_repo.dart';
import '../services/repository_service.dart';
import '../state/app_state.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/logoutView.dart';
import '../widgets/repo_card.dart';

class ReposScreen extends StatefulWidget {
  const ReposScreen({super.key});

  @override
  State<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends State<ReposScreen> {
  bool loading = true;
  String? error;

  List<dynamic> repos = [];
  Set<int> favouriteRepoIds = {};
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

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final List<FavouriteRepo> favourites = await RepositoryService.fetchFavourites();
      favouriteRepoIds = favourites.map<int>((repo) => repo.repoId).toSet();

      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
        headers: {'Authorization': 'Bearer ${AppState.jwt}'},
      );

      if (response.statusCode == 200) {
        repos = jsonDecode(response.body);
        visibleItems = List.generate(repos.length, (_) => false);
      } else {
        error = 'Failed to load repositories';
      }
    } catch (_) {
      error = 'Failed to load repositories';
    }

    if (mounted) {
      setState(() => loading = false);
      _startStaggeredAnimation();
    }
  }

  void _startStaggeredAnimation() {
    for (int i = 0; i < visibleItems.length; i++) {
      Future.delayed(Duration(milliseconds: 70 * i), () {
        if (!mounted) return;
        setState(() => visibleItems[i] = true);
      });
    }
  }

  int _columnsForWidth(double width) {
    if (width >= 1240) return 3;
    if (width >= 760) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Scaffold(body: LoggedOutView());
    }

    if (loading) {
      return const Scaffold(body: ReposScreenSkeleton());
    }

    if (error != null) {
      return Scaffold(body: AppErrorState(message: error!, onRetry: _loadData));
    }

    if (repos.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'No repositories found',
          subtitle: 'Connect repositories on GitHub and sync again.',
          icon: Icons.folder_off_outlined,
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnsForWidth(constraints.maxWidth);
          final horizontalPadding = constraints.maxWidth >= 760 ? 20.0 : 16.0;
          final spacing = 12.0;
          final available =
              constraints.maxWidth -
              (horizontalPadding * 2) -
              (spacing * (columns - 1));
          final cardWidth = math.max(280.0, available / columns);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                title: Text(
                  'Repositories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 18),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(repos.length, (index) {
                      final repo = repos[index];
                      final fullName = repo['full_name'] ?? '';
                      final owner = fullName.contains('/')
                          ? fullName.split('/')[0]
                          : 'unknown';
                      final int repoId = repo['id'];

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 320),
                        opacity: visibleItems[index] ? 1 : 0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          offset: visibleItems[index] ? Offset.zero : const Offset(0, 0.08),
                          child: SizedBox(
                            width: cardWidth,
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
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
