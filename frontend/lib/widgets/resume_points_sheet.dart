import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_content_service.dart';

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

      if (result.trim().isEmpty) {
        _points = null;
      } else {
        _points = result;
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Material(
            elevation: 20,
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.max, // ✅ FIX
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Resume Points',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Optimized, ATS-friendly bullet points based on your repository.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    /// Content (Scrollable)
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.6),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _points ?? 'Failed to generate resume points.',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _points == null
                                ? null
                                : _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
