import 'package:flutter/material.dart';

import '../models/resume_draft.dart';
import '../services/resume_api.dart';
import '../services/resume/github_api.dart';
import '../widgets/resume/repo_card.dart';
import 'resume_preview_screen.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final ResumeDraft draft = ResumeDraft();

  bool loading = true;
  bool reposLoading = true;

  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  List<Map<String, dynamic>> repos = [];
  final Map<String, bool> generating = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _portfolioCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD =================

  Future<void> _loadInitialData() async {
    await Future.wait([_loadRepos(), _loadSavedResume()]);

    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadRepos() async {
    repos = await GithubApi.fetchRepos();
    if (mounted) setState(() => reposLoading = false);
  }

  Future<void> _loadSavedResume() async {
    final data = await ResumeApi.fetchResume();
    if (data == null) return;

    final profile = Map<String, dynamic>.from(data['profile'] ?? {});
    _phoneCtrl.text = profile['phone'] ?? '';
    _locationCtrl.text = profile['location'] ?? '';
    _linkedinCtrl.text = profile['linkedin'] ?? '';
    _portfolioCtrl.text = profile['portfolio'] ?? '';

    draft.skills
      ..clear()
      ..addAll(List<String>.from(data['skills'] ?? []));

    draft.education
      ..clear()
      ..addAll(
        (data['education'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );

    final projects = data['projects'] as List<dynamic>? ?? [];
    for (final p in projects) {
      draft.projects[p['repoName']] = ProjectResumeData(
        included: p['included'] ?? false,
        bulletPoints: List<String>.from(p['bulletPoints'] ?? []),
      );
    }
  }

  // ================= SAVE =================

  Future<void> _saveResume() async {
    draft.profile['phone'] = _phoneCtrl.text.trim();
    draft.profile['location'] = _locationCtrl.text.trim();
    draft.profile['linkedin'] = _linkedinCtrl.text.trim();
    draft.profile['portfolio'] = _portfolioCtrl.text.trim();

    await ResumeApi.saveResume({
      'profile': draft.profile,
      'skills': draft.skills,
      'education': draft.education,
      'projects': draft.projects.entries
          .map((e) => e.value.toJson(e.key))
          .toList(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Resume saved successfully')));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveResume),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResumePreviewScreen(draft: draft),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Basic Information'),
            _profileSection(),
            const SizedBox(height: 24),
            _sectionTitle('Skills'),
            _skillsSection(),
            const SizedBox(height: 24),
            _sectionTitle('Education'),
            _educationSection(),
            const SizedBox(height: 24),
            _sectionTitle('Projects (GitHub)'),
            _reposSection(),
          ],
        ),
      ),
    );
  }

  // ================= SECTIONS =================

  Widget _profileSection() => Column(
    children: [
      _input('Phone', _phoneCtrl),
      _input('Location', _locationCtrl),
      _input('LinkedIn URL', _linkedinCtrl),
      _input('Portfolio URL', _portfolioCtrl),
    ],
  );

  Widget _skillsSection() => Column(
    children: [
      Wrap(
        spacing: 8,
        children: draft.skills
            .map(
              (s) => Chip(
                label: Text(s),
                onDeleted: () => setState(() => draft.skills.remove(s)),
              ),
            )
            .toList(),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _skillCtrl,
              decoration: const InputDecoration(hintText: 'Add a skill'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final skill = _skillCtrl.text.trim();
              if (skill.isNotEmpty) {
                setState(() {
                  draft.skills.add(skill);
                  _skillCtrl.clear();
                });
              }
            },
          ),
        ],
      ),
    ],
  );

  Widget _educationSection() => Column(
    children: [
      ...draft.education.asMap().entries.map((e) {
        final i = e.key;
        final edu = e.value;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _educationInput(
                  'Degree',
                  edu['degree'] ?? '',
                  (v) => edu['degree'] = v,
                ),
                _educationInput(
                  'Institution',
                  edu['institution'] ?? '',
                  (v) => edu['institution'] = v,
                ),
                _educationInput(
                  'Year',
                  edu['year'] ?? '',
                  (v) => edu['year'] = v,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => draft.education.removeAt(i)),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Education'),
        onPressed: () => setState(
          () => draft.education.add(<String, dynamic>{
            'degree': '',
            'institution': '',
            'year': '',
          }),
        ),
      ),
    ],
  );

  Widget _reposSection() {
    if (reposLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: repos.map((repo) {
        final name = repo['name'] as String;
        draft.projects.putIfAbsent(name, () => ProjectResumeData());
        final project = draft.projects[name]!;

        return RepoCard(
          repo: repo,
          included: project.included,
          generating: generating[name] == true,
          points: project.bulletPoints,
          onToggleInclude: () =>
              setState(() => project.included = !project.included),
          onGenerate: () async {
            setState(() => generating[name] = true);
            final points = await GithubApi.generateResumePoints(name);
            setState(() {
              project.bulletPoints = points;
              generating[name] = false;
            });
          },
          onEditPoint: (i, v) => project.bulletPoints[i] = v,
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  Widget _input(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: l),
    ),
  );

  Widget _educationInput(String l, String v, Function(String) onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          initialValue: v,
          decoration: InputDecoration(labelText: l),
          onChanged: onChanged,
        ),
      );
}
