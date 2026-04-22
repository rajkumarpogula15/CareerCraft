import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';
import 'loading/app_skeleton.dart';

class ReadmePreviewSheet extends StatefulWidget {
  final String repoName;
  final String owner;
  final String? description;
  final String? language;

  const ReadmePreviewSheet({
    super.key,
    required this.repoName,
    required this.owner,
    this.description,
    this.language,
  });

  @override
  State<ReadmePreviewSheet> createState() => _ReadmePreviewSheetState();
}

class _ReadmePreviewSheetState extends State<ReadmePreviewSheet> {
  bool loading = true;
  bool committing = false;

  String? readme;
  String? error;
  String? _post;

  @override
  void initState() {
    super.initState();
    _generateReadme();
  }

  Future<void> _generateReadme() async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/ai/readme/generate'),
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'repoName': widget.repoName,
          'owner': widget.owner,
          'description': widget.description,
          'language': widget.language,
        }),
      );

      if (res.statusCode == 200) {
        final content = json.decode(res.body)['readme'];

        setState(() {
          readme = content;
          _post = content;
          loading = false;
        });
      } else {
        _setError('Failed to generate README');
      }
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> _commitReadme() async {
    setState(() => committing = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/ai/readme/commit'),
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'repoName': widget.repoName, 'readme': readme}),
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('README committed to GitHub')),
        );
        Navigator.pop(context);
      } else {
        _showSnack('Failed to commit README');
      }
    } catch (_) {
      _showSnack('Commit failed');
    } finally {
      if (mounted) setState(() => committing = false);
    }
  }

  void _setError(String msg) {
    setState(() {
      error = msg;
      loading = false;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const SheetPreviewSkeleton();
    }

    return SafeArea(
      child: Column(
        children: [
          _header(theme),
          const Divider(height: 1),
          Expanded(child: _body(context)),
          _commitBar(theme),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Generated README',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.repoName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);

    if (error != null) {
      return _errorState(error!);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: _buildBotContent(context),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBotContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_post == null || _post!.isEmpty) {
      return [
        Text(
          'Failed to generate README.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ];
    }

    final lines = _post!.split('\n');
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
        widgets.add(_heading(context, line.substring(3)));
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
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _richText(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
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
      padding: const EdgeInsets.only(left: 12, bottom: 8),
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
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
    final regex = RegExp(r"(\*\*.*?\*\*|\*.*?\*|`.*?`|'.*?'|#\w[\w-]*)");

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
      } else if (value.startsWith('#')) {
        spans.add(
          TextSpan(
            text: value,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
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

  Widget _commitBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: (readme == null || committing) ? null : _commitReadme,
          icon: committing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload_rounded),
          label: Text(
            committing ? 'Committing README...' : 'Commit README to GitHub',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
