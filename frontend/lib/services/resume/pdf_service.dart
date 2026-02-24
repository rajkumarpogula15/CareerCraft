import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/resume_draft.dart';

class PdfService {
  static Future<void> generateResumePdf(ResumeDraft draft) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          _header(draft),
          _sectionDivider(),

          // ================= SUMMARY =================
          if (draft.summary.isNotEmpty) ...[
            _sectionTitle('PROFESSIONAL SUMMARY'),
            pw.Text(draft.summary, style: _body()),
            _sectionDivider(),
          ],

          // ================= SKILLS =================
          if (draft.skills.isNotEmpty) ...[
            _sectionTitle('SKILLS'),
            pw.Text(draft.skills.join(', '), style: _body()),
            _sectionDivider(),
          ],

          // ================= EXPERIENCE =================
          if (draft.experience.isNotEmpty) ...[
            _sectionTitle('EXPERIENCE'),
            ...draft.experience.map(_experienceItem),
            _sectionDivider(),
          ],

          // ================= PROJECTS =================
          _projectsSection(draft),

          // ================= EDUCATION =================
          if (draft.education.isNotEmpty) ...[
            _sectionTitle('EDUCATION'),
            ...draft.education.map(_educationItem),
            _sectionDivider(),
          ],

          // ================= ACHIEVEMENTS =================
          if (draft.achievements.isNotEmpty) ...[
            _sectionTitle('ACHIEVEMENTS AND CERTIFICATIONS'),
            ...draft.achievements.map(
              (a) => pw.Bullet(text: a, style: _body()),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ================= HEADER =================

  static pw.Widget _header(ResumeDraft draft) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          draft.profile['name'] ?? '',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        if ((draft.profile['title'] ?? '').isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              draft.profile['title'],
              style: pw.TextStyle(fontSize: 14),
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 14,
          children: [
            _meta(draft.profile['email']),
            _meta(draft.profile['phone']),
            _meta(draft.profile['location']),
            _meta(draft.profile['linkedin']),
            _meta(draft.profile['portfolio']),
          ].whereType<pw.Widget>().toList(),
        ),
      ],
    );
  }

  static pw.Widget _meta(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return pw.SizedBox();
    }
    return pw.Text(value.toString(), style: pw.TextStyle(fontSize: 10));
  }

  // ================= EXPERIENCE =================

  static pw.Widget _experienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp['role'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(exp['duration'] ?? '', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          if ((exp['company'] ?? '').isNotEmpty)
            pw.Text(
              exp['company'],
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          if ((exp['description'] ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(exp['description'], style: _body()),
            ),
        ],
      ),
    );
  }

  // ================= PROJECTS =================

  static pw.Widget _projectsSection(ResumeDraft draft) {
    final projects = draft.projects.entries
        .where((e) => e.value.included)
        .toList();

    if (projects.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('PROJECTS'),
        ...projects.map(
          (p) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  p.key,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...p.value.bulletPoints.map(
                  (bp) => pw.Bullet(text: bp, style: _body()),
                ),
              ],
            ),
          ),
        ),
        _sectionDivider(),
      ],
    );
  }

  // ================= EDUCATION =================

  static pw.Widget _educationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  edu['degree'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(edu['institution'] ?? '', style: _body()),
                if ((edu['Percentage'] ?? '').toString().isNotEmpty)
                  pw.Text('Percentage: ${edu['Percentage']}', style: _body()),
              ],
            ),
          ),
          pw.Text(edu['year'] ?? '', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _sectionDivider() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.7),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.TextStyle _body() {
    return pw.TextStyle(fontSize: 11, height: 1.4);
  }
}
