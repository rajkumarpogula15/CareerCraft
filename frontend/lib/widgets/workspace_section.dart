import 'package:flutter/material.dart';

import 'section_title.dart';
import '../services/activity_service.dart';
import '../services/repository_service.dart';
import '../models/favourite_repo.dart';
import '../widgets/repo_card.dart';

class WorkspaceSection extends StatefulWidget {
  const WorkspaceSection({Key? key}) : super(key: key);

  @override
  State<WorkspaceSection> createState() => _WorkspaceSectionState();
}

class _WorkspaceSectionState extends State<WorkspaceSection> {
  late Future<List<RecentActivity>> _activities;
  late Future<List<FavouriteRepo>> _favouriteRepos;

  bool _showAllFavourites = false; // 👈 toggle state

  @override
  void initState() {
    super.initState();
    _activities = ActivityService.fetchRecent();
    _favouriteRepos = RepositoryService.fetchFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* =========================
           FAVOURITE REPOSITORIES
        ========================= */
        const SectionTitle(title: 'Favourite Repositories'),
        const SizedBox(height: 12),

        FutureBuilder<List<FavouriteRepo>>(
          future: _favouriteRepos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading favourite repositories...',
                style: TextStyle(color: Color(0xFF64748B)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                'No favourite repositories',
                style: TextStyle(color: Color(0xFF64748B)),
              );
            }

            final repos = snapshot.data!;
            final visibleRepos = _showAllFavourites
                ? repos
                : repos.take(3).toList();

            return Column(
              children: [
                // ⭐ Favourite Repo Cards
                ...visibleRepos.map((repo) {
                  return RepoCard(
                    repoId: repo.repoId,
                    name: repo.name,
                    description: repo.description,
                    isPrivate: repo.isPrivate,
                    owner: repo.owner,
                    htmlUrl: repo.htmlUrl,
                    isFavourite: true,
                  );
                }),

                // 👇 See all / Show less
                if (repos.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllFavourites = !_showAllFavourites;
                        });
                      },
                      child: Text(
                        _showAllFavourites ? 'Show less' : 'See all',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 4),

        /* =========================
           RECENT ACTIVITY
        ========================= */
        const SectionTitle(title: 'Recent Activity'),
        const SizedBox(height: 12),

        FutureBuilder<List<RecentActivity>>(
          future: _activities,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading recent activity...',
                style: TextStyle(color: Color(0xFF64748B)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                'No recent activity yet',
                style: TextStyle(color: Color(0xFF64748B)),
              );
            }

            return Column(
              children: snapshot.data!.take(5).map(_activityCard).toList(),
            );
          },
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _activityCard(RecentActivity activity) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFF4F46E5), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                activity.message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
