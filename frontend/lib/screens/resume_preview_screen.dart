import 'package:flutter/material.dart';

import '../models/resume_draft.dart';
import '../services/resume/pdf_service.dart';

class ResumePreviewScreen extends StatelessWidget {
  final ResumeDraft draft;

  const ResumePreviewScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () async {
              await PdfService.generateResumePdf(draft);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF generated successfully')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _resumeBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumeBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: 28),
        _section(context, 'PROFESSIONAL SUMMARY', _summary(context)),
        _section(context, 'SKILLS', _skills(context)),
        _section(context, 'EXPERIENCE', _experience(context)),
        _section(context, 'PROJECTS', _projects(context)),
        _section(context, 'EDUCATION', _education(context)),
        _section(context, 'ACHIEVEMENTS AND CERTIFICATIONS', _achievements(context)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.profile['name'] ?? '',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if ((draft.profile['title'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(draft.profile['title'], style: theme.textTheme.titleMedium),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _meta(context, draft.profile['email']),
            _meta(context, draft.profile['phone']),
            _meta(context, draft.profile['location']),
            _meta(context, draft.profile['linkedin']),
            _meta(context, draft.profile['portfolio']),
          ].whereType<Widget>().toList(),
        ),
      ],
    );
  }

  Widget? _meta(BuildContext context, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return Text(
      value.toString(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _summary(BuildContext context) {
    if (draft.summary.isEmpty) return _empty(context);
    return Text(
      draft.summary,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
    );
  }

  Widget _skills(BuildContext context) {
    if (draft.skills.isEmpty) return _empty(context);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: draft.skills
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(s, style: theme.textTheme.bodySmall),
            ),
          )
          .toList(),
    );
  }

  Widget _experience(BuildContext context) {
    if (draft.experience.isEmpty) return _empty(context);
    final theme = Theme.of(context);

    return Column(
      children: draft.experience.map((exp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exp['role'] ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(exp['duration'] ?? '', style: theme.textTheme.bodySmall),
                ],
              ),
              if ((exp['company'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    exp['company'],
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              if ((exp['description'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    exp['description'],
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _projects(BuildContext context) {
    final projects = draft.projects.entries.where((e) => e.value.included).toList();
    if (projects.isEmpty) return _empty(context);
    final theme = Theme.of(context);

    return Column(
      children: projects.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...entry.value.bulletPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _education(BuildContext context) {
    if (draft.education.isEmpty) return _empty(context);
    final theme = Theme.of(context);

    return Column(
      children: draft.education.map((edu) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${edu['degree'] ?? ''}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(edu['institution'] ?? '', style: theme.textTheme.bodyMedium),
                    if ((edu['Percentage'] ?? '').toString().isNotEmpty)
                      Text('Percentage: ${edu['Percentage']}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(edu['year'] ?? '', style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _achievements(BuildContext context) {
    if (draft.achievements.isEmpty) return _empty(context);
    final theme = Theme.of(context);

    return Column(
      children: draft.achievements
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(a, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _section(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Text(
      '-',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
