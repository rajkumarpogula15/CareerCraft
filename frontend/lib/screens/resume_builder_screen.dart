import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/resume_draft.dart';
import '../services/resume_api.dart';
import '../services/resume/github_api.dart';
import '../services/resume/profile_api.dart';
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

  // ================= STATIC CONTROLLERS =================

  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _achievementCtrl = TextEditingController();

  // ================= DYNAMIC CONTROLLERS =================

  final Map<String, TextEditingController> _eduCtrls = {};
  final Map<String, TextEditingController> _expCtrls = {};

  List<Map<String, dynamic>> repos = [];
  final Map<String, bool> generating = {};

  // ================= LIFECYCLE =================

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (final c in _eduCtrls.values) {
      c.dispose();
    }
    for (final c in _expCtrls.values) {
      c.dispose();
    }

    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _portfolioCtrl.dispose();
    _summaryCtrl.dispose();
    _skillCtrl.dispose();
    _achievementCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD =================

  Future<void> _loadInitialData() async {
    await Future.wait([_loadProfile(), _loadRepos(), _loadSavedResume()]);
    if (mounted) setState(() => loading = false);
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
    repos = await GithubApi.fetchRepos();
    if (mounted) setState(() => reposLoading = false);
  }

  Future<void> _loadSavedResume() async {
    final data = await ResumeApi.fetchResume();
    if (data == null) return;

    _eduCtrls.clear();
    _expCtrls.clear();

    final profile = Map<String, dynamic>.from(data['profile'] ?? {});
    _titleCtrl.text = profile['title'] ?? '';
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

    final projects = data['projects'] as List<dynamic>? ?? [];
    for (final p in projects) {
      draft.projects[p['repoName']] = ProjectResumeData(
        included: p['included'] ?? false,
        bulletPoints: List<String>.from(p['bulletPoints'] ?? []),
      );
    }

    setState(() {});
  }

  // ================= SAVE =================

  Future<void> _saveResume() async {
    draft.summary = _summaryCtrl.text.trim();

    draft.profile
      ..['name'] = _nameCtrl.text.trim()
      ..['title'] = _titleCtrl.text.trim()
      ..['email'] = _emailCtrl.text.trim()
      ..['phone'] = _phoneCtrl.text.trim()
      ..['location'] = _locationCtrl.text.trim()
      ..['linkedin'] = _linkedinCtrl.text.trim()
      ..['portfolio'] = _portfolioCtrl.text.trim();

    await ResumeApi.saveResume({
      'profile': draft.profile,
      'summary': draft.summary,
      'skills': draft.skills,
      'education': draft.education,
      'experience': draft.experience,
      'achievements': draft.achievements,
      'projects': draft.projects.entries
          .map((e) => e.value.toJson(e.key))
          .toList(),
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resume saved')));
    }
  }

  // ================= HELPERS =================

  TextEditingController _bindCtrl(
    Map<String, TextEditingController> store,
    String key,
    String value,
  ) {
    return store.putIfAbsent(key, () => TextEditingController(text: value));
  }

  Widget _boundInput({
    required String label,
    required Map map,
    required String mapKey,
    required String ctrlKey,
    required Map<String, TextEditingController> store,
  }) {
    final ctrl = _bindCtrl(store, ctrlKey, map[mapKey]?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => map[mapKey] = v,
      ),
    );
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResumePreviewScreen(draft: draft),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Profile'),
            _input('Full Name', _nameCtrl),
            _input('Professional Title', _titleCtrl),
            _input('Email', _emailCtrl),
            _input('Phone', _phoneCtrl),
            _input('Location', _locationCtrl),
            _input('LinkedIn', _linkedinCtrl),
            _input('Portfolio', _portfolioCtrl),

            _sectionTitle('Professional Summary'),
            TextField(controller: _summaryCtrl, maxLines: 4),

            _sectionTitle('Skills'),
            _skillsSection(),

            _sectionTitle('Experience'),
            _experienceSection(),

            _sectionTitle('Education'),
            _educationSection(),

            _sectionTitle('Achievements & Certificates'),
            _achievementSection(),

            _sectionTitle('Projects'),
            _reposSection(),
          ],
        ),
      ),
    );
  }

  // ================= SECTIONS =================

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
          Expanded(child: TextField(controller: _skillCtrl)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (_skillCtrl.text.isNotEmpty) {
                setState(() {
                  draft.skills.add(_skillCtrl.text.trim());
                  _skillCtrl.clear();
                });
              }
            },
          ),
        ],
      ),
    ],
  );

  Widget _experienceSection() => Column(
    children: [
      ...draft.experience.asMap().entries.map((e) {
        final i = e.key;
        final exp = e.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _boundInput(
                  label: 'Role',
                  map: exp,
                  mapKey: 'role',
                  ctrlKey: 'exp_${i}_role',
                  store: _expCtrls,
                ),
                _boundInput(
                  label: 'Company',
                  map: exp,
                  mapKey: 'company',
                  ctrlKey: 'exp_${i}_company',
                  store: _expCtrls,
                ),
                _boundInput(
                  label: 'Duration',
                  map: exp,
                  mapKey: 'duration',
                  ctrlKey: 'exp_${i}_duration',
                  store: _expCtrls,
                ),
                _boundInput(
                  label: 'Description',
                  map: exp,
                  mapKey: 'description',
                  ctrlKey: 'exp_${i}_description',
                  store: _expCtrls,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _expCtrls.removeWhere((k, _) => k.startsWith('exp_${i}_'));
                    setState(() => draft.experience.removeAt(i));
                  },
                ),
              ],
            ),
          ),
        );
      }),
      OutlinedButton(
        onPressed: () => setState(() => draft.experience.add({})),
        child: const Text('Add Experience'),
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
                _boundInput(
                  label: 'Degree',
                  map: edu,
                  mapKey: 'degree',
                  ctrlKey: 'edu_${i}_degree',
                  store: _eduCtrls,
                ),
                _boundInput(
                  label: 'Institution',
                  map: edu,
                  mapKey: 'institution',
                  ctrlKey: 'edu_${i}_institution',
                  store: _eduCtrls,
                ),
                _boundInput(
                  label: 'Year',
                  map: edu,
                  mapKey: 'year',
                  ctrlKey: 'edu_${i}_year',
                  store: _eduCtrls,
                ),
                _boundInput(
                  label: 'Percentage',
                  map: edu,
                  mapKey: 'Percentage',
                  ctrlKey: 'edu_${i}_Percentage',
                  store: _eduCtrls,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _eduCtrls.removeWhere((k, _) => k.startsWith('edu_${i}_'));
                    setState(() => draft.education.removeAt(i));
                  },
                ),
              ],
            ),
          ),
        );
      }),
      OutlinedButton(
        onPressed: () => setState(() => draft.education.add({})),
        child: const Text('Add Education'),
      ),
    ],
  );

  Widget _achievementSection() => Column(
    children: [
      ...draft.achievements.map(
        (a) => ListTile(
          title: Text(a),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => draft.achievements.remove(a)),
          ),
        ),
      ),
      Row(
        children: [
          Expanded(child: TextField(controller: _achievementCtrl)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (_achievementCtrl.text.isNotEmpty) {
                setState(() {
                  draft.achievements.add(_achievementCtrl.text.trim());
                  _achievementCtrl.clear();
                });
              }
            },
          ),
        ],
      ),
    ],
  );

  Widget _reposSection() {
    if (reposLoading) return const CircularProgressIndicator();

    return Column(
      children: repos.map((repo) {
        final name = repo['name'];
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
            project.bulletPoints = await GithubApi.generateResumePoints(name);
            generating[name] = false;
            setState(() {});
          },
          onEditPoint: (i, v) => project.bulletPoints[i] = v,
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _input(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: l),
    ),
  );
}
