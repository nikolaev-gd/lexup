import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ContentCard({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  String get title {
    final words = text.split(' ');
    return words.length > 3 ? words.take(3).join(' ') : text;
  }

  String get previewText {
    final lines = text.split('\n');
    return lines.length > 5 ? lines.take(5).join('\n') : text;
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
              Text(
                previewText,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.fade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
