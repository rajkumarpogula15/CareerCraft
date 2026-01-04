import 'package:flutter/material.dart';
import '../screens/repo_chat_screen.dart';
import '../screens/interview_setup_screen.dart';
import '../screens/resume_builder_screen.dart';

/// --------------------------------------------------------------
/// Suggestion Action Type
/// --------------------------------------------------------------
enum SuggestionAction {
  readmeGeneration,
  repoChat,
  mockInterview,
  resumeBuilder,
}

/// --------------------------------------------------------------
/// Model (BACKWARD COMPATIBLE)
/// --------------------------------------------------------------
class SmartSuggestion {
  final String label; // ⬅️ old field (required)
  final String subtitle;
  final IconData icon;

  final String? repoName;
  final SuggestionAction action;

  const SmartSuggestion({
    required this.label,
    required this.action,
    this.repoName,
    this.subtitle = '',
    this.icon = Icons.lightbulb_outline_rounded,
  });

  String get title => label;

  bool get canNavigate =>
      action == SuggestionAction.repoChat && repoName != null;
}

/// --------------------------------------------------------------
/// Smart Suggestions Section (COMPACT UI)
/// --------------------------------------------------------------
class SmartSuggestionsSection extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final String owner;
  final VoidCallback onGenerateReadme;

  const SmartSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.owner,
    required this.onGenerateReadme,
  });

  List<SmartSuggestion> get _predefinedSuggestions => const [
    SmartSuggestion(
      label: 'Mock interview',
      subtitle: 'Practice interview questions',
      icon: Icons.mic_rounded,
      action: SuggestionAction.mockInterview,
    ),
    SmartSuggestion(
      label: 'Build resume',
      subtitle: 'Create an ATS-friendly resume',
      icon: Icons.description_rounded,
      action: SuggestionAction.resumeBuilder,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSuggestions = [..._predefinedSuggestions, ...suggestions];

    if (allSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(theme: theme),
          const SizedBox(height: 12),
          Column(
            children: allSuggestions.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SuggestionRow(
                  suggestion: s,
                  onTap: () => _handleTap(context, s),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, SmartSuggestion suggestion) {
    switch (suggestion.action) {
      case SuggestionAction.readmeGeneration:
        onGenerateReadme();
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

/// --------------------------------------------------------------
/// Header (SMALL & CLEAN)
/// --------------------------------------------------------------
class _Header extends StatelessWidget {
  final ThemeData theme;

  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Smart suggestions',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// --------------------------------------------------------------
/// Suggestion Row (OLD-SIZE FEEL, NEW LOOK)
/// --------------------------------------------------------------
class _SuggestionRow extends StatelessWidget {
  final SmartSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionRow({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(suggestion.icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (suggestion.subtitle.isNotEmpty)
                    Text(
                      suggestion.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
