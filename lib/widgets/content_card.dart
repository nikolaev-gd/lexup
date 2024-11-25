import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ContentCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ContentCard({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  String get title {
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].replaceAll(RegExp(r'[#*_]'), '').trim();
      return firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;
    }
    return '';
  }

  String get previewText {
    final lines = text.split('\n');
    if (lines.length > 1) {
      return lines.skip(1).take(4).join('\n');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: previewText,
                shrinkWrap: true,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
