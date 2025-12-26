import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser ? const Color(0xFFE5E7EB) : const Color(0xFFF8FAFC);

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
                  : Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildBotContent(),
                if (!isUser) _copyButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CONTENT PARSER
  // --------------------------------------------------
  List<Widget> _buildBotContent() {
    final lines = message.split('\n');
    final widgets = <Widget>[];

    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final line in lines) {
      // ``` code block
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

      // ## Heading
      if (line.startsWith('## ')) {
        widgets.add(_heading(line.replaceFirst('## ', '')));
        continue;
      }

      // - bullet
      if (line.trim().startsWith('- ')) {
        widgets.add(_bullet(line.trim().substring(2)));
        continue;
      }

      // * bullet
      if (line.trim().startsWith('* ')) {
        widgets.add(_bullet(line.trim().substring(2)));
        continue;
      }

      // 1. numbered
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

  // --------------------------------------------------
  // TEXT STYLES
  // --------------------------------------------------
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

  // --------------------------------------------------
  // CODE BLOCK (``` ``` )
  // --------------------------------------------------
  Widget _codeBlock(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText.rich(
        TextSpan(children: _highlightCode(code)),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INLINE PARSER (**bold**, *italic*, `code`, 'code')
  // --------------------------------------------------
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
        // inline code
        spans.addAll(_highlightCode(value.substring(1, value.length - 1)));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  // --------------------------------------------------
  // KEYWORD HIGHLIGHTING (ALL REQUESTED LANGS)
  // --------------------------------------------------
  List<TextSpan> _highlightCode(String code) {
    final keywords = {
      // common
      'if', 'else', 'for', 'while', 'return', 'break', 'continue',
      'true', 'false', 'null',

      // Java / C / C++
      'int', 'double', 'float', 'char', 'void', 'static', 'class',
      'public', 'private', 'protected', 'new',

      // JS / TS / MERN / Next
      'const', 'let', 'var', 'function', 'async', 'await',
      'import', 'export', 'from', 'default',

      // Python
      'def', 'None', 'self', 'lambda',

      // Dart / Flutter
      'final', 'var', 'Widget', 'BuildContext', 'State',
      'setState', 'build',

      // HTML / CSS
      'div', 'span', 'body', 'html', 'class', 'id',
    };

    final spans = <TextSpan>[];
    final parts = code.split(RegExp(r'(\s+)'));

    for (final part in parts) {
      if (keywords.contains(part)) {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: Color.fromARGB(255, 72, 97, 37),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    }

    return spans;
  }

  // --------------------------------------------------
  // COPY BUTTON
  // --------------------------------------------------
  Widget _copyButton(BuildContext context) {
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
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 4),
              Text(
                'Copy',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
