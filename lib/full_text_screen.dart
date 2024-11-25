import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FullTextScreen extends StatelessWidget {
  final String text;
  final String title;

  const FullTextScreen({Key? key, required this.text, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Markdown(
        data: text,
        padding: const EdgeInsets.all(16),
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyLarge,
          h1: Theme.of(context).textTheme.headlineMedium,
          h2: Theme.of(context).textTheme.titleLarge,
          h3: Theme.of(context).textTheme.titleMedium,
          h4: Theme.of(context).textTheme.titleSmall,
          h5: Theme.of(context).textTheme.bodyLarge,
          h6: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
