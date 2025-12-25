import 'package:flutter/material.dart';
import '../services/repository_service.dart';
import '../screens/repo_chat_screen.dart';
import 'readme_preview_sheet.dart';
import 'social_post_sheet.dart';
import 'resume_points_sheet.dart';

class RepoCard extends StatefulWidget {
  final int repoId;
  final String name;
  final String description;
  final bool isPrivate;
  final String owner;
  final String htmlUrl;
  final String? language;
  final bool isFavourite;

  const RepoCard({
    super.key,
    required this.repoId,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.owner,
    required this.htmlUrl,
    this.language,
    this.isFavourite = false,
  });

  @override
  State<RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends State<RepoCard> {
  bool _expanded = false;
  late bool _isFavourite;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.isFavourite;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? theme.colorScheme.primary
              : theme.dividerColor.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mainRow(theme),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: _actions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ---------------- MAIN ROW ---------------- */

  Widget _mainRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.description.isNotEmpty
                    ? widget.description
                    : 'No description provided',
                maxLines: _expanded ? 4 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Icon(
          widget.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
          size: 18,
          color: Colors.black,
        ),

        const SizedBox(width: 4),

        AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.expand_more_rounded,
            size: 22,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /* ---------------- ACTIONS ---------------- */

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.favorite_border,
            label: _isFavourite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onTap: () => _handleFavourite(context),
          ),
          _actionRow(
            icon: Icons.info_outline,
            label: 'Repository details',
            onTap: () => _showDetails(context),
          ),
          _actionRow(
            icon: Icons.auto_awesome_outlined,
            label: 'Generate README',
            onTap: () => _showReadmeGenerator(context),
          ),
          _actionRow(
            icon: Icons.chat_bubble_outline,
            label: 'Repository chatbot',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RepoChatScreen(owner: widget.owner, repo: widget.name),
                ),
              );
            },
          ),
          _actionRow(
            icon: Icons.campaign_outlined,
            label: 'Social media post generator',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => SocialPostSheet(repoName: widget.name),
              );
            },
          ),
          _actionRow(
            icon: Icons.work_outline,
            label: 'Resume points generator',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => ResumePointsSheet(repoName: widget.name),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  /* ---------------- LOGIC ---------------- */

  Future<void> _handleFavourite(BuildContext context) async {
    try {
      if (_isFavourite) {
        await RepositoryService.removeFavourite(widget.repoId);
      } else {
        await RepositoryService.addFavourite({
          'id': widget.repoId,
          'name': widget.name,
          'fullName': '${widget.owner}/${widget.name}',
          'description': widget.description,
          'private': widget.isPrivate,
          'htmlUrl': widget.htmlUrl,
        });
      }

      setState(() => _isFavourite = !_isFavourite);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favourite')),
      );
    }
  }

  void _showReadmeGenerator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReadmePreviewSheet(
        repoName: widget.name,
        owner: widget.owner,
        description: widget.description,
        language: widget.language,
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(widget.description),
      ),
    );
  }
}
