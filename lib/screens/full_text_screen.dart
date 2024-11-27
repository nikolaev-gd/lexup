import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lexup/services/api_service.dart';
import 'package:lexup/services/firestore_service.dart'; // Исправленный импорт
import 'package:lexup/models/card_model.dart'; // Импорт модели карточек

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
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

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
    try {
      final simplifiedText = await _firestoreService.loadSimplifiedText(widget.documentId);
      if (simplifiedText != null) {
        setState(() {
          _simplifiedText = _fixEncoding(simplifiedText);
        });
        print("Simplified text loaded: $_simplifiedText");
      } else {
        print("Simplified text not found");
      }
    } catch (e) {
      print("Error loading simplified text: $e");
    }
  }

  Future<void> _checkApiConnection() async {
    bool isConnected = await _apiService.checkApiConnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API connection failed. Please check your configuration.'))
      );
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
        _simplifiedText = await _apiService.simplifyText(widget.text);
        _simplifiedText = _fixEncoding(_simplifiedText!);
        print("New simplified text: $_simplifiedText");
        
        await _firestoreService.saveSimplifiedText(widget.documentId, _simplifiedText!);
        print("Simplified text saved to Firestore");
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
      final cardInfo = await _apiService.getWordInfo(word, sentence);
      final cardModel = CardModel(
        word: word,
        extractedPhrase: cardInfo['extracted_phrase'] ?? '',
        originalSentence: cardInfo['original_sentence'] ?? '',
        briefDefinition: cardInfo['brief_definition'] ?? '',
        commonCollocations: cardInfo['common_collocations'] ?? '',
        exampleSentence: cardInfo['example_sentence'] ?? '',
      );
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(word),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cardModel.toMap().entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key}: ${entry.value}'),
                      SizedBox(height: 10),
                    ],
                  );
                }).toList(),
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
                  _saveCard(cardModel);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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

  Future<void> _saveCard(CardModel cardModel) async {
    try {
      await _firestoreService.saveCard(widget.documentId, cardModel.word, cardModel.toMap());
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

  Future<void> _deleteCard(String cardId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text('Вы уверены, что хотите удалить эту карточку?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _firestoreService.deleteCard(widget.documentId, cardId);
        print("Card deleted successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Card deleted successfully'))
        );
        setState(() {
          _shouldRefreshCards = true;
        });
      } catch (e) {
        print("Error deleting card: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete card. Please try again.'))
        );
      }
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
      stream: _firestoreService.getSavedCardsStream(widget.documentId),
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
            final cardModel = CardModel.fromMap(data);
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cardModel.word, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCard(document.id),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Extracted phrase: ${cardModel.extractedPhrase}'),
                    Text('Original sentence: ${cardModel.originalSentence}'),
                    Text('Brief definition: ${cardModel.briefDefinition}'),
                    Text('Common collocations: ${cardModel.commonCollocations}'),
                    Text('Example sentence: ${cardModel.exampleSentence}'),
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
