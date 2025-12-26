import 'package:flutter/material.dart';
import '../screens/repo_chat_screen.dart';

/// --------------------------------------------------------------
/// Suggestion Action Type
/// --------------------------------------------------------------
enum SuggestionAction { readmeGeneration, repoChat }

/// --------------------------------------------------------------
/// Model
/// --------------------------------------------------------------
class SmartSuggestion {
  final String label;
  final String? repoName;
  final SuggestionAction action;

  const SmartSuggestion({
    required this.label,
    required this.action,
    this.repoName,
  });

  bool get canNavigate =>
      action == SuggestionAction.repoChat && repoName != null;
}

/// --------------------------------------------------------------
/// Smart Suggestions Section
/// --------------------------------------------------------------
class SmartSuggestionsSection extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final String owner;

  /// 🔑 Callback injected from parent (RepoCard / Repo screen)
  final VoidCallback onGenerateReadme;

  const SmartSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.owner,
    required this.onGenerateReadme,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[SmartSuggestionsSection] build | owner=$owner | count=${suggestions.length}',
    );

    if (suggestions.isEmpty) {
      debugPrint('[SmartSuggestionsSection] No suggestions → hidden');
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(theme: theme),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: suggestions.map((suggestion) {
              debugPrint(
                '[SmartSuggestionsSection] Rendering → ${suggestion.label}',
              );

              return _SuggestionChip(
                label: suggestion.label,
                onTap: () => _handleSuggestionTap(context, suggestion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------
  /// Handle suggestion tap
  /// --------------------------------------------------------------
  void _handleSuggestionTap(BuildContext context, SmartSuggestion suggestion) {
    debugPrint('[SmartSuggestionsSection] Tap → ${suggestion.label}');

    switch (suggestion.action) {
      case SuggestionAction.readmeGeneration:
        debugPrint('[SmartSuggestionsSection] Trigger README generator');
        onGenerateReadme();
        break;

      case SuggestionAction.repoChat:
        if (!suggestion.canNavigate) {
          debugPrint('[SmartSuggestionsSection] Missing repo → abort');
          return;
        }

        debugPrint(
          '[SmartSuggestionsSection] Navigating → owner=$owner repo=${suggestion.repoName}',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RepoChatScreen(owner: owner, repo: suggestion.repoName!),
          ),
        );
        break;
    }
  }
}

/// --------------------------------------------------------------
/// Header widget
/// --------------------------------------------------------------
class _Header extends StatelessWidget {
  final ThemeData theme;

  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Suggestions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI-powered ideas to move you forward',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// --------------------------------------------------------------
/// Suggestion chip
/// --------------------------------------------------------------
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    debugPrint('[_SuggestionChip] build → "$label"');

    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        debugPrint('[_SuggestionChip] tapped → "$label"');
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
