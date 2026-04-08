import 'package:flutter/material.dart';

import '../models/resume_draft.dart';
import '../services/resume/github_api.dart';
import '../services/resume/profile_api.dart';
import '../services/resume_api.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/resume/repo_card.dart';
import 'resume_preview_screen.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final ResumeDraft draft = ResumeDraft();

  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  int _currentStep = 0;
  bool loading = true;
  bool reposLoading = true;
  bool saving = false;
  bool summaryGenerating = false;
  bool skillSuggesting = false;
  String? error;

  List<Map<String, dynamic>> repos = [];
  final Map<String, bool> generating = {};

  static const _steps = [
    (
      title: 'Personal information',
      subtitle: 'Add the core details recruiters should see first.',
    ),
    (
      title: 'Education details',
      subtitle: 'Add your academic details.',
    ),
    (
      title: 'Work experience',
      subtitle: 'Add your work history.',
    ),
    (
      title: 'Project selection',
      subtitle: 'Select projects for your resume.',
    ),
    (
      title: 'Skills and highlights',
      subtitle: 'Add your strengths and highlights.',
    ),
    (
      title: 'Review and finalize',
      subtitle: 'Check everything before preview.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _portfolioCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadProfile(), _loadRepos(), _loadSavedResume()]);
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileApi.fetchProfile();
      if (profile == null) return;
      _nameCtrl.text = profile['name'] ?? '';
      _emailCtrl.text = profile['email'] ?? '';
    } catch (_) {}
  }

  Future<void> _loadRepos() async {
    try {
      repos = await GithubApi.fetchRepos();
    } catch (_) {
      repos = [];
    }
    if (mounted) {
      setState(() => reposLoading = false);
    }
  }

  Future<void> _loadSavedResume() async {
    final data = await ResumeApi.fetchResume();
    if (data == null) return;

    final profile = Map<String, dynamic>.from(data['profile'] ?? {});
    _nameCtrl.text = profile['name'] ?? _nameCtrl.text;
    _titleCtrl.text = profile['title'] ?? '';
    _emailCtrl.text = profile['email'] ?? _emailCtrl.text;
    _phoneCtrl.text = profile['phone'] ?? '';
    _locationCtrl.text = profile['location'] ?? '';
    _linkedinCtrl.text = profile['linkedin'] ?? '';
    _portfolioCtrl.text = profile['portfolio'] ?? '';
    _summaryCtrl.text = data['summary'] ?? '';

    draft.skills
      ..clear()
      ..addAll(List<String>.from(data['skills'] ?? []));

    draft.education
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(data['education'] ?? []));

    draft.experience
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(data['experience'] ?? []));

    draft.achievements
      ..clear()
      ..addAll(List<String>.from(data['achievements'] ?? []));

    draft.projects.clear();
    final projects = data['projects'] as List<dynamic>? ?? [];
    for (final p in projects) {
      draft.projects[p['repoName']] = ProjectResumeData(
        included: p['included'] ?? false,
        bulletPoints: List<String>.from(p['bulletPoints'] ?? []),
      );
    }

    if (mounted) setState(() {});
  }

  void _syncDraftFromControllers() {
    draft.summary = _summaryCtrl.text.trim();
    draft.profile
      ..['name'] = _nameCtrl.text.trim()
      ..['title'] = _titleCtrl.text.trim()
      ..['email'] = _emailCtrl.text.trim()
      ..['phone'] = _phoneCtrl.text.trim()
      ..['location'] = _locationCtrl.text.trim()
      ..['linkedin'] = _linkedinCtrl.text.trim()
      ..['portfolio'] = _portfolioCtrl.text.trim();
  }

  Future<void> _saveResume() async {
    _syncDraftFromControllers();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ResumeApi.saveResume({
        'profile': draft.profile,
        'summary': draft.summary,
        'skills': draft.skills,
        'education': draft.education,
        'experience': draft.experience,
        'achievements': draft.achievements,
        'projects': draft.projects.entries.map((e) => e.value.toJson(e.key)).toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume saved')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Failed to save resume');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _openPreview() {
    _syncDraftFromControllers();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResumePreviewScreen(draft: draft)),
    );
  }

  List<Map<String, dynamic>> _repoPayload() {
    return repos.map((repo) {
      final name = (repo['name'] ?? '').toString();
      final project = draft.projects[name] ?? ProjectResumeData();
      return {
        'name': name,
        'description': repo['description'],
        'language': repo['language'],
        'included': project.included,
        'bulletPoints': project.bulletPoints,
      };
    }).toList();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _backStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _showEducationDialog({int? editIndex}) async {
    final current = editIndex != null ? draft.education[editIndex] : null;
    final navigator = Navigator.of(context, rootNavigator: true);
    var degree = (current?['degree'] ?? '').toString();
    var institution = (current?['institution'] ?? '').toString();
    var year = (current?['year'] ?? '').toString();
    var score = (current?['Percentage'] ?? '').toString();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex == null ? 'Add Education' : 'Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: degree,
                decoration: const InputDecoration(labelText: 'Degree'),
                onChanged: (value) => degree = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: institution,
                decoration: const InputDecoration(labelText: 'Institution'),
                onChanged: (value) => institution = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'Year'),
                onChanged: (value) => year = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: score,
                decoration: const InputDecoration(labelText: 'Percentage / GPA'),
                onChanged: (value) => score = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => navigator.pop({
              'degree': degree.trim(),
              'institution': institution.trim(),
              'year': year.trim(),
              'Percentage': score.trim(),
            }),
            child: Text(editIndex == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!mounted) return;
    if ((result['degree'] ?? '').toString().isEmpty &&
        (result['institution'] ?? '').toString().isEmpty) {
      return;
    }
    setState(() {
      if (editIndex == null) {
        draft.education.add(result);
      } else {
        draft.education[editIndex] = result;
      }
    });
  }

  Future<void> _showExperienceDialog({int? editIndex}) async {
    final current = editIndex != null ? draft.experience[editIndex] : null;
    final navigator = Navigator.of(context, rootNavigator: true);
    var role = (current?['role'] ?? '').toString();
    var company = (current?['company'] ?? '').toString();
    var duration = (current?['duration'] ?? '').toString();
    var description = (current?['description'] ?? '').toString();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex == null ? 'Add Experience' : 'Edit Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                onChanged: (value) => role = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: company,
                decoration: const InputDecoration(labelText: 'Company'),
                onChanged: (value) => company = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: duration,
                decoration: const InputDecoration(labelText: 'Duration'),
                onChanged: (value) => duration = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => navigator.pop({
              'role': role.trim(),
              'company': company.trim(),
              'duration': duration.trim(),
              'description': description.trim(),
            }),
            child: Text(editIndex == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!mounted) return;
    if ((result['role'] ?? '').toString().isEmpty &&
        (result['company'] ?? '').toString().isEmpty) {
      return;
    }
    setState(() {
      if (editIndex == null) {
        draft.experience.add(result);
      } else {
        draft.experience[editIndex] = result;
      }
    });
  }

  Future<void> _showSimpleAddDialog({
    required String title,
    required String label,
    String initialValue = '',
    String confirmLabel = 'Add',
    required ValueChanged<String> onAdd,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var value = initialValue;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => navigator.pop(value.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    onAdd(result);
  }

  Future<void> _generateSummaryWithAi() async {
    _syncDraftFromControllers();
    setState(() {
      summaryGenerating = true;
      error = null;
    });
    try {
      final summary = await ResumeApi.generateSummary({
        'profile': draft.profile,
        'experience': draft.experience,
        'skills': draft.skills,
        'repos': _repoPayload(),
      });
      if (!mounted) return;
      setState(() => _summaryCtrl.text = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Failed to generate summary');
    } finally {
      if (mounted) setState(() => summaryGenerating = false);
    }
  }

  Future<void> _suggestSkillsWithAi() async {
    setState(() {
      skillSuggesting = true;
      error = null;
    });
    try {
      final suggestions = await ResumeApi.suggestSkills({
        'repos': _repoPayload(),
        'currentSkills': draft.skills,
      });
      if (!mounted) return;
      final selected = Set<String>.from(draft.skills);
      final picked = <String>{};
      final navigator = Navigator.of(context, rootNavigator: true);
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Suggested Skills'),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((skill) {
                  final active = picked.contains(skill) || selected.contains(skill);
                  return FilterChip(
                    selected: active,
                    label: Text(skill),
                    onSelected: selected.contains(skill)
                        ? null
                        : (value) {
                            setModalState(() {
                              if (value) {
                                picked.add(skill);
                              } else {
                                picked.remove(skill);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => navigator.pop(
                  picked.where((skill) => !draft.skills.contains(skill)).toList(),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || result == null || result.isEmpty) return;
      setState(() => draft.skills.addAll(result));
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Failed to suggest skills');
    } finally {
      if (mounted) setState(() => skillSuggesting = false);
    }
  }

  Future<void> _editProjectPoints(String repoName) async {
    final project = draft.projects[repoName];
    if (project == null) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final values = [...project.bulletPoints];
    while (values.length < 2) {
      values.add('');
    }

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit Points: $repoName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  TextFormField(
                    initialValue: values[i],
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Point ${i + 1}'),
                    onChanged: (value) => values[i] = value,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => navigator.pop(
                values
                    .map((text) => text.trim())
                    .where((text) => text.isNotEmpty)
                    .take(2)
                    .toList(),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => project.bulletPoints = result);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: FormSectionSkeleton());
    }

    final theme = Theme.of(context);
    final step = _steps[_currentStep];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: saving ? null : _saveResume,
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _openPreview,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _buildHeader(theme, step),
              const SizedBox(height: 16),
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
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: bottomInset > 0 ? 8 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      _inlineMessage(theme, error!, isError: true),
                    if (error != null) const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : _backStep,
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : (_currentStep == _steps.length - 1 ? _openPreview : _nextStep),
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _currentStep == _steps.length - 1
                                        ? 'Preview Resume'
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

  Widget _buildHeader(
    ThemeData theme,
    ({String title, String subtitle}) step,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  Widget _inlineMessage(ThemeData theme, String message, {bool isError = false}) {
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _profileStep();
      case 1:
        return _educationStep();
      case 2:
        return _experienceStep();
      case 3:
        return _projectsStep();
      case 4:
        return _skillsStep();
      default:
        return _reviewStep();
    }
  }

  Widget _profileStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _input('Full Name', _nameCtrl),
          _input('Professional Title', _titleCtrl),
          _input('Email', _emailCtrl),
          _input('Phone', _phoneCtrl),
          _input('Location', _locationCtrl),
          _input('LinkedIn', _linkedinCtrl),
          _input('Portfolio', _portfolioCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Professional summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: summaryGenerating ? null : _generateSummaryWithAi,
                icon: summaryGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Generate with AI'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Add a short professional summary',
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationStep() {
    return _entryStep(
      subtitle: 'Add your education entries.',
      emptyTitle: 'No education added yet',
      emptySubtitle: 'Tap add to create one.',
      onAdd: () => _showEducationDialog(),
      addLabel: 'Add Education',
      items: draft.education.asMap().entries.map((entry) {
        final i = entry.key;
        final edu = entry.value;
        return _editableEntryCard(
          title: (edu['degree'] ?? 'Education ${i + 1}').toString(),
          onEdit: () => _showEducationDialog(editIndex: i),
          onDelete: () {
            setState(() => draft.education.removeAt(i));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(edu['institution']?.toString() ?? 'Institution not added'),
              const SizedBox(height: 4),
              Text(edu['year']?.toString() ?? 'Year not added'),
              if ((edu['Percentage'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Score: ${edu['Percentage']}'),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _experienceStep() {
    return _entryStep(
      subtitle: 'Add your experience entries.',
      emptyTitle: 'No experience added yet',
      emptySubtitle: 'Tap add to create one.',
      onAdd: () => _showExperienceDialog(),
      addLabel: 'Add Experience',
      items: draft.experience.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        return _editableEntryCard(
          title: (exp['role'] ?? 'Experience ${i + 1}').toString(),
          onEdit: () => _showExperienceDialog(editIndex: i),
          onDelete: () {
            setState(() => draft.experience.removeAt(i));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exp['company']?.toString() ?? 'Company not added'),
              const SizedBox(height: 4),
              Text(exp['duration']?.toString() ?? 'Duration not added'),
              if ((exp['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  exp['description'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _projectsStep() {
    if (reposLoading) {
      return const CardListSkeleton(itemCount: 3, itemHeight: 120);
    }

    for (final repo in repos) {
      draft.projects.putIfAbsent(repo['name'], () => ProjectResumeData());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select projects and generate points as needed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: repos.length,
            itemBuilder: (context, index) {
              final repo = repos[index];
              final name = repo['name'];
              final project = draft.projects[name]!;
              return RepoCard(
                repo: repo,
                included: project.included,
                generating: generating[name] == true,
                points: project.bulletPoints,
                onToggleInclude: () => setState(() => project.included = !project.included),
                onGenerate: () async {
                  setState(() {
                    generating[name] = true;
                    error = null;
                    project.included = true;
                  });
                  try {
                    final generated = await GithubApi.generateResumePoints(name);
                    project.bulletPoints = generated.take(2).toList();
                  } catch (_) {
                    if (mounted) {
                      setState(() => error = 'Failed to generate project points');
                    }
                  } finally {
                    generating[name] = false;
                    if (mounted) setState(() {});
                  }
                },
                onEditPoints: () => _editProjectPoints(name),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _skillsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: skillSuggesting ? null : _suggestSkillsWithAi,
                icon: skillSuggesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Suggest Skills'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: draft.skills
                  .map(
                    (skill) => InputChip(
                      label: Text(skill),
                      onDeleted: () => setState(() => draft.skills.remove(skill)),
                      onPressed: () => _showSimpleAddDialog(
                        title: 'Edit Skill',
                        label: 'Skill',
                        initialValue: skill,
                        confirmLabel: 'Save',
                        onAdd: (value) => setState(() {
                          final index = draft.skills.indexOf(skill);
                          if (index != -1) draft.skills[index] = value;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showSimpleAddDialog(
                title: 'Add Skill',
                label: 'Skill',
                onAdd: (value) => setState(() => draft.skills.add(value)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Skill'),
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Achievements & certificates',
            child: Column(
              children: [
                ...draft.achievements.map(
                  (achievement) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(achievement),
                    onTap: () => _showSimpleAddDialog(
                      title: 'Edit Achievement',
                      label: 'Achievement or certificate',
                      initialValue: achievement,
                      confirmLabel: 'Save',
                      onAdd: (value) => setState(() {
                        final index = draft.achievements.indexOf(achievement);
                        if (index != -1) draft.achievements[index] = value;
                      }),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => draft.achievements.remove(achievement)),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSimpleAddDialog(
                      title: 'Add Achievement',
                      label: 'Achievement or certificate',
                      onAdd: (value) => setState(() => draft.achievements.add(value)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Achievement'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    _syncDraftFromControllers();
    final selectedProjects = draft.projects.entries.where((entry) => entry.value.included).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewPanel('Profile', [
            _nameCtrl.text.trim().isEmpty ? 'Name not added yet' : _nameCtrl.text.trim(),
            _titleCtrl.text.trim().isEmpty ? 'Professional title not added yet' : _titleCtrl.text.trim(),
            _emailCtrl.text.trim().isEmpty ? 'Email not added yet' : _emailCtrl.text.trim(),
          ]),
          const SizedBox(height: 14),
          _reviewPanel(
            'Education',
            draft.education.isEmpty
                ? ['No education entries yet']
                : draft.education
                    .map((edu) => '${edu['degree'] ?? 'Untitled'} - ${edu['institution'] ?? 'Institution missing'}')
                    .toList(),
          ),
          const SizedBox(height: 14),
          _reviewPanel(
            'Experience',
            draft.experience.isEmpty
                ? ['No experience entries yet']
                : draft.experience
                    .map((exp) => '${exp['role'] ?? 'Untitled'} - ${exp['company'] ?? 'Company missing'}')
                    .toList(),
          ),
          const SizedBox(height: 14),
          _reviewPanel(
            'Projects',
            selectedProjects.isEmpty
                ? ['No projects selected yet']
                : selectedProjects.map((entry) => entry.key).toList(),
          ),
          const SizedBox(height: 14),
          _reviewPanel(
            'Skills & highlights',
            [
              '${draft.skills.length} skills added',
              '${draft.achievements.length} achievements or certificates added',
            ],
          ),
        ],
      ),
    );
  }

  Widget _entryStep({
    required String subtitle,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onAdd,
    required String addLabel,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 36,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(emptyTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => items[index],
                ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => onAdd(),
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }

  Widget _editableEntryCard({
    required String title,
    required Widget child,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _reviewPanel(String title, List<String> items) {
    final theme = Theme.of(context);
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
