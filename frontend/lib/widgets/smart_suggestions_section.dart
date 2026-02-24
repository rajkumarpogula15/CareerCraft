import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/interview_setup_screen.dart';
import '../screens/repo_chat_screen.dart';
import '../screens/resume_builder_screen.dart';
import 'resume_points_sheet.dart';
import 'social_post_sheet.dart';
import 'common/pressable_scale.dart';

enum SuggestionAction {
  readmeGeneration,
  repoChat,
  socialPost,
  resumePoints,
  mockInterview,
  resumeBuilder,
}

class SmartSuggestion {
  final String label;
  final String subtitle;
  final IconData icon;
  final String? repoName;
  final SuggestionAction action;

  const SmartSuggestion({
    required this.label,
    required this.action,
    this.repoName,
    this.subtitle = '',
    this.icon = Icons.tips_and_updates_outlined,
  });

  bool get needsRepo =>
      action == SuggestionAction.repoChat ||
      action == SuggestionAction.readmeGeneration ||
      action == SuggestionAction.socialPost ||
      action == SuggestionAction.resumePoints;

  bool get canNavigate => !needsRepo || repoName != null;
}

class SmartSuggestionsSection extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final String owner;
  final ValueChanged<String> onGenerateReadme;

  const SmartSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.owner,
    required this.onGenerateReadme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _PrimaryActions(
          onOpenInterview: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InterviewSetupScreen()),
            );
          },
          onOpenResume: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
            );
          },
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Repository Suggestions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(5).map((s) {
              return _SecondarySuggestionChip(
                suggestion: s,
                onTap: () => _handleTap(context, s),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ],
    );
  }

  void _handleTap(BuildContext context, SmartSuggestion suggestion) {
    switch (suggestion.action) {
      case SuggestionAction.readmeGeneration:
        if (suggestion.repoName == null) return;
        onGenerateReadme(suggestion.repoName!);
        break;
      case SuggestionAction.repoChat:
        if (!suggestion.canNavigate) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RepoChatScreen(owner: owner, repo: suggestion.repoName!),
          ),
        );
        break;
      case SuggestionAction.socialPost:
        if (suggestion.repoName == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => SocialPostSheet(repoName: suggestion.repoName!),
        );
        break;
      case SuggestionAction.resumePoints:
        if (suggestion.repoName == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => ResumePointsSheet(repoName: suggestion.repoName!),
        );
        break;
      case SuggestionAction.mockInterview:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InterviewSetupScreen()),
        );
        break;
      case SuggestionAction.resumeBuilder:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
        );
        break;
    }
  }
}

class _PrimaryActions extends StatelessWidget {
  final VoidCallback onOpenInterview;
  final VoidCallback onOpenResume;

  const _PrimaryActions({
    required this.onOpenInterview,
    required this.onOpenResume,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final items = [
          _PrimaryActionCard(
            title: 'Mock Interview',
            subtitle: 'Practice targeted interview rounds',
            icon: Icons.mic_rounded,
            onTap: onOpenInterview,
          ),
          _PrimaryActionCard(
            title: 'Build Resume',
            subtitle: 'Craft an ATS-ready resume quickly',
            icon: Icons.description_outlined,
            onTap: onOpenResume,
          ),
        ];

        if (compact) {
          return Column(
            children: [items[0], const SizedBox(height: 8), items[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 8),
            Expanded(child: items[1]),
          ],
        );
      },
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      haptic: true,
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Recommended',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondarySuggestionChip extends StatelessWidget {
  final SmartSuggestion suggestion;
  final VoidCallback onTap;

  const _SecondarySuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      haptic: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForAction(suggestion.action),
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  suggestion.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForAction(SuggestionAction action) {
    switch (action) {
      case SuggestionAction.readmeGeneration:
        return Icons.menu_book_outlined;
      case SuggestionAction.repoChat:
        return Icons.chat_bubble_outline;
      case SuggestionAction.socialPost:
        return Icons.campaign_outlined;
      case SuggestionAction.resumePoints:
        return Icons.auto_awesome_outlined;
      case SuggestionAction.mockInterview:
        return Icons.mic_none_outlined;
      case SuggestionAction.resumeBuilder:
        return Icons.description_outlined;
    }
  }
}
