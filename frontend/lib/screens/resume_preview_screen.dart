import 'package:flutter/material.dart';

import '../models/resume_draft.dart';
import '../services/resume/pdf_service.dart';

class ResumePreviewScreen extends StatelessWidget {
  final ResumeDraft draft;

  const ResumePreviewScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () async {
              await PdfService.generateResumePdf(draft);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('PDF generated')));
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _resumeBody(),
          ),
        ),
      ),
    );
  }

  // ================= BODY =================

  Widget _resumeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 24),

        _section('SKILLS', _skills()),
        _section('EDUCATION', _education()),
        _section('PROJECTS', _projects()),
      ],
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.profile['name'] ?? '',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _meta(draft.profile['email']),
            _meta(draft.profile['phone']),
            _meta(draft.profile['location']),
            _meta(draft.profile['linkedin']),
            _meta(draft.profile['portfolio']),
          ].whereType<Widget>().toList(),
        ),
      ],
    );
  }

  Widget _meta(dynamic value) {
    if (value == null || value.toString().trim().isEmpty)
      return const SizedBox();
    return Text(
      value.toString(),
      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
    );
  }

  // ================= SECTIONS =================

  Widget _skills() {
    if (draft.skills.isEmpty) return _empty();

    return Text(
      draft.skills.join(', '),
      softWrap: true,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _education() {
    if (draft.education.isEmpty) return _empty();

    return Column(
      children: draft.education.map((edu) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${edu['degree'] ?? ''}, ${edu['institution'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 12),
              Text(edu['year'] ?? '', style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _projects() {
    final projects = draft.projects.entries
        .where((e) => e.value.included)
        .toList();

    if (projects.isEmpty) return _empty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: projects.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...entry.value.bulletPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          point,
                          softWrap: true,
                          style: const TextStyle(fontSize: 14),
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

  // ================= HELPERS =================

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _empty() {
    return Text('—', style: TextStyle(color: Colors.grey.shade500));
  }
}
