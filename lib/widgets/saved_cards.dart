import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lexup/models/card_model.dart';

class SavedCards extends StatelessWidget {
  final Stream<QuerySnapshot> cardStream;
  final Function(String cardId) onDeleteCard;

  const SavedCards({
    Key? key,
    required this.cardStream,
    required this.onDeleteCard,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: cardStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in StreamBuilder: ${snapshot.error}');
          return Text('Что-то пошло не так: ${snapshot.error}', style: TextStyle(fontSize: 18));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('Нет сохраненных карточек', style: TextStyle(fontSize: 18));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            CardModel cardModel;
            try {
              cardModel = CardModel.fromMap(data);
              print('Processing card: word="${cardModel.word}", extractedPhrase="${cardModel.extractedPhrase}"');
            } catch (e) {
              print("Error creating CardModel: $e");
              return Text('Ошибка отображения карточки', style: TextStyle(fontSize: 18));
            }
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
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 18, color: Colors.black),
                              children: _buildWordSpans(
                                cardModel.extractedPhrase,
                                cardModel.word,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDeleteCard(document.id),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardModel.originalSentence,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardModel.briefDefinition,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardModel.commonCollocations,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardModel.exampleSentence,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
