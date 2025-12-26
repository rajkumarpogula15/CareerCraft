import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

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

  // Renderer source
  String? _post;

  @override
  void initState() {
    super.initState();
    _generateReadme();
  }

  // ==================================================
  // API
  // ==================================================

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
          _post = content; // ✅ connect renderer
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
          const SnackBar(content: Text('README committed to GitHub 🚀')),
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

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          _header(theme),
          const Divider(height: 1),
          Expanded(child: _body()),
          _commitBar(theme),
        ],
      ),
    );
  }

  // ==================================================
  // HEADER
  // ==================================================

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
                  '${widget.repoName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
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

  // ==================================================
  // BODY
  // ==================================================

  Widget _body() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _errorState(error!);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: _buildBotContent(),
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

  // ==================================================
  // CONTENT RENDERER
  // ==================================================

  List<Widget> _buildBotContent() {
    if (_post == null || _post!.isEmpty) {
      return const [Text('Failed to generate README.')];
    }

    final lines = _post!.split('\n');
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
        widgets.add(_heading(line.substring(3)));
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
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _richText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, height: 1.5)),
          Expanded(child: _richText(text)),
        ],
      ),
    );
  }

  Widget _numbered(String text) {
    final parts = text.split(RegExp(r'\.\s'));
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
  // INLINE PARSER
  // ==================================================

  List<TextSpan> _parseInline(String text) {
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
            style: const TextStyle(
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
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
  // COMMIT BAR
  // ==================================================

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
            committing ? 'Committing README…' : 'Commit README to GitHub',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
