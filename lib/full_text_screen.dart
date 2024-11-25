import 'package:flutter/material.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
