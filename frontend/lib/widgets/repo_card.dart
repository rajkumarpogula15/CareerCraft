import 'package:flutter/material.dart';
import 'readme_preview_sheet.dart';
import '../screens/repo_chat_screen.dart';

class RepoCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isPrivate;
  final String owner;
  final String? language;

  const RepoCard({
    super.key,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.owner,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isPrivate ? Icons.lock : Icons.public,
          color: isPrivate ? Colors.redAccent : Colors.green,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'details', child: Text('Repository Details')),
            PopupMenuItem(value: 'readme', child: Text('Generate README (AI)')),
            PopupMenuItem(value: 'chat', child: Text('Repository Chatbot')),
            PopupMenuItem(value: 'favourite', child: Text('Mark as Favourite')),
            PopupMenuItem(value: 'github', child: Text('Open on GitHub')),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'details':
        _showDetails(context);
        break;

      case 'readme':
        _showReadmeGenerator(context);
        break;

      case 'chat':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RepoChatScreen(owner: owner, repo: name),
          ),
        );
        break;

      case 'favourite':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marked as favourite')));
        break;

      case 'github':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open GitHub (link later)')),
        );
        break;
    }
  }

  void _showReadmeGenerator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ReadmePreviewSheet(
          repoName: name,
          owner: owner,
          description: description,
          language: language,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(isPrivate ? Icons.lock : Icons.public, size: 18),
                  const SizedBox(width: 6),
                  Text(isPrivate ? 'Private Repository' : 'Public Repository'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
