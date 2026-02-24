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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: isUser
                  ? null
                  : Border.all(color: theme.colorScheme.outlineVariant),
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

      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              line.replaceFirst('## ', ''),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );
        continue;
      }

      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(_bulletLine(context, line.trim().substring(2)));
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        final match = RegExp(r'^(\d+\.)\s(.*)$').firstMatch(line.trim());
        final number = match?.group(1) ?? '';
        final content = match?.group(2) ?? line;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(child: _inlineRichText(context, content)),
              ],
            ),
          ),
        );
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

  Widget _bulletLine(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- ', style: TextStyle(fontSize: 16)),
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

  List<InlineSpan> _parseInlineSpans(BuildContext context, String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*\n]+\*\*|\*[^*\n]+\*|`[^`\n]+`)');

    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final token = match.group(0)!;

      if (token.startsWith('**') && token.endsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (token.startsWith('`') && token.endsWith('`')) {
        final code = token.substring(1, token.length - 1);
        spans.addAll(_highlightCode(context, code, inline: true));
      } else {
        spans.add(TextSpan(text: token));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Widget _codeBlock(BuildContext context, String code) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText.rich(
        TextSpan(children: _highlightCode(context, code, inline: false)),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }

  List<InlineSpan> _highlightCode(
    BuildContext context,
    String code, {
    required bool inline,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final keywords = <String>{
      'if',
      'else',
      'for',
      'while',
      'return',
      'break',
      'continue',
      'true',
      'false',
      'null',
      'const',
      'let',
      'var',
      'function',
      'async',
      'await',
      'import',
      'export',
      'from',
      'default',
      'class',
      'new',
      'final',
      'Widget',
      'BuildContext',
      'State',
      'setState',
      'build',
      'def',
      'self',
      'None',
      'int',
      'double',
      'float',
      'void',
      'public',
      'private',
      'protected',
      'div',
      'span',
      'body',
      'html',
    };

    final tokenRegex = RegExp(r'''(\s+|[{}()[\].,;:+\-*/=<>&|!?"'`~])''');
    final parts = code.split(tokenRegex);
    final matches = tokenRegex.allMatches(code).toList();
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      final token = parts[i];
      if (token.isNotEmpty) {
        final isKeyword = keywords.contains(token);
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: isKeyword ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: isKeyword ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'monospace',
              backgroundColor: inline
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
            ),
          ),
        );
      }

      if (i < matches.length) {
        spans.add(
          TextSpan(
            text: matches[i].group(0),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontFamily: 'monospace',
              backgroundColor: inline
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
            ),
          ),
        );
      }
    }

    return spans;
  }

  Widget _copyButton(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: message));
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied'),
                duration: Duration(milliseconds: 900),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Copy',
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
