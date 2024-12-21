import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Function(String word, String sentence) onWordTap;

  const ClickableText({
    Key? key,
    required this.text,
    required this.fontSize,
    required this.onWordTap,
  }) : super(key: key);

  String _findSentence(String word) {
    final normalizedText = text
        .replaceAll(RegExp(r'\*\*\*|\*\*|__'), '')
        .replaceAll(RegExp(r'\*|_'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .replaceAll(RegExp(r'\n'), ' ');

    final sentences = normalizedText.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.firstWhere(
      (sentence) => sentence.toLowerCase().contains(
        _cleanWord(word).toLowerCase(),
      ),
      orElse: () => normalizedText,
    );
  }

  String _cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'\*\*\*|\*\*|__'), '')
        .replaceAll(RegExp(r'\*|_'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .trim();
  }

  TextStyle _getHeaderStyle(int level) {
    final double scaleFactor = 1 + (0.2 * (4 - level));
    return TextStyle(
      fontSize: fontSize * scaleFactor,
      fontWeight: FontWeight.bold,
    );
  }

  List<TextSpan> _parseInlineMarkdown(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp inlinePattern = RegExp(
      r'(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(__.*?__)|(\*.*?\*)|(_.*?_)|(`.*?`)|([^*_`]+)',
      multiLine: true,
    );

    final matches = inlinePattern.allMatches(text);
    
    for (final match in matches) {
      String content = match[0]!;
      TextStyle style = baseStyle;

      if (content.startsWith('***') && content.endsWith('***')) {
        content = content.substring(3, content.length - 3);
        style = style.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
      } else if (content.startsWith('**') && content.endsWith('**')) {
        content = content.substring(2, content.length - 2);
        style = style.copyWith(fontWeight: FontWeight.bold);
      } else if (content.startsWith('__') && content.endsWith('__')) {
        content = content.substring(2, content.length - 2);
        style = style.copyWith(fontWeight: FontWeight.bold);
      } else if ((content.startsWith('*') && content.endsWith('*')) ||
                 (content.startsWith('_') && content.endsWith('_'))) {
        content = content.substring(1, content.length - 1);
        style = style.copyWith(fontStyle: FontStyle.italic);
      } else if (content.startsWith('`')) {
        content = content.substring(1, content.length - 1);
        style = style.copyWith(fontFamily: 'Courier');
      }

      spans.addAll(_buildWordSpans(content, style));
    }

    return spans;
  }

  List<TextSpan> _parseMarkdown(String text) {
    final List<TextSpan> spans = [];
    final RegExp blockPattern = RegExp(
      r'(#{1,6}\s+.*?)(?:\n|$)|(>.*?)(?:\n|$)|(.*?)(?:\n|$)',
      multiLine: true,
    );

    final matches = blockPattern.allMatches(text);
    
    for (final match in matches) {
      String content = match[0]!;
      TextStyle style = TextStyle(fontSize: fontSize);

      if (content.startsWith('#')) {
        // Header
        final headerLevel = RegExp(r'^#+').firstMatch(content)![0]!.length;
        content = content.substring(headerLevel).trimLeft();
        style = _getHeaderStyle(headerLevel);
        spans.addAll(_parseInlineMarkdown(content, style));
      } else if (content.startsWith('>')) {
        // Blockquote
        content = content.substring(1).trim();
        style = style.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
        );
        spans.addAll(_parseInlineMarkdown(content, style));
      } else {
        // Regular paragraph
        spans.addAll(_parseInlineMarkdown(content, style));
      }
    }

    return spans;
  }

  List<TextSpan> _buildWordSpans(String text, TextStyle style) {
    final List<TextSpan> spans = [];
    String currentWord = '';
    String currentPunctuation = '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (char == ' ' || char == '\n') {
        if (currentWord.isNotEmpty) {
          spans.add(_createWordSpan(currentWord, style));
          currentWord = '';
        }
        if (currentPunctuation.isNotEmpty) {
          spans.add(TextSpan(text: currentPunctuation, style: style));
          currentPunctuation = '';
        }
        spans.add(TextSpan(text: char, style: style));
      } else if (RegExp(r'[.,!?;:]').hasMatch(char)) {
        if (currentWord.isNotEmpty) {
          spans.add(_createWordSpan(currentWord, style));
          currentWord = '';
        }
        currentPunctuation += char;
      } else {
        if (currentPunctuation.isNotEmpty) {
          spans.add(TextSpan(text: currentPunctuation, style: style));
          currentPunctuation = '';
        }
        currentWord += char;
      }
    }

    if (currentWord.isNotEmpty) {
      spans.add(_createWordSpan(currentWord, style));
    }
    if (currentPunctuation.isNotEmpty) {
      spans.add(TextSpan(text: currentPunctuation, style: style));
    }

    return spans;
  }

  TextSpan _createWordSpan(String word, TextStyle style) {
    return TextSpan(
      text: word,
      style: style,
      recognizer: TapGestureRecognizer()
        ..onTap = () => onWordTap(word, _findSentence(word)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _parseMarkdown(text),
      ),
    );
  }
}
