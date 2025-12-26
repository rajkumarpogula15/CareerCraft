import 'package:flutter/material.dart';
import '../screens/repo_chat_screen.dart';

/// ─────────────────────────────────────────────────────────────
/// CONTINUE WHERE YOU LEFT OFF – MODERN UX
/// ─────────────────────────────────────────────────────────────
class ContinueSessionCard extends StatelessWidget {
  final String repoName;
  final String owner;
  final String lastQuestion;
  final String type;

  const ContinueSessionCard({
    super.key,
    required this.repoName,
    required this.owner,
    required this.lastQuestion,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pick up where you left off",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        _ResumeWorkCard(
          repoName: repoName,
          owner: owner,
          lastQuestion: lastQuestion,
          type: type,
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// RESUME WORK CARD – ACTION FIRST
/// ─────────────────────────────────────────────────────────────
class _ResumeWorkCard extends StatelessWidget {
  final String repoName;
  final String owner;
  final String lastQuestion;
  final String type;

  const _ResumeWorkCard({
    required this.repoName,
    required this.owner,
    required this.lastQuestion,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ─── Header ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RepoIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repoName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$owner • $type",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ─── Last Question (Muted) ───────────────
          Text(
            lastQuestion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          /// ─── CTA BUTTON ─────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RepoChatScreen(owner: owner, repo: repoName),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Continue chat",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// REPO ICON (VISUAL ANCHOR)
/// ─────────────────────────────────────────────────────────────
class _RepoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.folder_open_rounded, color: theme.colorScheme.primary),
    );
  }
}
