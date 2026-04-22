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

  List<Widget> _buildBotContent(BuildContext context) {
    final lines = _points!.split('\n');
    final widgets = <Widget>[];

    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          widgets.add(_codeBlock(context, codeBuffer.toString()));
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
        widgets.add(_heading(context, line.replaceFirst('## ', '')));
        continue;
      }

      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(_bullet(context, line.trim().substring(2)));
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(_numbered(context, line));
        continue;
      }

      if (line.trim().isNotEmpty) {
        widgets.add(_richText(context, line));
      }
    }

    return widgets;
  }

  Widget _heading(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _richText(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText.rich(
        TextSpan(children: _parseInline(context, text)),
        style: TextStyle(
          fontSize: 15.5,
          height: 1.65,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(child: _richText(context, text)),
        ],
      ),
    );
  }

  Widget _numbered(BuildContext context, String text) {
    final theme = Theme.of(context);
    final parts = text.split(RegExp(r'\.\s'));

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${parts.first}. ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(child: _richText(context, parts.sublist(1).join('. '))),
        ],
      ),
    );
  }

  Widget _codeBlock(BuildContext context, String code) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SelectableText(
        code.trim(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  List<TextSpan> _parseInline(BuildContext context, String text) {
    final theme = Theme.of(context);
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
            style: TextStyle(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume bullet points',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ATS-optimized points you can paste directly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _points == null
                        ? [
                            Text(
                              'Failed to generate resume points.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ]
                        : _buildBotContent(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
