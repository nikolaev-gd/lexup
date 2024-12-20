import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Function(String word, String sentence) onWordTap;

  const MarkdownText({
    Key? key,
    required this.text,
    required this.fontSize,
    required this.onWordTap,
  }) : super(key: key);

  String _findSentence(String word) {
    final normalizedText = text
        .replaceAll(RegExp(r'\*\*|__'), '')
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
        .replaceAll(RegExp(r'\*\*|__'), '')
        .replaceAll(RegExp(r'\*|_'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: fontSize),
        h1: TextStyle(fontSize: fontSize * 1.5),
        h2: TextStyle(fontSize: fontSize * 1.3),
        h3: TextStyle(fontSize: fontSize * 1.1),
        strong: TextStyle(fontWeight: FontWeight.bold),
        em: TextStyle(fontStyle: FontStyle.italic),
        listBullet: TextStyle(fontSize: fontSize),
        blockquote: TextStyle(fontSize: fontSize, fontStyle: FontStyle.italic),
      ),
      builders: {
        'p': CustomTextBuilder(
          fontSize: fontSize,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
        ),
        'h1': CustomTextBuilder(
          fontSize: fontSize * 1.5,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
        ),
        'h2': CustomTextBuilder(
          fontSize: fontSize * 1.3,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
        ),
        'h3': CustomTextBuilder(
          fontSize: fontSize * 1.1,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
        ),
        'strong': CustomTextBuilder(
          fontSize: fontSize,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
          isBold: true,
        ),
        'em': CustomTextBuilder(
          fontSize: fontSize,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
          isItalic: true,
        ),
        'blockquote': CustomTextBuilder(
          fontSize: fontSize,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
          isItalic: true,
        ),
        'li': CustomTextBuilder(
          fontSize: fontSize,
          onWordTap: (word) => onWordTap(_cleanWord(word), _findSentence(word)),
        ),
      },
    );
  }
}

class CustomTextBuilder extends MarkdownElementBuilder {
  final double fontSize;
  final Function(String word) onWordTap;
  final bool isBold;
  final bool isItalic;

  CustomTextBuilder({
    required this.fontSize,
    required this.onWordTap,
    this.isBold = false,
    this.isItalic = false,
  });

  List<TextSpan> _buildWordSpans(String text, TextStyle? style) {
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
          spans.add(TextSpan(text: currentPunctuation));
          currentPunctuation = '';
        }
        spans.add(TextSpan(text: char));
      } else if (RegExp(r'[.,!?;:]').hasMatch(char)) {
        if (currentWord.isNotEmpty) {
          spans.add(_createWordSpan(currentWord, style));
          currentWord = '';
        }
        currentPunctuation += char;
      } else if (RegExp(r"['\-]").hasMatch(char)) {
        currentWord += char;
      } else {
        if (currentPunctuation.isNotEmpty) {
          spans.add(TextSpan(text: currentPunctuation));
          currentPunctuation = '';
        }
        currentWord += char;
      }
    }

    if (currentWord.isNotEmpty) {
      spans.add(_createWordSpan(currentWord, style));
    }
    if (currentPunctuation.isNotEmpty) {
      spans.add(TextSpan(text: currentPunctuation));
    }

    return spans;
  }

  TextSpan _createWordSpan(String word, TextStyle? style) {
    return TextSpan(
      text: word,
      style: (style ?? TextStyle())
          .copyWith(
            fontSize: fontSize,
            color: Colors.black,
            fontWeight: isBold ? FontWeight.bold : style?.fontWeight,
            fontStyle: isItalic ? FontStyle.italic : style?.fontStyle,
          ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => onWordTap(word),
    );
  }

  @override
  Widget? visitText(md.Text text, TextStyle? style) {
    return RichText(
      text: TextSpan(
        children: _buildWordSpans(text.text, style),
      ),
    );
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.children != null && element.children!.isNotEmpty) {
      final List<TextSpan> spans = [];
      
      for (var child in element.children!) {
        if (child is md.Text) {
          spans.addAll(_buildWordSpans(
            child.text,
            (preferredStyle ?? TextStyle()).copyWith(
              fontWeight: isBold || element.tag == 'strong' 
                  ? FontWeight.bold 
                  : preferredStyle?.fontWeight,
              fontStyle: isItalic || element.tag == 'em' 
                  ? FontStyle.italic 
                  : preferredStyle?.fontStyle,
            ),
          ));
        }
      }

      if (spans.isNotEmpty) {
        return RichText(
          text: TextSpan(children: spans),
        );
      }
    }
    return null;
  }
}
