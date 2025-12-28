import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/resume_draft.dart';

class PdfService {
  static Future<void> generateResumePdf(ResumeDraft draft) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              draft.profile['name'] ?? '',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(draft.profile['email'] ?? ''),
            pw.Text(draft.profile['phone'] ?? ''),
            pw.SizedBox(height: 12),

            _section(
              'Skills',
              draft.skills.map((s) => pw.Text('• $s')).toList(),
            ),

            _section(
              'Education',
              draft.education
                  .map(
                    (e) => pw.Text(
                      '${e['degree']} – ${e['institution']} (${e['year']})',
                    ),
                  )
                  .toList(),
            ),

            _section(
              'Projects',
              draft.projects.entries
                  .where((e) => e.value.included)
                  .expand(
                    (e) => [
                      pw.Text(
                        e.key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      ...e.value.bulletPoints.map((p) => pw.Text('• $p')),
                      pw.SizedBox(height: 6),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.Widget _section(String title, List<pw.Widget> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        ...items,
      ],
    );
  }
}
