import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lexup/config/api_keys.dart';

class FullTextScreen extends StatefulWidget {
  final String text;
  final String title;

  const FullTextScreen({Key? key, required this.text, required this.title}) : super(key: key);

  @override
  _FullTextScreenState createState() => _FullTextScreenState();
}

class _FullTextScreenState extends State<FullTextScreen> {
  late String _currentText;
  String? _simplifiedText;
  bool _isSimplified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;
  }

  Future<void> _simplifyText() async {
    if (_simplifiedText == null) {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that simplifies text.',
            },
            {
              'role': 'user',
              'content': 'Simplify the following text, making it easier to understand while preserving the main ideas: ${widget.text}',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _simplifiedText = data['choices'][0]['message']['content'];
          _currentText = _simplifiedText!;
          _isSimplified = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simplify text. Please try again.')),
        );
      }
    } else {
      setState(() {
        _isSimplified = !_isSimplified;
        _currentText = _isSimplified ? _simplifiedText! : widget.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: Colors.white))
          else
            IconButton(
              icon: Icon(_isSimplified ? Icons.undo : Icons.auto_awesome),
              onPressed: _simplifyText,
              tooltip: _isSimplified ? 'Original' : 'Simplify',
            ),
        ],
      ),
      body: Markdown(
        data: _currentText,
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
