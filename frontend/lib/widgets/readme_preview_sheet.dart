import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

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

  @override
  void initState() {
    super.initState();
    generateReadme();
  }

  Future<void> generateReadme() async {
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
        setState(() {
          readme = json.decode(res.body)['readme'];
          loading = false;
        });
      } else {
        setState(() {
          error = 'Failed to generate README';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Something went wrong';
        loading = false;
      });
    }
  }

  Future<void> commitReadme() async {
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

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('README committed to GitHub 🚀')),
        );
        Navigator.pop(context);
      } else {
        _showError('Failed to commit README');
      }
    } catch (e) {
      _showError('Commit failed');
    } finally {
      if (mounted) setState(() => committing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(),
            const Divider(),
            Expanded(child: _content()),
            const SizedBox(height: 12),
            _commitButton(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'AI Generated README',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _content() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return Markdown(data: readme!, selectable: true);
  }

  Widget _commitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (readme == null || committing) ? null : commitReadme,
        icon: committing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(committing ? 'Committing...' : 'Commit README to GitHub'),
      ),
    );
  }
}
