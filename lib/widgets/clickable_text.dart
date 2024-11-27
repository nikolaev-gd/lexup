import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        final words = paragraph.split(' ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Wrap(
            spacing: 4.0,
            children: words.map((word) {
              return GestureDetector(
                onTap: () => onWordTap(word, paragraph),
                child: Text(
                  word,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
