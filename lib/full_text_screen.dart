import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lexup/config/api_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FullTextScreen extends StatefulWidget {
  final String text;
  final String title;
  final String documentId;

  const FullTextScreen({Key? key, required this.text, required this.title, required this.documentId}) : super(key: key);

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
    _loadSimplifiedText();
  }

  Future<void> _loadSimplifiedText() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('content')
        .doc(widget.documentId)
        .get();

    if (docSnapshot.exists) {
      setState(() {
        _simplifiedText = docSnapshot.data()?['simplified_text'];
      });
    }
  }

  Future<void> _saveSimplifiedText(String simplifiedText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('content')
        .doc(widget.documentId)
        .update({
      'simplified_text': simplifiedText,
    });
  }

  Future<void> _simplifyText() async {
    if (_simplifiedText == null) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, войдите в систему для упрощения текста')),
        );
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(widget.documentId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()?['simplified_text'] != null) {
        setState(() {
          _simplifiedText = docSnapshot.data()?['simplified_text'];
          _currentText = _simplifiedText!;
          _isSimplified = true;
          _isLoading = false;
        });
      } else {
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
          final simplifiedText = data['choices'][0]['message']['content'];
          await _saveSimplifiedText(simplifiedText);
          setState(() {
            _simplifiedText = simplifiedText;
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
