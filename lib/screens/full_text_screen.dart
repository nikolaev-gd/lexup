import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lexup/services/api_service.dart';
import 'package:lexup/services/firestore_service.dart';
import 'package:lexup/models/card_model.dart';
import 'package:lexup/widgets/clickable_text.dart';
import 'package:lexup/widgets/saved_cards.dart';
import 'package:lexup/utils/text_utils.dart';

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

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s\-]'), '').trim().toLowerCase();
  }

  List<TextSpan> _buildWordSpans(String phrase, String word) {
    print('Building spans for phrase: "$phrase", word: "$word"');
    
    final cleanWord = _cleanWord(word);
    final cleanPhrase = _cleanWord(phrase);
    
    print('Cleaned word: "$cleanWord", cleaned phrase: "$cleanPhrase"');

    // Найти все возможные части фразы, содержащие очищенное слово
    final List<String> parts = cleanPhrase.split(' ');
    int startIndex = -1;
    int endIndex = -1;
    
    // Ищем слово как часть фразы
    for (int i = 0; i < parts.length; i++) {
      String currentPart = '';
      for (int j = i; j < parts.length; j++) {
        if (currentPart.isNotEmpty) currentPart += ' ';
        currentPart += parts[j];
        if (currentPart == cleanWord) {
          startIndex = i;
          endIndex = j;
          break;
        }
      }
      if (startIndex != -1) break;
    }

    print('Found word at positions: start=$startIndex, end=$endIndex');

    if (startIndex == -1) {
      print('Word not found in phrase');
      return [TextSpan(text: phrase)];
    }

    // Находим соответствующие позиции в оригинальной фразе
    final originalParts = phrase.split(' ');
    final beforeWord = originalParts.take(startIndex).join(' ');
    final wordPart = originalParts.skip(startIndex).take(endIndex - startIndex + 1).join(' ');
    final afterWord = originalParts.skip(endIndex + 1).join(' ');

    print('Split phrase into: before="$beforeWord", word="$wordPart", after="$afterWord"');

    final spans = <TextSpan>[];
    
    if (beforeWord.isNotEmpty) {
      spans.add(TextSpan(text: beforeWord + ' '));
    }
    
    spans.add(TextSpan(
      text: wordPart,
      style: TextStyle(fontWeight: FontWeight.bold),
    ));
    
    if (afterWord.isNotEmpty) {
      spans.add(TextSpan(text: ' ' + afterWord));
    }

    print('Created spans: $spans');
    return spans;
  }

  String _extractSentence(String text, String word) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.firstWhere(
      (sentence) => sentence.toLowerCase().contains(_cleanWord(word)),
      orElse: () => text,
    );
  }

  @override
  void initState() {
    super.initState();
    print("FullTextScreen initialized");
    _currentText = TextUtils.fixEncoding(widget.text);
    _loadSimplifiedText();
    _checkApiConnection();
  }

  Future<void> _loadSimplifiedText() async {
    print("Loading simplified text");
    try {
      final simplifiedText = await _firestoreService.loadSimplifiedText(widget.documentId);
      if (simplifiedText != null) {
        setState(() {
          _simplifiedText = TextUtils.fixEncoding(simplifiedText);
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

    setState(() {
      _isLoading = true;
    });

    try {
      if (_simplifiedText == null || _simplifiedText!.isEmpty) {
        _simplifiedText = await _apiService.simplifyText(widget.text);
        _simplifiedText = TextUtils.fixEncoding(_simplifiedText!);
        await _firestoreService.saveSimplifiedText(widget.documentId, _simplifiedText!);
      }

      setState(() {
        _isSimplified = !_isSimplified;
        _currentText = _isSimplified ? _simplifiedText! : TextUtils.fixEncoding(widget.text);
      });
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

  Future<void> _showWordInfo(String word, String sentence) async {
    print("Show word info for: $word");
    print("Full sentence context: $sentence");

    final relevantSentence = _extractSentence(sentence, word);
    print("Extracted relevant sentence: $relevantSentence");

    setState(() {
      _isLoading = true;
    });

    try {
      final cardInfo = await _apiService.getWordInfo(word, relevantSentence);
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
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 18, color: Colors.black),
                      children: _buildWordSpans(
                        cardModel.extractedPhrase,
                        cardModel.word,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    cardModel.originalSentence,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    cardModel.briefDefinition,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    cardModel.commonCollocations,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    cardModel.exampleSentence,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close', style: TextStyle(fontSize: 18)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Save', style: TextStyle(fontSize: 18)),
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
          title: Text('Подтверждение удаления', style: TextStyle(fontSize: 18)),
          content: Text('Вы уверены, что хотите удалить эту карточку?', style: TextStyle(fontSize: 18)),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(fontSize: 18)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Удалить', style: TextStyle(fontSize: 18)),
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
              ClickableText(
                text: _currentText,
                fontSize: _fontSize,
                onWordTap: _showWordInfo,
              )
            else
              ElevatedButton(
                onPressed: () => _launchURL(widget.link),
                child: Text('Open Link', style: TextStyle(fontSize: 18)),
              ),
            SizedBox(height: 20),
            Text(
              'Saved Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SavedCards(
              cardStream: _firestoreService.getSavedCardsStream(widget.documentId),
              onDeleteCard: _deleteCard,
            ),
          ],
        ),
      ),
    );
  }
}
