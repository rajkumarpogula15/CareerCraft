import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_content_service.dart';

class SocialPostSheet extends StatefulWidget {
  final String repoName;

  const SocialPostSheet({super.key, required this.repoName});

  @override
  State<SocialPostSheet> createState() => _SocialPostSheetState();
}

class _SocialPostSheetState extends State<SocialPostSheet> {
  bool _loading = true;
  String? _post;

  @override
  void initState() {
    super.initState();
    debugPrint('[SocialPostSheet] initState called');
    debugPrint('[SocialPostSheet] repoName = ${widget.repoName}');
    _loadPost();
  }

  Future<void> _loadPost() async {
    debugPrint('[SocialPostSheet] _loadPost started');

    try {
      debugPrint(
        '[SocialPostSheet] Calling AIContentService.generateSocialPost',
      );

      final result = await AIContentService.generateSocialPost(
        repoName: widget.repoName,
      );

      debugPrint('[SocialPostSheet] AI service returned: $result');

      if (result.trim().isEmpty) {
        debugPrint('[SocialPostSheet] WARNING: Empty post returned');
        _post = null;
      } else {
        _post = result;
        debugPrint('[SocialPostSheet] Post successfully set');
      }
    } catch (error, stackTrace) {
      debugPrint('[SocialPostSheet] ERROR while generating post');
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
      _post = null;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
      debugPrint('[SocialPostSheet] Loading set to false');
    });
  }

  void _copyPost() {
    if (_post == null) return;

    Clipboard.setData(ClipboardData(text: _post!));
    debugPrint('[SocialPostSheet] Post copied to clipboard');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openLinkedIn() async {
    final uri = Uri.parse('https://www.linkedin.com/feed/?shareActive=true');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    debugPrint('[SocialPostSheet] build called');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 22,
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.max, // ✅ FIX
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      children: [
                        const Icon(Icons.campaign_outlined, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Social Media Post',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          splashRadius: 20,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'AI-generated post ready for LinkedIn and professional platforms.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    /// Content (Scrollable + Safe)
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
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
                              _post ?? 'Failed to generate social post.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.55,
                              ),
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
                            onPressed: _post == null ? null : _copyPost,
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

                    const SizedBox(height: 12),

                    /// Secondary action
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _post == null ? null : _openLinkedIn,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Post on LinkedIn'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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
