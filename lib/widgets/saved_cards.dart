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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: cardStream,
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
                          onPressed: () => onDeleteCard(document.id),
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
}
