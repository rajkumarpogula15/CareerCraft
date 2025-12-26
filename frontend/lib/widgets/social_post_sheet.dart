import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_content_service.dart';

enum SocialPlatform { linkedin, x, reddit }

class SocialPlatformConfig {
  final String label;
  final IconData icon;
  final Uri webUrl;
  final Uri? appUrl;

  const SocialPlatformConfig({
    required this.label,
    required this.icon,
    required this.webUrl,
    this.appUrl,
  });
}

final Map<SocialPlatform, SocialPlatformConfig> socialPlatforms = {
  SocialPlatform.linkedin: SocialPlatformConfig(
    label: 'LinkedIn',
    icon: Icons.business_center_rounded,
    webUrl: Uri.parse('https://www.linkedin.com/feed/?shareActive=true'),
    appUrl: Uri.parse('linkedin://feed'),
  ),
  SocialPlatform.x: SocialPlatformConfig(
    label: 'X',
    icon: Icons.alternate_email_rounded,
    webUrl: Uri.parse('https://twitter.com/intent/tweet'),
    appUrl: Uri.parse('twitter://post'),
  ),
  SocialPlatform.reddit: SocialPlatformConfig(
    label: 'Reddit',
    icon: Icons.forum_rounded,
    webUrl: Uri.parse('https://www.reddit.com/submit'),
  ),
};

class SocialPostSheet extends StatefulWidget {
  final String repoName;

  const SocialPostSheet({super.key, required this.repoName});

  @override
  State<SocialPostSheet> createState() => _SocialPostSheetState();
}

class _SocialPostSheetState extends State<SocialPostSheet> {
  bool _loading = true;
  String? _post;
  SocialPlatform? _preferredPlatform;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadPreferredPlatform();
  }

  Future<void> _loadPost() async {
    try {
      final result = await AIContentService.generateSocialPost(
        repoName: widget.repoName,
      );
      _post = result.trim().isEmpty ? null : result;
    } catch (_) {
      _post = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPreferredPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('preferred_social_platform');
    if (value != null) {
      _preferredPlatform = SocialPlatform.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SocialPlatform.linkedin,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _savePreferredPlatform(SocialPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_social_platform', platform.name);
  }

  void _copyPost() {
    if (_post == null) return;
    Clipboard.setData(ClipboardData(text: _post!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post copied to clipboard')));
  }

  Future<void> _postToPlatform(SocialPlatform platform) async {
    final config = socialPlatforms[platform]!;
    if (config.appUrl != null && await canLaunchUrl(config.appUrl!)) {
      await launchUrl(config.appUrl!, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(config.webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlatformPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share to',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...SocialPlatform.values.map((platform) {
                  final config = socialPlatforms[platform]!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(config.icon, color: Colors.blue),
                    ),
                    title: Text(config.label),
                    trailing: platform == _preferredPlatform
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () async {
                      await _savePreferredPlatform(platform);
                      setState(() => _preferredPlatform = platform);
                      Navigator.pop(context);
                      _postToPlatform(platform);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================================================
  // CONTENT RENDERER
  // ==================================================

  List<Widget> _buildBotContent() {
    if (_post == null) {
      return const [Text('Failed to generate post.')];
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

    // Added hashtag pattern
    final regex = RegExp(r"(\*\*.*?\*\*|\*.*?\*|`.*?`|'.*?'|#\w[\w-]*)");

    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final value = match.group(0)!;

      if (value.startsWith('**')) {
        // Bold
        spans.add(
          TextSpan(
            text: value.replaceAll('**', ''),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      } else if (value.startsWith('*')) {
        // Italic
        spans.add(
          TextSpan(
            text: value.replaceAll('*', ''),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (value.startsWith('#')) {
        // ✅ Hashtag style
        spans.add(
          TextSpan(
            text: value,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else {
        // Inline code
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 42, 20, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Post Generator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildBotContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _post == null ? null : _copyPost,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _post == null ? null : _showPlatformPicker,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
