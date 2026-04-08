import 'package:flutter/material.dart';

import '../services/github_api.dart';
import '../widgets/common/state_views.dart';
import 'interview_session_screen.dart';

class InterviewSetupScreen extends StatefulWidget {
  final List<int> initialRepoIds;
  final String? initialDifficulty;
  final List<String> focusAreas;
  final String? flowTitle;

  const InterviewSetupScreen({
    super.key,
    this.initialRepoIds = const [],
    this.initialDifficulty,
    this.focusAreas = const [],
    this.flowTitle,
  });

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  static const int _minRepos = 1;
  static const int _maxRepos = 4;

  final TextEditingController _searchCtrl = TextEditingController();

  int _currentStep = 0;
  List<Map<String, dynamic>> repos = [];
  final Set<int> selectedRepoIds = {};
  String difficulty = 'medium';
  String searchQuery = '';
  bool searchExpanded = false;
  bool loading = true;
  bool summarizing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    selectedRepoIds.addAll(widget.initialRepoIds.take(_maxRepos));
    if (widget.initialDifficulty != null)
      difficulty = widget.initialDifficulty!;
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text.trim().toLowerCase();
      if (next != searchQuery) setState(() => searchQuery = next);
    });
    _loadRepos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await GithubApi.fetchRepos();
      if (!mounted) return;
      setState(() {
        repos = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Failed to load repositories';
        loading = false;
      });
    }
  }

  Future<void> _startInterview() async {
    if (!_validRepoSelection || summarizing) return;
    setState(() {
      summarizing = true;
      error = null;
    });
    try {
      final selected = repos
          .where((repo) => selectedRepoIds.contains(repo['id']))
          .map(
            (repo) => {
              'id': repo['id'],
              'name': repo['name'],
              'description': repo['description'],
              'updated_at': repo['updated_at'],
            },
          )
          .toList();

      await GithubApi.summarizeRepos(selected);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InterviewSessionScreen(
            repoIds: selectedRepoIds.toList(),
            difficulty: difficulty,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        summarizing = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _validRepoSelection =>
      selectedRepoIds.length >= _minRepos &&
      selectedRepoIds.length <= _maxRepos;

  List<Map<String, dynamic>> get _visibleRepos {
    final filtered = repos.where((repo) {
      if (searchQuery.isEmpty) return true;
      final name = (repo['name'] ?? '').toString().toLowerCase();
      final desc = (repo['description'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || desc.contains(searchQuery);
    }).toList();

    filtered.sort((a, b) {
      final aSelected = selectedRepoIds.contains(a['id']);
      final bSelected = selectedRepoIds.contains(b['id']);
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      return (a['name'] ?? '').toString().compareTo(
        (b['name'] ?? '').toString(),
      );
    });
    return filtered;
  }

  List<Map<String, dynamic>> get _selectedRepos =>
      repos.where((repo) => selectedRepoIds.contains(repo['id'])).toList()
        ..sort(
          (a, b) => (a['name'] ?? '').toString().compareTo(
            (b['name'] ?? '').toString(),
          ),
        );

  void _toggleRepo(int repoId) {
    final selected = selectedRepoIds.contains(repoId);
    if (!selected && selectedRepoIds.length >= _maxRepos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 4 repositories.')),
      );
      return;
    }
    setState(() {
      error = null;
      if (selected) {
        selectedRepoIds.remove(repoId);
      } else {
        selectedRepoIds.add(repoId);
      }
    });
  }

  void _next() {
    if (_currentStep == 0 && !_validRepoSelection) {
      setState(() => error = 'Select at least 1 repository to continue');
      return;
    }
    setState(() {
      error = null;
      _currentStep++;
    });
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() {
      error = null;
      _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && repos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.flowTitle ?? 'Interview Prep')),
        body: AppErrorState(message: error!, onRetry: _loadRepos),
      );
    }

    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final compactLayout =
        bottomInset > 0 || MediaQuery.sizeOf(context).height < 760;
    final titles = [
      'Choose repositories',
      'Select difficulty',
      'Review and start',
    ];
    final subtitles = [
      'Pick 1 to 4 repositories for a focused interview.',
      'Choose how challenging the questions should feel.',
      'Confirm your setup and launch the interview.',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.flowTitle ?? 'Interview Prep')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compactLayout ? 16 : 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 3',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.86,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      titles[_currentStep],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitles[_currentStep],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    SizedBox(height: compactLayout ? 12 : 16),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / 3,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compactLayout ? 12 : 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    key: ValueKey(_currentStep),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.06,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _buildStep(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: compactLayout ? 12 : 16,
                  bottom: bottomInset > 0 ? 8 : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compactLayout) _buildSummaryStrip(theme),
                    if (!compactLayout && error != null) ...[
                      const SizedBox(height: 12),
                      _infoBanner(
                        context,
                        error!,
                        theme.colorScheme.error,
                        Icons.error_outline,
                      ),
                    ],
                    if (compactLayout && error != null)
                      _infoBanner(
                        context,
                        error!,
                        theme.colorScheme.error,
                        Icons.error_outline,
                      ),
                    if (error != null) const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: summarizing ? null : _back,
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: summarizing
                                ? null
                                : (_currentStep == 2
                                      ? (_validRepoSelection
                                            ? _startInterview
                                            : null)
                                      : (_currentStep == 0 &&
                                                !_validRepoSelection
                                            ? null
                                            : _next)),
                            child: summarizing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _currentStep == 2
                                        ? 'Start Interview'
                                        : 'Continue',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final items = [
            _summaryItem(
              theme,
              Icons.folder_outlined,
              'Repositories',
              '${selectedRepoIds.length}/$_maxRepos',
            ),
            _summaryItem(
              theme,
              Icons.tune,
              'Difficulty',
              difficulty.toUpperCase(),
            ),
            _summaryItem(
              theme,
              Icons.track_changes_outlined,
              'Focus',
              widget.focusAreas.isEmpty
                  ? 'Default'
                  : '${widget.focusAreas.length} areas',
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return Row(
            children: items.map((item) => Expanded(child: item)).toList(),
          );
        },
      ),
    );
  }

  Widget _summaryItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildRepoSelection();
      case 1:
        return _buildDifficulty();
      default:
        return _buildReview();
    }
  }

  Widget _buildRepoSelection() {
    final theme = Theme.of(context);
    final visibleRepos = _visibleRepos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedRepoIds.isEmpty
                    ? 'Select the repositories you want included.'
                    : '${selectedRepoIds.length} ${selectedRepoIds.length == 1 ? 'repository' : 'repositories'} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: searchExpanded ? 184 : 40,
              curve: Curves.easeOutCubic,
              child: searchExpanded
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => searchExpanded = false);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    )
                  : IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      tooltip: 'Search repositories',
                      onPressed: () => setState(() => searchExpanded = true),
                      icon: const Icon(Icons.search),
                    ),
            ),
          ],
        ),
        if (searchQuery.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${visibleRepos.length} result${visibleRepos.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (selectedRepoIds.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _selectedRepos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final repo = _selectedRepos[index];
                return InputChip(
                  label: Text((repo['name'] ?? 'Repository').toString()),
                  onDeleted: () => _toggleRepo(repo['id'] as int),
                );
              },
            ),
          ),
        if (selectedRepoIds.isNotEmpty) const SizedBox(height: 16),
        Expanded(
          child: visibleRepos.isEmpty
              ? AppEmptyState(
                  title: searchQuery.isEmpty
                      ? 'No repositories available'
                      : 'No repositories match your search',
                  subtitle: searchQuery.isEmpty
                      ? 'Sync your repositories and try again.'
                      : 'Try a different keyword or close search.',
                  icon: Icons.folder_off_outlined,
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: visibleRepos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final repo = visibleRepos[index];
                    final repoId = repo['id'] as int;
                    final selected = selectedRepoIds.contains(repoId);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleRepo(repoId),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  )
                                : theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (repo['name'] ?? 'Repository').toString(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (repo['description'] ?? 'No description')
                                          .toString(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDifficulty() {
    final theme = Theme.of(context);
    final levels = [
      (
        'easy',
        'Easy',
        'Basic project and concept questions.',
        Icons.sentiment_satisfied_alt_outlined,
      ),
      (
        'medium',
        'Medium',
        'Moderate questions with practical depth.',
        Icons.tune_outlined,
      ),
      (
        'hard',
        'Hard',
        'Advanced and more challenging questions.',
        Icons.psychology_alt_outlined,
      ),
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: levels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = levels[index];
        final selected = difficulty == item.$1;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => difficulty = item.$1),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$4, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$3,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReview() {
    final theme = Theme.of(context);
    final selected = _selectedRepos;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewBlock(
            theme,
            'Repositories',
            '${selected.length} selected',
            selected.isEmpty
                ? const Text('No repositories selected')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selected
                        .map(
                          (repo) => Chip(
                            label: Text((repo['name'] ?? 'Repo').toString()),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _reviewBlock(
            theme,
            'Difficulty',
            difficulty.toUpperCase(),
            Text(_difficultyDescription()),
          ),
          if (widget.focusAreas.isNotEmpty) ...[
            const SizedBox(height: 14),
            _reviewBlock(
              theme,
              'Focus Areas',
              '${widget.focusAreas.length}',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.focusAreas
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: Text(
              'ALL THE BEST!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewBlock(
    ThemeData theme,
    String title,
    String trailing,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(trailing, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoBanner(
    BuildContext context,
    String text,
    Color color,
    IconData? icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment:
            icon == null ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              textAlign: icon == null ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyDescription() {
    switch (difficulty) {
      case 'easy':
        return 'Best for confidence-building practice and first-pass prep.';
      case 'hard':
        return 'Best for deeper rehearsal with tougher technical pressure.';
      default:
        return 'Best for realistic mock interviews with balanced depth.';
    }
  }
}
