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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF generated successfully')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(child: _resumeBody()),
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
        const SizedBox(height: 28),

        _section('PROFESSIONAL SUMMARY', _summary()),
        _section('SKILLS', _skills()),
        _section('EXPERIENCE', _experience()),
        _section('PROJECTS', _projects()),
        _section('EDUCATION', _education()),
        _section('ACHIEVEMENTS AND CERTIFICATIONS', _achievements()),
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
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        if ((draft.profile['title'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              draft.profile['title'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
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
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox();
    }
    return Text(
      value.toString(),
      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
    );
  }

  // ================= SECTIONS =================

  Widget _summary() {
    if ((draft.summary ?? '').isEmpty) return _empty();
    return Text(
      draft.summary!,
      style: const TextStyle(fontSize: 14, height: 1.4),
    );
  }

  Widget _skills() {
    if (draft.skills.isEmpty) return _empty();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: draft.skills
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(s, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  Widget _experience() {
    if (draft.experience.isEmpty) return _empty();

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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    exp['duration'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              if ((exp['company'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    exp['company'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if ((exp['description'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    exp['description'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
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
                          style: const TextStyle(fontSize: 14, height: 1.4),
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

  Widget _education() {
    if (draft.education.isEmpty) return _empty();

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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      edu['institution'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if ((edu['Percentage'] ?? '').toString().isNotEmpty)
                      Text(
                        'Percentage: ${edu['Percentage']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
              Text(edu['year'] ?? '', style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _achievements() {
    if (draft.achievements.isEmpty) return _empty();

    return Column(
      children: draft.achievements
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      a,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ================= HELPERS =================

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
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
          const SizedBox(height: 6),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _empty() {
    return Text('—', style: TextStyle(color: Colors.grey.shade500));
  }
}
