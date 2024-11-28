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

  String _extractSentence(String text, String word) {
    // Разбиваем текст на предложения
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    // Ищем предложение, содержащее слово
    return sentences.firstWhere(
      (sentence) => sentence.toLowerCase().contains(word.toLowerCase()),
      orElse: () => text, // Если не найдено, возвращаем весь текст
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

    print("_simplifyText called");
    setState(() {
      _isLoading = true;
    });

    try {
      print("Current simplified text: $_simplifiedText");
      print("Is simplified: $_isSimplified");

      if (_simplifiedText == null || _simplifiedText!.isEmpty) {
        _simplifiedText = await _apiService.simplifyText(widget.text);
        _simplifiedText = TextUtils.fixEncoding(_simplifiedText!);
        print("New simplified text: $_simplifiedText");
        
        await _firestoreService.saveSimplifiedText(widget.documentId, _simplifiedText!);
        print("Simplified text saved to Firestore");
      }

      setState(() {
        _isSimplified = !_isSimplified;
        _currentText = _isSimplified ? _simplifiedText! : TextUtils.fixEncoding(widget.text);
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

  Future<void> _showWordInfo(String word, String sentence) async {
    print("Show word info for: $word");
    print("Full sentence context: $sentence");

    // Извлекаем только предложение, содержащее слово
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
            title: Text(cardModel.word),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cardModel.extractedPhrase),
                  SizedBox(height: 10),
                  Text(cardModel.originalSentence),
                  SizedBox(height: 10),
                  Text(cardModel.briefDefinition),
                  SizedBox(height: 10),
                  Text(cardModel.commonCollocations),
                  SizedBox(height: 10),
                  Text(cardModel.exampleSentence),
                ],
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
                child: Text('Open Link'),
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
