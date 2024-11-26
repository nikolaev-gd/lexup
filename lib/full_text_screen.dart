import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lexup/config/api_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class FullTextScreen extends StatefulWidget {
  final String text;
  final String link;
  final String title;
  final String documentId;

  const FullTextScreen({
    Key? key,
    required this.text,
    required this.link,
    required this.title,
    required this.documentId,
  }) : super(key: key);

  @override
  _FullTextScreenState createState() => _FullTextScreenState();
}

class _FullTextScreenState extends State<FullTextScreen> {
  late String _currentText;
  String? _simplifiedText;
  bool _isSimplified = false;
  bool _isLoading = false;
  double _fontSize = 18.0;
  bool _shouldRefreshCards = true;

  @override
  void initState() {
    super.initState();
    print("FullTextScreen initialized");
    _currentText = _fixEncoding(widget.text);
    _loadSimplifiedText();
    _checkApiConnection();
  }

  String _fixEncoding(String text) {
    print("Fixing encoding");
    return text
        .replaceAll('â', "'")
        .replaceAll('â', '"')
        .replaceAll('â', '"')
        .replaceAll('â', '–');
  }

  Future<void> _loadSimplifiedText() async {
    print("Loading simplified text");
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is null");
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(widget.documentId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _simplifiedText = _fixEncoding(docSnapshot.data()?['simplified_text'] ?? '');
        });
        print("Simplified text loaded: $_simplifiedText");
      } else {
        print("Document does not exist");
      }
    } catch (e) {
      print("Error loading simplified text: $e");
    }
  }

  Future<void> _checkApiConnection() async {
    print("Checking API connection");
    print("API Key: ${openAiApiKey.substring(0, 5)}...");
    if (openAiApiKey.isEmpty) {
      print("API key is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API key is not set. Please check your configuration.'))
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey'
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': 'Hello, this is a test message.'}
          ]
        })
      );

      print("API response status code: ${response.statusCode}");
      print("API response body: ${response.body}");

      if (response.statusCode == 200) {
        print("API connection successful");
      } else {
        print("API connection failed. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error checking API connection: $e");
    }
  }

  Future<void> _simplifyText() async {
    if (widget.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot simplify an empty text or a link.'))
      );
      return;
    }

    print("_simplifyText called");
    setState(() {
      _isLoading = true;
    });

    try {
      print("Current simplified text: $_simplifiedText");
      print("Is simplified: $_isSimplified");

      if (_simplifiedText == null || _simplifiedText!.isEmpty) {
        print("Sending request to OpenAI API");
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiApiKey'
          },
          body: jsonEncode({
            'model': 'gpt-4',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a helpful assistant that simplifies text.'
              },
              {
                'role': 'user',
                'content': 'Simplify the following text, making it easier to understand while preserving the main ideas: ${widget.text}'
              }
            ]
          })
        );

        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          _simplifiedText = _fixEncoding(data['choices'][0]['message']['content']);
          print("New simplified text: $_simplifiedText");
          
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('content')
                .doc(widget.documentId)
                .update({'simplified_text': _simplifiedText});
            print("Simplified text saved to Firestore");
          }
        } else {
          print("Error response: ${response.body}");
          throw Exception('Failed to simplify text');
        }
      }

      setState(() {
        _isSimplified = !_isSimplified;
        _currentText = _isSimplified ? _simplifiedText! : _fixEncoding(widget.text);
      });
      print("Is simplified after update: $_isSimplified");
      print("Current text updated: $_currentText");
    } catch (e) {
      print("Error in _simplifyText: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to simplify text. Please try again.'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildClickableText(String text) {
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
                onTap: () {
                  print("Word tapped: $word");
                  _showWordInfo(word, paragraph);
                },
                child: Text(
                  word,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: _fontSize,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showWordInfo(String word, String sentence) async {
    print("Show word info for: $word");
    print("Sentence: $sentence");

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey'
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful assistant that provides information about words in context.
              Provide the following information:
              1. Extracted phrase (collocation or minimal context)
              2. Original sentence
              3. Brief definition (up to 5 words)
              4. Three common collocations
              5. A new simple sentence using the extracted phrase'''
            },
            {
              'role': 'user',
              'content': 'Provide information for the word "$word" in the sentence: "$sentence"'
            }
          ]
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final lines = content.split('\n');
        
        print("API response content: $content");
        print("Lines: $lines");

        List<Widget> contentWidgets = [];
        Map<String, String> cardInfo = {};
        for (var line in lines) {
          if (line.isNotEmpty) {
            contentWidgets.add(Text(line));
            contentWidgets.add(SizedBox(height: 10));
            
            // Заполняем информацию для карточки
            if (line.startsWith('1.')) cardInfo['extracted_phrase'] = line.substring(3);
            if (line.startsWith('2.')) cardInfo['original_sentence'] = line.substring(3);
            if (line.startsWith('3.')) cardInfo['brief_definition'] = line.substring(3);
            if (line.startsWith('4.')) cardInfo['common_collocations'] = line.substring(3);
            if (line.startsWith('5.')) cardInfo['example_sentence'] = line.substring(3);
          }
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(word),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentWidgets,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    _saveCard(word, cardInfo);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to get word information');
      }
    } catch (e) {
      print("Error in _showWordInfo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get word information. Please try again.'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCard(String word, Map<String, String> cardInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to save cards.'))
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(widget.documentId)
          .collection('cards')
          .add({
        'word': word,
        'extracted_phrase': cardInfo['extracted_phrase'],
        'original_sentence': cardInfo['original_sentence'],
        'brief_definition': cardInfo['brief_definition'],
        'common_collocations': cardInfo['common_collocations'],
        'example_sentence': cardInfo['example_sentence'],
        'created_at': FieldValue.serverTimestamp(),
      });

      print("Card saved successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Card saved successfully'))
      );
      setState(() {
        _shouldRefreshCards = true;
      });
    } catch (e) {
      print("Error saving card: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save card. Please try again.'))
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url'))
      );
    }
  }

  Widget _buildSavedCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('content')
          .doc(widget.documentId)
          .collection('cards')
          .orderBy('created_at', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No saved cards');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['word'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Extracted phrase: ${data['extracted_phrase']}'),
                    Text('Original sentence: ${data['original_sentence']}'),
                    Text('Brief definition: ${data['brief_definition']}'),
                    Text('Common collocations: ${data['common_collocations']}'),
                    Text('Example sentence: ${data['example_sentence']}'),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: Colors.white))
          else if (widget.text.isNotEmpty)
            IconButton(
              icon: Icon(_isSimplified ? Icons.undo : Icons.auto_awesome),
              onPressed: _simplifyText,
              tooltip: _isSimplified ? 'Original' : 'Simplify',
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.text.isNotEmpty)
              _buildClickableText(_currentText)
            else
              ElevatedButton(
                onPressed: () => _launchURL(widget.link),
                child: Text('Open Link'),
              ),
            SizedBox(height: 20),
            Text(
              'Saved Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildSavedCards(),
          ],
        ),
      ),
    );
  }
}
