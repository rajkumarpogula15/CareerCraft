import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildContent(context),
                if (!isUser) _copyButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ---------------- CONTENT ---------------- */

  List<Widget> _buildContent(BuildContext context) {
    final blocks = message.split('```');
    final widgets = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final isCodeBlock = i.isOdd;

      if (block.trim().isEmpty) continue;

      if (isCodeBlock) {
        widgets.add(_codeBlock(context, block.trim()));
      } else {
        widgets.addAll(_buildTextLines(context, block));
      }
    }

    return widgets;
  }

  List<Widget> _buildTextLines(BuildContext context, String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;

      if (line.startsWith('### ')) {
        widgets.add(_heading(context, line.substring(4), size: 16));
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(_heading(context, line.substring(3), size: 18));
        continue;
      }

      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(_bulletLine(context, line.trim().substring(2)));
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _inlineRichText(context, line),
        ),
      );
    }

    return widgets;
  }

  Widget _heading(BuildContext context, String text, {required double size}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bulletLine(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: _inlineRichText(context, text)),
        ],
      ),
    );
  }

  Widget _inlineRichText(BuildContext context, String text) {
    return SelectableText.rich(
      TextSpan(children: _parseInlineSpans(context, text)),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
    );
  }

  /* ---------------- INLINE PARSER ---------------- */

  List<InlineSpan> _parseInlineSpans(BuildContext context, String text) {
    final spans = <InlineSpan>[];

    final regex = RegExp(
      r'(\*\*[^*\n]+\*\*|\*[^*\n]+\*|`[^`\n]+`|\$[^$\n]+\$|O\([A-Za-z0-9]+\))',
    );

    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final token = match.group(0)!;

      if (token.startsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (token.startsWith('*')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.addAll(
          _highlightCode(
            context,
            token.replaceAll(RegExp(r'[`$]'), ''),
            inline: true,
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

  /* ---------------- CODE BLOCK ---------------- */

  Widget _codeBlock(BuildContext context, String code) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SelectableText.rich(
            TextSpan(children: _highlightCode(context, code, inline: false)),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /* ---------------- FINAL CODE HIGHLIGHT ---------------- */

  List<InlineSpan> _highlightCode(
    BuildContext context,
    String code, {
    required bool inline,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final keywordColor = scheme.primary;
    final typeColor = Colors.purpleAccent;
    final stringColor = Colors.green;
    final numberColor = Colors.orange;
    final commentColor = Colors.grey;
    final defaultColor = scheme.onSurface;

    final keywords = {
      'if',
      'else',
      'for',
      'while',
      'return',
      'class',
      'new',
      'public',
      'private',
      'static',
      'void',
      'int',
      'double',
      'float',
      'char',
      'true',
      'false',
      'null',
    };

    final regex = RegExp(
      r'(//.*?$|/\*[\s\S]*?\*/|".*?"|'
      "'.*?'"
      r'|\d+|[a-zA-Z_]+|\s+|[^\s])',
      multiLine: true,
    );

    return regex.allMatches(code).map((match) {
      final token = match.group(0)!;

      if (RegExp(r'^\s+$').hasMatch(token)) {
        return TextSpan(text: token);
      }

      Color color = defaultColor;
      FontWeight weight = FontWeight.normal;

      if (token.startsWith('//') || token.startsWith('/*')) {
        color = commentColor;
      } else if (token.startsWith('"') || token.startsWith("'")) {
        color = stringColor;
      } else if (RegExp(r'^\d+$').hasMatch(token)) {
        color = numberColor;
      } else if (RegExp(r'^O\(.+\)$').hasMatch(token)) {
        color = Colors.orange;
        weight = FontWeight.bold;
      } else if (keywords.contains(token)) {
        color = keywordColor;
        weight = FontWeight.bold;
      } else if (RegExp(r'^[A-Z][a-zA-Z]+$').hasMatch(token)) {
        color = typeColor;
      } else if (RegExp(r'^[a-zA-Z_]+\(\)$').hasMatch(token)) {
        color = Colors.blueAccent;
      }

      return TextSpan(
        text: token,
        style: TextStyle(
          color: color,
          fontWeight: weight,
          fontFamily: 'monospace',
          backgroundColor: inline
              ? scheme.surfaceContainerHighest
              : Colors.transparent,
        ),
      );
    }).toList();
  }

  /* ---------------- COPY BUTTON ---------------- */

  Widget _copyButton(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: message));
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
        icon: Icon(
          Icons.copy_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          '',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
