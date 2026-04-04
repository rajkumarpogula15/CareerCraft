import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_content_service.dart';
import 'loading/app_skeleton.dart';

class ResumePointsSheet extends StatefulWidget {
  final String repoName;

  const ResumePointsSheet({super.key, required this.repoName});

  @override
  State<ResumePointsSheet> createState() => _ResumePointsSheetState();
}

class _ResumePointsSheetState extends State<ResumePointsSheet> {
  bool _loading = true;
  String? _points;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final result = await AIContentService.generateResumePoints(
        repoName: widget.repoName,
      );
      _points = result.trim().isEmpty ? null : result;
    } catch (_) {
      _points = null;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _copyToClipboard() {
    if (_points == null) return;

    Clipboard.setData(ClipboardData(text: _points!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resume points copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================================================
  // CONTENT RENDERER
  // ==================================================

  List<Widget> _buildBotContent() {
    final lines = _points!.split('\n');
    final widgets = <Widget>[];

    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          widgets.add(_codeBlock(codeBuffer.toString()));
          codeBuffer.clear();
        }
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(line);
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(_heading(line.replaceFirst('## ', '')));
        continue;
      }

      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(_bullet(line.trim().substring(2)));
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(_numbered(line));
        continue;
      }

      if (line.trim().isNotEmpty) {
        widgets.add(_richText(line));
      }
    }

    return widgets;
  }

  // ==================================================
  // BLOCK STYLES
  // ==================================================

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _richText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText.rich(
        TextSpan(children: _parseInline(text)),
        style: const TextStyle(
          fontSize: 15.5,
          height: 1.65,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(child: _richText(text)),
        ],
      ),
    );
  }

  Widget _numbered(String text) {
    final parts = text.split(RegExp(r'\.\s'));
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${parts.first}. ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: _richText(parts.sublist(1).join('. '))),
        ],
      ),
    );
  }

  Widget _codeBlock(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        code.trim(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  // ==================================================
  // INLINE PARSER (**bold**, *italic*, `code`, 'code')
  // ==================================================

  List<TextSpan> _parseInline(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r"(\*\*.*?\*\*|\*.*?\*|`.*?`|'.*?')");

    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final value = match.group(0)!;

      if (value.startsWith('**')) {
        spans.add(
          TextSpan(
            text: value.replaceAll('**', ''),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      } else if (value.startsWith('*')) {
        spans.add(
          TextSpan(
            text: value.replaceAll('*', ''),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: value.substring(1, value.length - 1),
            style: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Color(0xFFE2E8F0),
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const SheetPreviewSkeleton(showHandle: true);
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            /// Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            /// Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume bullet points ✨',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ATS-optimized points you can paste directly',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(
                    0.55,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _points == null
                        ? [
                            const Text(
                              'Failed to generate resume points.',
                            ),
                          ]
                        : _buildBotContent(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _points == null ? null : _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy resume points'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
