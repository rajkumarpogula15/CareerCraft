import 'package:flutter/material.dart';
import '../services/repository_service.dart';
import '../widgets/repo_card.dart';

class FavouriteReposScreen extends StatefulWidget {
  const FavouriteReposScreen({Key? key}) : super(key: key);

  @override
  State<FavouriteReposScreen> createState() => _FavouriteReposScreenState();
}

class _FavouriteReposScreenState extends State<FavouriteReposScreen> {
  late Future<List<dynamic>> _reposFuture;

  @override
  void initState() {
    super.initState();
    _reposFuture = RepositoryService.fetchFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite Repositories')),
      body: FutureBuilder<List<dynamic>>(
        future: _reposFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error or empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favourites yet ⭐'));
          }

          final repos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: repos.length,
            itemBuilder: (context, index) {
              final repo = repos[index];

              final String fullName = repo['fullName'] ?? '';
              final String owner = fullName.contains('/')
                  ? fullName.split('/').first
                  : 'unknown';

              return RepoCard(
                repoId: repo['repoId'] as int, // ✅ FIXED
                name: repo['name'] ?? '',
                description: repo['description'] ?? '',
                isPrivate: repo['private'] ?? false,
                owner: owner,
                htmlUrl: repo['htmlUrl'] ?? '',
                isFavourite: true,
              );
            },
          );
        },
      ),
    );
  }
}
